// AI image generation, done on the server.
//
// The app asks for pictures by adding a job (a row in `ai_jobs`); the
// `run-ai-job` Edge Function calls Gemini, stores the pictures and writes its
// progress back to the row, which the app watches live. Because the work is on
// the server it carries on when the app is closed, and the person gets a
// notification (and a push) when it is done. The Gemini key never ships in the
// app.
//
// A job is a list of steps. Each step sends some pictures and an instruction
// and gets back `count` new pictures; a picture is an address or the first
// picture made by an earlier step, which is how a makeover builds each change
// on top of the last.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:banigoba/core/supabase/supabase_config.dart';

/// What a job is for. Decides the notification's wording.
enum AiJobKind {
  look('look'),
  tryOn('try_on'),
  turnAround('turn_around'),
  makeover('makeover');

  const AiJobKind(this.id);

  final String id;
}

/// A picture handed to a step.
@immutable
sealed class AiImageRef {
  const AiImageRef();

  Object toJson();
}

/// A picture at an address.
final class AiImageUrl extends AiImageRef {
  const AiImageUrl(this.url);

  final String url;

  @override
  Object toJson() => url;

  @override
  bool operator ==(Object other) => other is AiImageUrl && other.url == url;

  @override
  int get hashCode => url.hashCode;
}

/// The first picture made by an earlier step of the same job.
final class AiStepImage extends AiImageRef {
  const AiStepImage(this.step);

  final int step;

  @override
  Object toJson() => {'step': step};

  @override
  bool operator ==(Object other) => other is AiStepImage && other.step == step;

  @override
  int get hashCode => step.hashCode;
}

/// One image edit: [images] and [prompt] in, [count] pictures out.
@immutable
class AiImageStep {
  const AiImageStep({
    required this.prompt,
    required this.images,
    this.count = 1,
  });

  final String prompt;
  final List<AiImageRef> images;
  final int count;

  Map<String, Object> toJson() => {
    'prompt': prompt,
    'images': [for (final image in images) image.toJson()],
    'count': count,
  };
}

/// What to make. [label] names it in the notification ("Your makeover").
/// [document] is a makeover the server should keep up to date as it works.
@immutable
class AiJobRequest {
  const AiJobRequest({
    required this.kind,
    required this.steps,
    this.label = '',
    this.document,
  });

  final AiJobKind kind;
  final List<AiImageStep> steps;
  final String label;
  final Map<String, Object>? document;

  Map<String, Object> toInput() => {
    'label': label,
    'steps': [for (final step in steps) step.toJson()],
    'document': ?document,
  };
}

enum AiJobStatus {
  queued,
  running,
  succeeded,
  failed;

  bool get isFinished => this == succeeded || this == failed;

  static AiJobStatus fromId(Object? id) => switch (id) {
    'running' => running,
    'succeeded' => succeeded,
    'failed' => failed,
    _ => queued,
  };
}

/// A job as the server last reported it.
@immutable
class AiJob {
  const AiJob({
    required this.id,
    required this.status,
    this.steps = const [],
    this.images = const [],
    this.error = '',
  });

  factory AiJob.fromRow(Map<String, dynamic> row) {
    final result = row['result'];
    final rawSteps = result is Map ? result['steps'] : null;
    final rawImages = result is Map ? result['images'] : null;
    return AiJob(
      id: (row['id'] ?? '').toString(),
      status: AiJobStatus.fromId(row['status']),
      steps: List.unmodifiable([
        if (rawSteps is List)
          for (final step in rawSteps)
            step is List ? List<String>.unmodifiable(_urls(step)) : null,
      ]),
      images: List.unmodifiable(
        rawImages is List ? _urls(rawImages) : const [],
      ),
      error: (row['error'] ?? '').toString(),
    );
  }

  static List<String> _urls(List<dynamic> items) => [
    for (final item in items)
      if (item is String && item.isNotEmpty) item,
  ];

  final String id;
  final AiJobStatus status;

  /// Each step's pictures, or null for a step not made yet.
  final List<List<String>?> steps;

  /// The finished pictures: those of the steps nothing else builds on.
  final List<String> images;
  final String error;

  /// The pictures of [step], or none yet.
  List<String> stepImages(int step) =>
      step < steps.length ? steps[step] ?? const [] : const [];
}

/// A job that could not be made, with a message fit to show the person.
class AiJobException implements Exception {
  const AiJobException(this.message, {this.isStillRunning = false});

  final String message;

  /// True when the app stopped waiting but the server is still working; the
  /// person will be notified when it is done.
  final bool isStillRunning;

  @override
  String toString() => message;
}

/// Runs image jobs on the server. Tests use a fake.
abstract interface class AiImageJobs {
  /// Starts [request] and waits for it, calling [onStep] as each step's
  /// pictures arrive. Returns the finished job; throws [AiJobException] if it
  /// fails or takes longer than the app waits. Leaving the page does not stop
  /// the job.
  Future<AiJob> run(
    AiJobRequest request, {
    void Function(int step, List<String> images)? onStep,
  });
}

class SupabaseAiImageJobs implements AiImageJobs {
  SupabaseAiImageJobs({SupabaseClient? client, Duration? waitFor})
    : _client = client,
      _waitFor = waitFor ?? const Duration(minutes: 10);

  final SupabaseClient? _client;
  final Duration _waitFor;

  SupabaseClient get _db => _client ?? supabase;

  @override
  Future<AiJob> run(
    AiJobRequest request, {
    void Function(int step, List<String> images)? onStep,
  }) async {
    final String jobId;
    try {
      final row = await _db
          .from('ai_jobs')
          .insert({'kind': request.kind.id, 'input': request.toInput()})
          .select('id')
          .single();
      jobId = row['id'].toString();
    } on PostgrestException catch (error) {
      debugPrint('Could not start AI job: ${error.code} ${error.message}');
      // The limits in the database speak for themselves.
      throw AiJobException(
        error.code == 'P0001'
            ? error.message
            : 'We could not start this. Please try again.',
      );
    }
    return _follow(jobId, onStep);
  }

  Future<AiJob> _follow(
    String jobId,
    void Function(int step, List<String> images)? onStep,
  ) async {
    final reported = <int>{};
    final finished = Completer<AiJob>();
    final subscription = _db
        .from('ai_jobs')
        .stream(primaryKey: ['id'])
        .eq('id', jobId)
        .listen(
          (rows) {
            if (rows.isEmpty || finished.isCompleted) return;
            final job = AiJob.fromRow(rows.first);
            for (var step = 0; step < job.steps.length; step += 1) {
              final images = job.stepImages(step);
              if (images.isEmpty || !reported.add(step)) continue;
              onStep?.call(step, images);
            }
            if (job.status.isFinished) finished.complete(job);
          },
          onError: (Object error) {
            debugPrint('Lost the live view of AI job $jobId: $error');
            if (!finished.isCompleted) {
              finished.completeError(
                const AiJobException(
                  'We lost touch while this was being made. We will let you '
                  'know when it is ready.',
                  isStillRunning: true,
                ),
              );
            }
          },
        );

    try {
      final job = await finished.future.timeout(
        _waitFor,
        onTimeout: () => throw const AiJobException(
          'This is taking a while. We will let you know when it is ready.',
          isStillRunning: true,
        ),
      );
      if (job.status == AiJobStatus.failed) {
        throw AiJobException(
          job.error.isEmpty
              ? 'We could not make this picture. Please try again.'
              : job.error,
        );
      }
      return job;
    } finally {
      await subscription.cancel();
    }
  }
}
