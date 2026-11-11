import assert from 'node:assert/strict';
import { describe, test } from 'node:test';
import {
  applyToMakeoverDocument,
  finalSteps,
  firstImage,
  isAllowedImageUrl,
  notificationFor,
  readySteps,
  RefusalError,
  resolveImages,
  validateJobInput,
} from '../aiJobs.js';

const photo = 'https://example.supabase.co/storage/v1/object/public/user-images/u/me.jpg';
const garment = 'https://cdn.shop.com/shirt.jpg';

describe('isAllowedImageUrl', () => {
  test('allows public https addresses', () => {
    assert.ok(isAllowedImageUrl(photo));
    assert.ok(isAllowedImageUrl(garment));
  });

  test('blocks http, private networks and odd hosts', () => {
    for (const url of [
      'http://cdn.shop.com/a.jpg',
      'https://localhost/a.jpg',
      'https://127.0.0.1/a.jpg',
      'https://10.0.0.4/a.jpg',
      'https://192.168.1.2/a.jpg',
      'https://172.20.0.1/a.jpg',
      'https://169.254.169.254/latest',
      'https://[::1]/a.jpg',
      'https://user:pw@cdn.shop.com/a.jpg',
      'https://cdn.shop.com:8443/a.jpg',
      'https://db.internal/a.jpg',
      'not a url',
      '',
      42,
    ]) {
      assert.equal(isAllowedImageUrl(url), false, String(url));
    }
  });
});

describe('validateJobInput', () => {
  test('accepts a chain and cleans it', () => {
    const input = validateJobInput('makeover', {
      label: '  Your makeover  ',
      steps: [
        { prompt: ' hair ', images: [photo] },
        { prompt: 'shirt', images: [{ step: 0 }, garment], count: 2 },
      ],
      document: { kind: 'makeoverJobs', id: 'x1', stages: [{ domain: 'hair', steps: [0] }, { domain: 'clothing', steps: [1] }] },
    });
    assert.equal(input.label, 'Your makeover');
    assert.equal(input.steps[0].prompt, 'hair');
    assert.equal(input.steps[0].count, 1);
    assert.deepEqual(input.steps[1].images, [{ step: 0 }, garment]);
    assert.equal(input.document.id, 'x1');
  });

  test('rejects what a job may not ask for', () => {
    const bad = [
      ['look', null],
      ['video', { steps: [{ prompt: 'p', images: [photo] }] }],
      ['look', { steps: [] }],
      ['look', { steps: [{ prompt: '', images: [photo] }] }],
      ['look', { steps: [{ prompt: 'p', images: [] }] }],
      ['look', { steps: [{ prompt: 'p', images: ['http://x.com/a.jpg'] }] }],
      ['look', { steps: [{ prompt: 'p', images: [{ step: 0 }] }] }],
      ['look', { steps: [{ prompt: 'p', images: [photo], count: 5 }] }],
      ['look', { steps: Array.from({ length: 9 }, () => ({ prompt: 'p', images: [photo] })) }],
      ['look', { steps: [{ prompt: 'p', images: [photo] }], document: { kind: 'makeoverJobs', id: 'x', stages: [{ domain: 'hair', steps: [0] }] } }],
      ['makeover', { steps: [{ prompt: 'p', images: [photo] }], document: { kind: 'makeoverJobs', id: 'x', stages: [{ domain: 'hair', steps: [3] }] } }],
    ];
    for (const [kind, input] of bad) {
      assert.throws(() => validateJobInput(kind, input), Error, JSON.stringify(input));
    }
  });
});

describe('step order', () => {
  const steps = [
    { prompt: 'a', images: [photo], count: 1 },
    { prompt: 'b', images: [{ step: 0 }, garment], count: 1 },
    { prompt: 'c', images: [{ step: 1 }], count: 2 },
  ];

  test('a step waits for the pictures it builds on', () => {
    assert.deepEqual(readySteps(steps, [null, null, null]), [0]);
    assert.deepEqual(readySteps(steps, [['u0'], null, null]), [1]);
    assert.deepEqual(readySteps(steps, [['u0'], ['u1'], null]), [2]);
    assert.deepEqual(readySteps(steps, [['u0'], ['u1'], ['u2', 'u3']]), []);
  });

  test('independent steps are ready together', () => {
    const angles = [0, 1, 2].map((i) => ({ prompt: `view ${i}`, images: [photo], count: 1 }));
    assert.deepEqual(readySteps(angles, [null, ['done'], null]), [0, 2]);
    assert.deepEqual(readySteps(angles, [null, null, null], new Set([0])), [1, 2]);
  });

  test('earlier results fill in the picture list', () => {
    assert.deepEqual(resolveImages(steps[1], [['u0', 'other'], null, null]), ['u0', garment]);
  });

  test('the final steps are the ones nothing builds on', () => {
    assert.deepEqual(finalSteps(steps), [2]);
    const angles = [0, 1, 2].map(() => ({ prompt: 'v', images: [photo], count: 1 }));
    assert.deepEqual(finalSteps(angles), [0, 1, 2]);
  });
});

describe('firstImage', () => {
  test('finds the image in the timeline', () => {
    const image = firstImage({
      steps: [
        { content: [{ type: 'text', text: 'here' }] },
        { content: [{ type: 'image', data: 'AAAA', mime_type: 'image/png; q=1' }] },
      ],
    });
    assert.deepEqual(image, { data: 'AAAA', mimeType: 'image/png' });
  });

  test('a text-only answer is a refusal carrying the model\'s words', () => {
    assert.throws(
      () => firstImage({ steps: [{ content: [{ type: 'text', text: 'I cannot edit this photo.' }] }] }),
      (error) => error instanceof RefusalError && error.message.includes('I cannot edit this photo.'),
    );
    assert.throws(() => firstImage({}), /no steps/);
  });
});

describe('notificationFor', () => {
  const job = {
    id: 'j1',
    user_id: 'u1',
    kind: 'makeover',
    input: {
      label: 'Your makeover',
      steps: [
        { prompt: 'hair', images: [photo] },
        { prompt: 'shirt', images: [{ step: 0 }, garment] },
      ],
    },
  };

  test('a finished job points at the result and the photo it started from', () => {
    const note = notificationFor(job, 'succeeded', 'https://x/look.jpg');
    assert.equal(note.user_id, 'u1');
    assert.equal(note.type, 'ai_job');
    assert.equal(note.title, 'Your makeover is ready');
    assert.equal(note.body, 'Tap to see your before and after.');
    assert.deepEqual(note.extra_data, {
      jobId: 'j1',
      kind: 'makeover',
      status: 'succeeded',
      imageUrl: 'https://x/look.jpg',
      beforeUrl: photo,
    });
  });

  test('a job with no address to start from has no before picture', () => {
    assert.equal(notificationFor({ ...job, input: {} }, 'succeeded', 'x').extra_data.beforeUrl, '');
  });

  test('a failed job says so', () => {
    const note = notificationFor(job, 'failed');
    assert.equal(note.title, 'Your look did not finish');
    assert.equal(note.extra_data.status, 'failed');
  });
});

describe('applyToMakeoverDocument', () => {
  const spec = { kind: 'makeoverJobs', id: 'x', stages: [{ domain: 'hair', steps: [0] }, { domain: 'clothing', steps: [1, 2] }] };
  const doc = { userId: 'u1', stages: { hair: { status: 'queued' }, clothing: { status: 'queued' } } };

  test('marks stages as they run and finish', () => {
    const running = applyToMakeoverDocument(doc, spec, {
      done: [['h'], null, null], started: new Set([1]), failed: new Set(), finished: false, error: '',
    });
    assert.equal(running.userId, 'u1');
    assert.equal(running.stages.hair.status, 'succeeded');
    assert.deepEqual(running.stages.hair.outputImageUrls, ['h']);
    assert.equal(running.stages.clothing.status, 'running');
    assert.deepEqual(running.alternatives, []);
  });

  test('the deepest finished stage gives the alternatives', () => {
    const done = applyToMakeoverDocument(doc, spec, {
      done: [['h'], ['c1'], ['a', 'b']], started: new Set(), failed: new Set(), finished: true, error: '',
    });
    assert.equal(done.stages.clothing.status, 'succeeded');
    assert.deepEqual(done.stages.clothing.outputImageUrls, ['a', 'b']);
    assert.deepEqual(done.alternatives, ['a', 'b']);
  });

  test('a failed stage keeps what worked before it', () => {
    const failed = applyToMakeoverDocument(doc, spec, {
      done: [['h'], null, null], started: new Set(), failed: new Set([1]), finished: true, error: 'refused',
    });
    assert.equal(failed.stages.hair.status, 'succeeded');
    assert.equal(failed.stages.clothing.status, 'failed');
    assert.equal(failed.stages.clothing.errorMessage, 'refused');
    assert.deepEqual(failed.alternatives, ['h']);
  });
});
