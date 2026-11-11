// A stand-in for the server's image jobs: records what was asked and answers
// each step with a made-up address, step by step.
import 'package:banigoba/data/services/ai_job_service.dart';

class FakeAiImageJobs implements AiImageJobs {
  FakeAiImageJobs({this.failOnStep = -1});

  /// The step that fails, or -1 for none.
  final int failOnStep;
  final List<AiJobRequest> requests = [];

  @override
  Future<AiJob> run(
    AiJobRequest request, {
    void Function(int step, List<String> images)? onStep,
  }) async {
    requests.add(request);
    final steps = <List<String>?>[];
    for (var index = 0; index < request.steps.length; index += 1) {
      if (index == failOnStep) {
        throw const AiJobException('model refused');
      }
      final urls = [
        for (var n = 0; n < request.steps[index].count; n += 1)
          'https://x/step-$index-$n.png',
      ];
      steps.add(urls);
      onStep?.call(index, urls);
    }
    return AiJob(
      id: 'job-1',
      status: AiJobStatus.succeeded,
      steps: steps,
      images: steps.last ?? const [],
    );
  }
}
