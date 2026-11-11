// Verifies how image jobs are described to the server and read back.
import 'package:banigoba/data/services/ai_job_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a request becomes the input the server checks', () {
    const request = AiJobRequest(
      kind: AiJobKind.makeover,
      label: 'Your makeover',
      steps: [
        AiImageStep(prompt: 'hair', images: [AiImageUrl('https://x/me.jpg')]),
        AiImageStep(
          prompt: 'shirt',
          images: [AiStepImage(0), AiImageUrl('https://x/shirt.jpg')],
          count: 2,
        ),
      ],
      document: {'kind': 'makeoverJobs', 'id': 'j1'},
    );

    expect(request.kind.id, 'makeover');
    expect(request.toInput(), {
      'label': 'Your makeover',
      'steps': [
        {
          'prompt': 'hair',
          'images': ['https://x/me.jpg'],
          'count': 1,
        },
        {
          'prompt': 'shirt',
          'images': [
            {'step': 0},
            'https://x/shirt.jpg',
          ],
          'count': 2,
        },
      ],
      'document': {'kind': 'makeoverJobs', 'id': 'j1'},
    });
  });

  test('a request without a document leaves it out', () {
    const request = AiJobRequest(
      kind: AiJobKind.look,
      steps: [
        AiImageStep(prompt: 'p', images: [AiImageUrl('https://x/a.jpg')]),
      ],
    );
    expect(request.toInput().containsKey('document'), isFalse);
  });

  test('reads a row, with steps not made yet as null', () {
    final job = AiJob.fromRow({
      'id': 'j1',
      'status': 'running',
      'result': {
        'steps': [
          ['https://x/1.jpg'],
          null,
        ],
      },
      'error': '',
    });

    expect(job.status, AiJobStatus.running);
    expect(job.status.isFinished, isFalse);
    expect(job.stepImages(0), ['https://x/1.jpg']);
    expect(job.stepImages(1), isEmpty);
    expect(job.stepImages(5), isEmpty);
    expect(job.images, isEmpty);
  });

  test('reads a finished row and its error', () {
    final done = AiJob.fromRow({
      'id': 'j1',
      'status': 'succeeded',
      'result': {
        'images': ['https://x/a.jpg', '', 3],
      },
    });
    final failed = AiJob.fromRow({
      'id': 'j2',
      'status': 'failed',
      'error': 'refused',
    });

    expect(done.status.isFinished, isTrue);
    expect(done.images, ['https://x/a.jpg']);
    expect(failed.status, AiJobStatus.failed);
    expect(failed.error, 'refused');
    expect(AiJobStatus.fromId('weird'), AiJobStatus.queued);
  });
}
