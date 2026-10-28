'use strict';
const assert = require('node:assert/strict');
const { describe, test } = require('node:test');
const { cleanUrl, isFashion, itemId, kindOf, placesOf, toDoc, topicsOf } = require('../content/classify');

const NOW = new Date('2026-10-28T12:00:00Z');
const source = { id: 'vogue', name: 'Vogue', region: 'intl' };
const general = { id: 'herald', name: 'The Herald', region: 'zw', requireFashion: true };

const item = (extra = {}) => ({
  title: 'Spring runway report',
  link: 'https://mag.example/spring?utm_source=rss',
  publishedAt: new Date('2026-10-27T08:00:00Z'),
  categories: [],
  imageUrl: 'https://img.example/a.jpg',
  ...extra,
});

describe('isFashion', () => {
  test('recognises fashion words in the title or categories', () => {
    assert.equal(isFashion(item({ title: 'Harare designer wins award' })), true);
    assert.equal(isFashion(item({ title: 'Local news', categories: ['Fashion'] })), true);
    assert.equal(isFashion(item({ title: 'Braids and hairstyles for summer' })), true);
  });

  test('rejects ordinary news', () => {
    assert.equal(isFashion(item({ title: 'Parliament passes budget' })), false);
    assert.equal(isFashion(item({ title: 'Fastest bowler named' })), false);
  });
});

describe('kindOf', () => {
  test('an announced fashion week or show is an event', () => {
    assert.equal(kindOf(item({ title: 'Harare Fashion Week returns in March' })), 'event');
    assert.equal(kindOf(item({ title: 'Designer to host runway show' })), 'event');
    assert.equal(kindOf(item({ title: 'Fashion Week tickets go on sale' })), 'event');
  });

  test('pop-ups, expos, festivals and galas are events by nature', () => {
    assert.equal(kindOf(item({ title: 'Pop-up market opens' })), 'event');
    assert.equal(kindOf(item({ title: 'Free NYC Pop-Up' })), 'event');
    assert.equal(kindOf(item({ title: 'Inside the annual gala' })), 'event');
  });

  test('reporting on a past show, or a fashion-week category, is news', () => {
    assert.equal(kindOf(item({ title: 'Attending Paris Fashion Week and rejecting style rules' })), 'news');
    assert.equal(
      kindOf(item({ title: 'Spring 2027 collection review', categories: ['New York Fashion Week'] })),
      'news',
    );
    assert.equal(kindOf(item()), 'news');
  });
});

describe('placesOf and topicsOf', () => {
  test('find places from the title and categories', () => {
    assert.deepEqual(placesOf(item({ title: 'Harare designers meet Lagos buyers' })), ['harare', 'lagos']);
    assert.deepEqual(placesOf(item({ title: 'Made in South Africa', categories: ['Zimbabwe'] })), ['zimbabwe', 'south-africa']);
    assert.deepEqual(placesOf(item()), []);
  });

  test('find topics', () => {
    assert.deepEqual(topicsOf(item({ title: 'Ankara wedding looks' })), ['african-print', 'wedding']);
    assert.deepEqual(topicsOf(item({ title: 'Streetwear and menswear picks' })), ['streetwear', 'menswear']);
    assert.deepEqual(topicsOf(item()), []);
  });
});

describe('cleanUrl and itemId', () => {
  test('drops tracking and fragments, keeps real parameters', () => {
    assert.equal(cleanUrl('https://m.example/a?id=4&utm_source=x&fbclid=y#top'), 'https://m.example/a?id=4');
    assert.equal(cleanUrl('https://m.example/a?utm_medium=rss'), 'https://m.example/a');
  });

  test('refuses links that are not http(s)', () => {
    assert.equal(cleanUrl('javascript:alert(1)'), '');
    assert.equal(cleanUrl('ftp://x/y'), '');
    assert.equal(cleanUrl('not a url'), '');
  });

  test('the same story always gets the same id', () => {
    const a = itemId(cleanUrl('https://m.example/a?utm_source=x'));
    const b = itemId(cleanUrl('https://m.example/a#frag'));

    assert.equal(a, b);
    assert.match(a, /^[0-9a-f]{20}$/);
    assert.notEqual(a, itemId('https://m.example/b'));
  });
});

describe('toDoc', () => {
  test('builds a credited link preview', () => {
    const doc = toDoc(item(), source, NOW);

    assert.equal(doc.title, 'Spring runway report');
    assert.equal(doc.url, 'https://mag.example/spring');
    assert.equal(doc.imageUrl, 'https://img.example/a.jpg');
    assert.equal(doc.sourceId, 'vogue');
    assert.equal(doc.sourceName, 'Vogue');
    assert.equal(doc.kind, 'news');
    assert.equal(doc.publishedAt.toISOString(), '2026-10-27T08:00:00.000Z');
    assert.equal(doc.expiresAt.toISOString(), '2026-11-26T08:00:00.000Z');
  });

  test('never carries the article text', () => {
    const doc = toDoc(item({ description: 'Long copyrighted text', summary: 'more' }), source, NOW);

    assert.equal('description' in doc, false);
    assert.equal('summary' in doc, false);
    assert.equal('content' in doc, false);
  });

  test('keeps only secure picture links', () => {
    assert.equal(toDoc(item({ imageUrl: 'http://img/a.jpg' }), source, NOW).imageUrl, '');
    assert.equal(toDoc(item({ imageUrl: 'data:image/png;base64,AA' }), source, NOW).imageUrl, '');
  });

  test('filters general news sources to fashion', () => {
    assert.equal(toDoc(item({ title: 'Parliament passes budget' }), general, NOW), null);
    assert.notEqual(toDoc(item({ title: 'Harare designer shows collection' }), general, NOW), null);
  });

  test('skips stories older than thirty days and bad links', () => {
    assert.equal(toDoc(item({ publishedAt: new Date('2026-09-01T00:00:00Z') }), source, NOW), null);
    assert.equal(toDoc(item({ link: 'javascript:x' }), source, NOW), null);
  });

  test('uses now for a missing date and clamps a future one', () => {
    assert.equal(toDoc(item({ publishedAt: null }), source, NOW).publishedAt.toISOString(), NOW.toISOString());
    assert.equal(toDoc(item({ publishedAt: new Date('2027-01-01') }), source, NOW).publishedAt.toISOString(), NOW.toISOString());
  });

  test('shortens very long titles', () => {
    assert.ok(toDoc(item({ title: 'x'.repeat(400) }), source, NOW).title.length <= 180);
  });
});
