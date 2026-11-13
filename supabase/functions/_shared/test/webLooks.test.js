import assert from 'node:assert/strict';
import { describe, test } from 'node:test';

import { cleanQuery, toWebLooks, WEB_LOOK_LIMITS } from '../webLooks.js';

const result = (image, extra = {}) => ({
  title: 'Street style',
  url: 'https://www.example.com/page',
  source: 'example.com',
  thumbnail: { src: `https://imgs.search.brave.com/${encodeURIComponent(image)}` },
  properties: { url: image },
  ...extra,
});

describe('cleanQuery', () => {
  test('trims and collapses spaces', () => {
    assert.equal(cleanQuery('  Winky   D  outfit '), 'Winky D outfit');
  });

  test('rejects missing, too short and too long questions', () => {
    assert.equal(cleanQuery(undefined), '');
    assert.equal(cleanQuery(' a '), '');
    assert.equal(cleanQuery('x'.repeat(WEB_LOOK_LIMITS.queryChars + 1)), '');
  });
});

describe('toWebLooks', () => {
  test('keeps public HTTPS pictures with their source', () => {
    const looks = toWebLooks({ results: [result('https://cdn.example.com/a.jpg')] });
    assert.deepEqual(looks, [
      {
        imageUrl: 'https://cdn.example.com/a.jpg',
        thumbnailUrl: 'https://imgs.search.brave.com/https%3A%2F%2Fcdn.example.com%2Fa.jpg',
        title: 'Street style',
        source: 'example.com',
        pageUrl: 'https://www.example.com/page',
      },
    ]);
  });

  test('drops plain HTTP, private addresses and duplicates', () => {
    const looks = toWebLooks({
      results: [
        result('http://cdn.example.com/a.jpg'),
        result('https://192.168.1.5/a.jpg'),
        result('https://cdn.example.com/b.jpg'),
        result('https://cdn.example.com/b.jpg'),
      ],
    });
    assert.deepEqual(
      looks.map((look) => look.imageUrl),
      ['https://cdn.example.com/b.jpg'],
    );
  });

  test('falls back to the image as thumbnail and the page host as source', () => {
    const [look] = toWebLooks({
      results: [{ url: 'https://www.vogue.com/x', properties: { url: 'https://img.vogue.com/c.jpg' } }],
    });
    assert.equal(look.thumbnailUrl, 'https://img.vogue.com/c.jpg');
    assert.equal(look.source, 'vogue.com');
  });

  test('copes with an empty or malformed answer', () => {
    assert.deepEqual(toWebLooks(null), []);
    assert.deepEqual(toWebLooks({ results: 'nope' }), []);
  });
});
