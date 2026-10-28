// Coordinator for the combined clothing-and-hair makeover.
//
// One job, two separable engines. The pipeline is:
//
//     source photo ──▶ [hair stage] ──▶ [clothing stage] ──▶ alternatives
//
// Every stage's output is persisted, which is what makes partial refinement
// possible:
//
//   * Refine clothing — resumes from the cached hair output. One billed call.
//     The hair result is reused exactly, not regenerated.
//   * Refine hair — must re-run from the source, then re-composite clothing,
//     because the clothing edit was applied on top of the hair pixels. Two
//     calls. The user's garment *selection* is preserved untouched; only the
//     compositing repeats. That is the guarantee the spec asks for
//     ("regenerate only affected domain while preserving the rest" — the
//     choices survive), and chaining image edits cannot do better without a
//     layer-aware model.
//
// A failing stage never silently degrades the result: the job records the
// failure, keeps whatever succeeded, and the UI offers a retry or a
// non-generative path.
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/makeover_job.dart';
import '../utils/garment_taxonomy.dart';
import 'photo_edit_api.dart';
import 'result_mirror.dart';

class CoordinatedMakeoverService {
  CoordinatedMakeoverService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    PhotoEditApi? api,
    String? apiKey,
    ResultMirror? mirror,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _injectedApi = api,
       // Real runs keep a copy of the result in our storage; tests that
       // inject a fake api opt in by passing a mirror.
       _mirror = mirror ?? (api == null ? ResultMirror() : null),
       _apiKey = apiKey ?? _compiledApiKey;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final PhotoEditApi? _injectedApi;
  final ResultMirror? _mirror;
  final String _apiKey;

  static const String _compiledApiKey = String.fromEnvironment('FASHN_API_KEY');

  /// AI-003: at least two separately selectable alternatives.
  static const int alternativesPerJob = 2;

  bool get isAiConfigured => _injectedApi != null || _apiKey.isNotEmpty;

  PhotoEditApi get _api => _injectedApi ?? PhotoEditApi(apiKey: _apiKey);

  String get _currentUserId => _auth.currentUser?.uid ?? '';

  /// The final images are the ones the user saves and posts, so they are
  /// copied into our storage; earlier stages only feed the next call.
  Future<List<String>> _keepCopies(List<String> outputs) async {
    final mirror = _mirror;
    final userId = _currentUserId;
    if (mirror == null || userId.isEmpty) return outputs;
    return [for (final url in outputs) await mirror.keep(url, userId)];
  }

  CollectionReference<Map<String, dynamic>> _jobsFor(String userId) =>
      _db.collection('users').doc(userId).collection('makeover_jobs');

  // ── Job lifecycle ───────────────────────────────────────────────────────

  /// Creates a job in the queued state. Nothing is generated yet.
  Future<MakeoverJob> createJob({
    required String sourceImageUrl,
    required MakeoverIntent intent,
  }) async {
    final userId = _currentUserId;
    if (userId.isEmpty) {
      throw StateError('Sign in to create a makeover.');
    }
    if (sourceImageUrl.isEmpty) {
      throw StateError('Add a photo before starting a makeover.');
    }
    if (intent.isEmpty) {
      throw StateError('Choose a clothing or hair change to continue.');
    }

    final stages = {
      for (final domain in MakeoverDomain.values)
        domain: MakeoverStage(
          domain: domain,
          status: intent.requestedDomains.contains(domain)
              ? MakeoverStageStatus.queued
              : MakeoverStageStatus.skipped,
        ),
    };

    final ref = _jobsFor(userId).doc();
    final job = MakeoverJob(
      id: ref.id,
      userId: userId,
      sourceImageUrl: sourceImageUrl,
      intent: intent,
      stages: stages,
    );

    await ref.set({
      ...job.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return job;
  }

  Stream<MakeoverJob?> watchJob(String jobId) {
    final userId = _currentUserId;
    if (userId.isEmpty || jobId.isEmpty) return Stream.value(null);

    return _jobsFor(userId)
        .doc(jobId)
        .snapshots()
        .map((doc) => doc.exists ? MakeoverJob.fromFirestore(doc) : null);
  }

  Stream<List<MakeoverJob>> watchRecentJobs({int limit = 20}) {
    final userId = _currentUserId;
    if (userId.isEmpty) return Stream.value(const []);

    return _jobsFor(userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(MakeoverJob.fromFirestore).toList(),
        );
  }

  Future<void> deleteJob(String jobId) async {
    final userId = _currentUserId;
    if (userId.isEmpty || jobId.isEmpty) return;
    await _jobsFor(userId).doc(jobId).delete();
  }

  // ── Generation ──────────────────────────────────────────────────────────

  /// Runs every requested domain in pipeline order.
  ///
  /// Returns the job as it finished. Safe to call again after a failure: only
  /// stages that have not succeeded are re-run.
  Future<MakeoverJob> run(MakeoverJob job) {
    return _runPipeline(job, from: null);
  }

  /// Re-runs one domain, preserving the other domain's selection.
  ///
  /// Passing [MakeoverDomain.clothing] resumes from the cached hair output and
  /// costs one call. Passing [MakeoverDomain.hair] restarts the pipeline,
  /// because clothing was composited on top of hair.
  Future<MakeoverJob> refine(
    MakeoverJob job, {
    required MakeoverDomain domain,
    MakeoverIntent? updatedIntent,
  }) async {
    final intent = updatedIntent ?? job.intent;

    // Reset the target domain and everything downstream of it.
    final invalidated = _domainsFrom(domain);
    final stages = {...job.stages};
    for (final entry in stages.entries) {
      final isRequested = intent.requestedDomains.contains(entry.key);
      if (!isRequested) {
        stages[entry.key] = entry.value.copyWith(
          status: MakeoverStageStatus.skipped,
          outputImageUrls: const [],
          errorMessage: '',
        );
        continue;
      }
      if (invalidated.contains(entry.key)) {
        stages[entry.key] = entry.value.copyWith(
          status: MakeoverStageStatus.queued,
          outputImageUrls: const [],
          errorMessage: '',
        );
      }
    }

    final reset = job.copyWith(
      intent: intent,
      stages: stages,
      alternatives: const [],
    );
    await _persist(reset);

    return _runPipeline(reset, from: domain);
  }

  /// Pipeline order from [domain] onwards.
  List<MakeoverDomain> _domainsFrom(MakeoverDomain domain) {
    final order = MakeoverDomain.values;
    final start = order.indexOf(domain);
    return order.sublist(start < 0 ? 0 : start);
  }

  Future<MakeoverJob> _runPipeline(
    MakeoverJob job, {
    required MakeoverDomain? from,
  }) async {
    if (!isAiConfigured) {
      throw StateError(
        'Image generation is not configured. Start the app with '
        '--dart-define-from-file=dart_defines.json',
      );
    }

    var current = job;
    final requested = current.intent.requestedDomains;
    if (requested.isEmpty) return current;

    // The image each stage builds on. Stages before the resume point keep
    // their cached output, so refinement does not repeat their work.
    var carrier = current.sourceImageUrl;
    final lastRequested = requested.last;

    for (final domain in MakeoverDomain.values) {
      if (!requested.contains(domain)) continue;

      final stage = current.stageFor(domain);

      // Reuse a stage that already succeeded and sits upstream of the change.
      if (stage.succeeded && stage.primaryOutput.isNotEmpty) {
        carrier = stage.primaryOutput;
        continue;
      }

      final isFinalStage = domain == lastRequested;
      current = await _markRunning(current, domain);

      try {
        final outputs = await _generateDomain(
          domain: domain,
          intent: current.intent,
          inputImageUrl: carrier,
          sampleCount: isFinalStage ? alternativesPerJob : 1,
        );

        if (outputs.isEmpty) {
          throw const MakeoverStageException(
            'The styling service returned no image.',
          );
        }

        final kept = isFinalStage ? await _keepCopies(outputs) : outputs;
        current = await _markSucceeded(current, domain, kept);
        carrier = kept.first;
      } on MakeoverStageException catch (error) {
        current = await _markFailed(current, domain, error.message);
        // Downstream stages cannot run without this stage's output.
        break;
      } on Exception catch (error) {
        debugPrint('Makeover stage ${domain.id} failed: $error');
        current = await _markFailed(
          current,
          domain,
          'We could not complete the ${domain.label.toLowerCase()} change.',
        );
        break;
      }
    }

    current = _withAlternatives(current);
    await _persist(current);
    return current;
  }

  Future<List<String>> _generateDomain({
    required MakeoverDomain domain,
    required MakeoverIntent intent,
    required String inputImageUrl,
    required int sampleCount,
  }) {
    return switch (domain) {
      MakeoverDomain.hair => _generateHair(
        intent: intent,
        inputImageUrl: inputImageUrl,
        sampleCount: sampleCount,
      ),
      MakeoverDomain.clothing => _generateClothing(
        intent: intent,
        inputImageUrl: inputImageUrl,
        sampleCount: sampleCount,
      ),
    };
  }

  Future<List<String>> _generateHair({
    required MakeoverIntent intent,
    required String inputImageUrl,
    required int sampleCount,
  }) async {
    return _api.applyHairStyle(
      imageUrl: inputImageUrl,
      prompt: buildHairPrompt(intent),
      numImages: sampleCount,
    );
  }

  /// Applies garments base-layer first, chaining each result into the next.
  ///
  /// Only the final garment produces multiple samples; intermediate layers
  /// stay single so cost scales with garment count, not with garments ×
  /// alternatives.
  Future<List<String>> _generateClothing({
    required MakeoverIntent intent,
    required String inputImageUrl,
    required int sampleCount,
  }) async {
    final garments = orderGarmentsForLayering(
      intent.garments,
    ).where((garment) => garmentImageUrlOf(garment).isNotEmpty).toList();

    if (garments.isEmpty) {
      throw const MakeoverStageException(
        'None of the selected items had a usable image.',
      );
    }

    var carrier = inputImageUrl;
    var results = <String>[carrier];

    for (var index = 0; index < garments.length; index += 1) {
      final garment = garments[index];
      final isLast = index == garments.length - 1;

      final outputs = await _api.tryOnClothes(
        modelImageUrl: carrier,
        garmentImageUrl: garmentImageUrlOf(garment),
        category: fashnCategoryFor(
          (garment['category'] ?? garment['subcategory'])?.toString(),
        ),
        numImages: isLast ? sampleCount : 1,
      );

      if (outputs.isEmpty) {
        final name = (garment['name'] ?? 'an item').toString();
        throw MakeoverStageException('No image was returned for $name.');
      }

      carrier = outputs.first;
      results = outputs;
    }

    return results;
  }

  /// Builds the hair instruction, scoped so generation cannot wander into
  /// identity. The spec forbids unsolicited changes to body shape, skin tone,
  /// facial structure or protected characteristics.
  @visibleForTesting
  static String buildHairPrompt(MakeoverIntent intent) {
    final parts = <String>[
      'Change only the hair to: ${intent.hairPrompt.trim()}.',
      if (intent.occasion.trim().isNotEmpty)
        'Styled for ${intent.occasion.trim()}.',
      if (intent.climate.trim().isNotEmpty)
        'Suited to ${intent.climate.trim()} conditions.',
      if (intent.modestyPreference.trim().isNotEmpty)
        'Respect this preference: ${intent.modestyPreference.trim()}.',
      if (intent.exclusions.isNotEmpty)
        'Avoid: ${intent.exclusions.join(', ')}.',
      'Preserve the face, skin tone, body shape and identity of the person '
          'exactly as photographed. Do not alter clothing.',
    ];
    return parts.join(' ');
  }

  /// Promotes the final stage's outputs to selectable alternatives.
  MakeoverJob _withAlternatives(MakeoverJob job) {
    final requested = job.intent.requestedDomains;
    if (requested.isEmpty) return job;

    // The deepest stage that succeeded holds the most complete image.
    MakeoverStage? deepest;
    for (final domain in MakeoverDomain.values) {
      if (!requested.contains(domain)) continue;
      final stage = job.stageFor(domain);
      if (stage.succeeded && stage.outputImageUrls.isNotEmpty) {
        deepest = stage;
      }
    }
    if (deepest == null) return job.copyWith(alternatives: const []);

    final applied = MakeoverDomain.values
        .where(
          (domain) =>
              requested.contains(domain) && job.stageFor(domain).succeeded,
        )
        .toList();

    final alternatives = <MakeoverAlternative>[];
    for (var index = 0; index < deepest.outputImageUrls.length; index += 1) {
      alternatives.add(
        MakeoverAlternative(
          index: index,
          imageUrl: deepest.outputImageUrls[index],
          appliedDomains: applied,
        ),
      );
    }

    return job.copyWith(alternatives: alternatives);
  }

  // ── State transitions ───────────────────────────────────────────────────

  Future<MakeoverJob> _markRunning(MakeoverJob job, MakeoverDomain domain) {
    return _updateStage(
      job,
      domain,
      job
          .stageFor(domain)
          .copyWith(
            status: MakeoverStageStatus.running,
            startedAt: DateTime.now(),
            errorMessage: '',
          ),
    );
  }

  Future<MakeoverJob> _markSucceeded(
    MakeoverJob job,
    MakeoverDomain domain,
    List<String> outputs,
  ) {
    return _updateStage(
      job,
      domain,
      job
          .stageFor(domain)
          .copyWith(
            status: MakeoverStageStatus.succeeded,
            outputImageUrls: outputs,
            completedAt: DateTime.now(),
            errorMessage: '',
          ),
    );
  }

  Future<MakeoverJob> _markFailed(
    MakeoverJob job,
    MakeoverDomain domain,
    String message,
  ) {
    return _updateStage(
      job,
      domain,
      job
          .stageFor(domain)
          .copyWith(
            status: MakeoverStageStatus.failed,
            errorMessage: message,
            completedAt: DateTime.now(),
          ),
    );
  }

  Future<MakeoverJob> _updateStage(
    MakeoverJob job,
    MakeoverDomain domain,
    MakeoverStage stage,
  ) async {
    final updated = job.copyWith(
      stages: {...job.stages, domain: stage},
      updatedAt: DateTime.now(),
    );
    await _persist(updated);
    return updated;
  }

  Future<void> _persist(MakeoverJob job) async {
    if (job.userId.isEmpty || job.id.isEmpty) return;
    try {
      await _jobsFor(job.userId).doc(job.id).set({
        ...job.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      // Losing a progress write must not abort a generation already paid for.
      debugPrint('Unable to persist makeover job ${job.id}: ${error.code}');
    }
  }
}

/// A stage failure with a message fit to show the user.
class MakeoverStageException implements Exception {
  const MakeoverStageException(this.message);

  final String message;

  @override
  String toString() => 'MakeoverStageException: $message';
}
