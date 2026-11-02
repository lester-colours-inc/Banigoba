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

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/app_auth.dart';
import '../../core/supabase/supabase_config.dart';
import '../supabase/storage_files.dart' show randomFileName;

import '../models/makeover_job.dart';
import '../utils/garment_taxonomy.dart';
import 'look_generation_service.dart';
import 'storage_service.dart';

class CoordinatedMakeoverService {
  CoordinatedMakeoverService({
    LookImageGenerator? generator,
    LookUploader? save,
  }) : _generator = generator ?? GeminiLookGenerator(),
       _injectedSave = save;

  final LookImageGenerator _generator;
  final LookUploader? _injectedSave;

  /// AI-003: at least two separately selectable alternatives.
  static const int alternativesPerJob = 2;

  bool get isAiConfigured => _generator.isConfigured;

  LookUploader get _save =>
      _injectedSave ?? StorageService().uploadTryOnResultBytes;

  String get _currentUserId => AppAuth.instance.currentUser?.uid ?? '';

  /// Jobs are private documents of kind `makeoverJobs`.
  static const String _kind = 'makeoverJobs';

  MakeoverJob _readJob(Map<String, dynamic> row) {
    final data = Map<String, dynamic>.from(row['data'] as Map? ?? {});
    data['createdAt'] ??= row['created_at'];
    data['updatedAt'] = row['updated_at'];
    return MakeoverJob.fromDocument(row['id'].toString(), data);
  }

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

    final job = MakeoverJob(
      id: randomFileName('x').split('.').first,
      userId: userId,
      sourceImageUrl: sourceImageUrl,
      intent: intent,
      stages: stages,
    );

    await supabase.from('user_documents').insert({
      'user_id': userId,
      'kind': _kind,
      'id': job.id,
      'data': job.toMap(),
    });

    return job;
  }

  Stream<MakeoverJob?> watchJob(String jobId) {
    final userId = _currentUserId;
    if (userId.isEmpty || jobId.isEmpty) return Stream.value(null);

    return supabase
        .from('user_documents')
        .stream(primaryKey: ['user_id', 'kind', 'id'])
        .eq('user_id', userId)
        .map((rows) {
          for (final row in rows) {
            if (row['kind'] == _kind && row['id'] == jobId) {
              return _readJob(row);
            }
          }
          return null;
        });
  }

  Stream<List<MakeoverJob>> watchRecentJobs({int limit = 20}) {
    final userId = _currentUserId;
    if (userId.isEmpty) return Stream.value(const []);

    return supabase
        .from('user_documents')
        .stream(primaryKey: ['user_id', 'kind', 'id'])
        .eq('user_id', userId)
        .map((rows) {
          final jobs =
              [
                for (final row in rows)
                  if (row['kind'] == _kind) _readJob(row),
              ]..sort(
                (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
                  a.createdAt ?? DateTime(0),
                ),
              );
          return jobs.take(limit).toList();
        });
  }

  Future<void> deleteJob(String jobId) async {
    final userId = _currentUserId;
    if (userId.isEmpty || jobId.isEmpty) return;
    await supabase
        .from('user_documents')
        .delete()
        .eq('user_id', userId)
        .eq('kind', _kind)
        .eq('id', jobId);
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

        current = await _markSucceeded(current, domain, outputs);
        carrier = outputs.first;
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
    return _images(
      photoUrl: inputImageUrl,
      prompt: buildHairPrompt(intent),
      count: sampleCount,
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

      final outputs = await _images(
        photoUrl: carrier,
        prompt: buildGarmentPrompt(garment),
        references: [garmentImageUrlOf(garment)],
        count: isLast ? sampleCount : 1,
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

  /// Generates [count] images (one Gemini call each, in parallel) and keeps
  /// them in our storage, returning their addresses.
  Future<List<String>> _images({
    required String photoUrl,
    required String prompt,
    List<String> references = const [],
    required int count,
  }) async {
    final userId = _currentUserId;
    if (userId.isEmpty) {
      throw const MakeoverStageException('Sign in to create a makeover.');
    }
    return Future.wait([
      for (var i = 0; i < count; i += 1)
        _generator
            .generate(
              photoUrl: photoUrl,
              prompt: prompt,
              referenceImageUrls: references,
            )
            .then((bytes) => _save(bytes, userId)),
    ]);
  }

  /// Puts one garment on the person, leaving everything else as it is.
  static String buildGarmentPrompt(Map<String, dynamic> garment) {
    final name = (garment['name'] ?? 'the item').toString().trim();
    return 'The first image is a photo of a person. The second image is '
        '$name. Generate one photorealistic image of the same person wearing '
        '$name exactly as shown: keep its colour, pattern, print, texture, '
        'length and cut identical. Keep the face, skin tone, body shape, '
        'hair, pose, background and every other piece of clothing unchanged.';
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
      await supabase.from('user_documents').upsert({
        'user_id': job.userId,
        'kind': _kind,
        'id': job.id,
        'data': job.toMap(),
      });
    } on PostgrestException catch (error) {
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
