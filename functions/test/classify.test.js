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

const { eventDateOf } = require('../content/classify');

describe('eventDateOf', () => {
  const now = new Date('2026-10-28T12:00:00Z');
  const day = (iso) => new Date(`${iso}T00:00:00Z`).getTime();

  test('reads "12 November" and "12th Nov"', () => {
    assert.equal(eventDateOf('Harare Fashion Week opens on 12 November', now).getTime(), day('2026-11-12'));
    assert.equal(eventDateOf('Pop-up market on 3rd Dec', now).getTime(), day('2026-12-03'));
  });

  test('reads "November 12" and "Nov 12th"', () => {
    assert.equal(eventDateOf('Gala set for November 12', now).getTime(), day('2026-11-12'));
    assert.equal(eventDateOf('Expo returns Nov 20th', now).getTime(), day('2026-11-20'));
  });

  test('takes the first day of a range', () => {
    assert.equal(eventDateOf('Fashion week runs 12-14 November', now).getTime(), day('2026-11-12'));
    assert.equal(eventDateOf('Festival 12 – 14 November', now).getTime(), day('2026-11-12'));
  });

  test('uses a year when the title gives one', () => {
    assert.equal(eventDateOf('Fashion Week returns 5 March 2027', now).getTime(), day('2027-03-05'));
  });

  test('a date earlier in the year means next year, when it is not just past', () => {
    assert.equal(eventDateOf('Fashion Week returns on 5 March', now).getTime(), day('2027-03-05'));
  });

  test('a date that has only just passed is not an event any more', () => {
    assert.equal(eventDateOf('Show was on 20 October', now), null);
  });

  test('"in March" with no day gives no date', () => {
    assert.equal(eventDateOf('Harare Fashion Week returns in March', now), null);
    assert.equal(eventDateOf('Spring runway report', now), null);
  });

  test('ignores numbers that are not dates', () => {
    assert.equal(eventDateOf('Top 12 looks from the show', now), null);
    assert.equal(eventDateOf('Fashion Week 2027 tickets go on sale', now), null);
  });

  test('ignores dates too far away to be believed', () => {
    assert.equal(eventDateOf('Expo on 5 March 2031', now), null);
  });
});

describe('toDoc for events', () => {
  const now = new Date('2026-10-28T12:00:00Z');
  const source = { id: 'fwo', name: 'Fashion Week Online', region: 'intl' };
  const item = (title) => ({
    title,
    link: 'https://fwo.example/x',
    publishedAt: new Date('2026-10-27T08:00:00Z'),
    categories: [],
    imageUrl: '',
  });

  test('keeps the date of an event and does not expire it before it happens', () => {
    const doc = toDoc(item('Harare Fashion Week returns on 20 December'), source, now);

    assert.equal(doc.kind, 'event');
    assert.equal(doc.startsAt.toISOString(), '2026-12-20T00:00:00.000Z');
    assert.ok(doc.expiresAt.getTime() >= doc.startsAt.getTime() + 24 * 3600 * 1000);
  });

  test('news never gets an event date', () => {
    const doc = toDoc(item('Review of the 12 November collection'), source, now);

    assert.equal(doc.kind, 'news');
    assert.equal('startsAt' in doc, false);
  });

  test('an event with no readable date has none', () => {
    const doc = toDoc(item('Harare Fashion Week returns in March'), source, now);

    assert.equal(doc.kind, 'event');
    assert.equal('startsAt' in doc, false);
  });
});
