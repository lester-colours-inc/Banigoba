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
//
// The pictures are made on the server (see ai_job_service.dart): the app
// plans the steps, the server runs them and keeps the stored job up to date,
// so a makeover finishes, and the person is told, even if the app is closed.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/app_auth.dart';
import '../../core/supabase/supabase_config.dart';
import '../supabase/storage_files.dart' show randomFileName;

import '../models/makeover_job.dart';
import '../utils/garment_taxonomy.dart';
import 'ai_job_service.dart';

class CoordinatedMakeoverService {
  CoordinatedMakeoverService({AiImageJobs? jobs})
    : _jobs = jobs ?? SupabaseAiImageJobs();

  final AiImageJobs _jobs;

  /// AI-003: at least two separately selectable alternatives.
  static const int alternativesPerJob = 2;

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
    return _runPipeline(job);
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

    return _runPipeline(reset);
  }

  /// Pipeline order from [domain] onwards.
  List<MakeoverDomain> _domainsFrom(MakeoverDomain domain) {
    final order = MakeoverDomain.values;
    final start = order.indexOf(domain);
    return order.sublist(start < 0 ? 0 : start);
  }

  Future<MakeoverJob> _runPipeline(MakeoverJob job) async {
    if (job.userId.isEmpty) {
      throw StateError('Sign in to create a makeover.');
    }
    final plan = planSteps(job);

    // A stage that cannot even start (no usable garment pictures) fails now;
    // the stages before it still run.
    var current = job;
    for (final entry in plan.failures.entries) {
      current = current.copyWith(
        stages: {
          ...current.stages,
          entry.key: current
              .stageFor(entry.key)
              .copyWith(
                status: MakeoverStageStatus.failed,
                outputImageUrls: const [],
                errorMessage: entry.value,
                completedAt: DateTime.now(),
              ),
        },
      );
    }
    await _persist(current);
    if (plan.steps.isEmpty) return _finish(current);

    try {
      await _jobs.run(
        AiJobRequest(
          kind: AiJobKind.makeover,
          label: 'Your makeover',
          steps: plan.steps,
          document: {
            'kind': _kind,
            'id': current.id,
            'stages': [
              for (final entry in plan.stageSteps.entries)
                {'domain': entry.key.id, 'steps': entry.value},
            ],
          },
        ),
      );
    } on AiJobException catch (error) {
      // The server has recorded which stage failed; a job still running will
      // be finished there and the person told.
      debugPrint('Makeover ${current.id}: ${error.message}');
      if (error.isStillRunning) return await _load(current.id) ?? current;
    }

    return _finish(await _load(current.id) ?? current);
  }

  /// Fills in the alternatives when the server's run left none to offer but
  /// an earlier stage (kept from before) did succeed.
  Future<MakeoverJob> _finish(MakeoverJob job) async {
    if (job.alternatives.isNotEmpty) return job;
    final finished = _withAlternatives(job);
    if (finished.alternatives.isNotEmpty) await _persist(finished);
    return finished;
  }

  Future<MakeoverJob?> _load(String jobId) async {
    final userId = _currentUserId;
    if (userId.isEmpty) return null;
    try {
      final row = await supabase
          .from('user_documents')
          .select()
          .eq('user_id', userId)
          .eq('kind', _kind)
          .eq('id', jobId)
          .maybeSingle();
      return row == null ? null : _readJob(row);
    } on PostgrestException catch (error) {
      debugPrint('Unable to read makeover job $jobId: ${error.code}');
      return null;
    }
  }

  /// The image edits that make [job], in order, and which of them make each
  /// stage. Stages that already succeeded upstream of a change are reused, so
  /// refinement does not repeat their work.
  @visibleForTesting
  static MakeoverPlan planSteps(MakeoverJob job) {
    final requested = job.intent.requestedDomains;
    final steps = <AiImageStep>[];
    final stageSteps = <MakeoverDomain, List<int>>{};
    final failures = <MakeoverDomain, String>{};
    if (requested.isEmpty) {
      return const MakeoverPlan(steps: [], stageSteps: {}, failures: {});
    }

    // The image each stage builds on.
    AiImageRef carrier = AiImageUrl(job.sourceImageUrl);
    final lastRequested = requested.last;

    for (final domain in MakeoverDomain.values) {
      if (!requested.contains(domain)) continue;

      final stage = job.stageFor(domain);
      if (stage.succeeded && stage.primaryOutput.isNotEmpty) {
        carrier = AiImageUrl(stage.primaryOutput);
        continue;
      }

      final sampleCount = domain == lastRequested ? alternativesPerJob : 1;
      final indices = <int>[];
      switch (domain) {
        case MakeoverDomain.hair:
          indices.add(steps.length);
          steps.add(
            AiImageStep(
              prompt: buildHairPrompt(job.intent),
              images: [carrier],
              count: sampleCount,
            ),
          );
        case MakeoverDomain.clothing:
          // Base layer first; only the last garment makes alternatives, so
          // cost scales with garments, not garments × alternatives.
          final garments = orderGarmentsForLayering(
            job.intent.garments,
          ).where((garment) => garmentImageUrlOf(garment).isNotEmpty).toList();
          if (garments.isEmpty) {
            failures[domain] = 'None of the selected items had a usable image.';
            break;
          }
          for (var index = 0; index < garments.length; index += 1) {
            final garment = garments[index];
            final isLast = index == garments.length - 1;
            indices.add(steps.length);
            steps.add(
              AiImageStep(
                prompt: buildGarmentPrompt(garment),
                images: [
                  if (index == 0) carrier else AiStepImage(steps.length - 1),
                  AiImageUrl(garmentImageUrlOf(garment)),
                ],
                count: isLast ? sampleCount : 1,
              ),
            );
          }
      }
      // Downstream stages cannot run without this stage's output.
      if (failures.containsKey(domain)) break;
      stageSteps[domain] = indices;
      carrier = AiStepImage(indices.last);
    }

    return MakeoverPlan(
      steps: List.unmodifiable(steps),
      stageSteps: Map.unmodifiable(stageSteps),
      failures: Map.unmodifiable(failures),
    );
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

  // ── Storage ─────────────────────────────────────────────────────────────

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

/// The steps a makeover needs (see [CoordinatedMakeoverService.planSteps]).
@immutable
class MakeoverPlan {
  const MakeoverPlan({
    required this.steps,
    required this.stageSteps,
    required this.failures,
  });

  final List<AiImageStep> steps;

  /// The steps that make each stage, in pipeline order.
  final Map<MakeoverDomain, List<int>> stageSteps;

  /// Stages that cannot start, with the reason to show.
  final Map<MakeoverDomain, String> failures;
}
