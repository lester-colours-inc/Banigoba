'use strict';
const assert = require('node:assert/strict');
const { describe, test } = require('node:test');
const { parseFeed } = require('../content/feed');

const rss = (items) => `<?xml version="1.0"?>
<rss version="2.0" xmlns:media="http://search.yahoo.com/mrss/" xmlns:content="http://purl.org/rss/1.0/modules/content/" xmlns:dc="http://purl.org/dc/elements/1.1/">
<channel><title>Mag</title>${items}</channel></rss>`;

describe('parseFeed (RSS)', () => {
  test('reads title, link, date and categories', () => {
    const items = parseFeed(
      rss(`<item>
        <title>Spring runway report</title>
        <link>https://mag.example/spring</link>
        <pubDate>Tue, 27 Oct 2026 08:00:00 GMT</pubDate>
        <category>Runway</category><category>Spring</category>
      </item>`),
    );

    assert.equal(items.length, 1);
    assert.equal(items[0].title, 'Spring runway report');
    assert.equal(items[0].link, 'https://mag.example/spring');
    assert.equal(items[0].publishedAt.toISOString(), '2026-10-27T08:00:00.000Z');
    assert.deepEqual(items[0].categories, ['Runway', 'Spring']);
  });

  test('finds a picture from media:content, media:thumbnail or an enclosure', () => {
    const items = parseFeed(
      rss(`
      <item><title>A</title><link>https://m/a</link><media:content url="https://img/a.jpg" medium="image"/></item>
      <item><title>B</title><link>https://m/b</link><media:thumbnail url="https://img/b.jpg"/></item>
      <item><title>C</title><link>https://m/c</link><enclosure url="https://img/c.jpg" type="image/jpeg"/></item>
      <item><title>D</title><link>https://m/d</link><enclosure url="https://aud/d.mp3" type="audio/mpeg"/></item>`),
    );

    assert.deepEqual(
      items.map((item) => item.imageUrl),
      ['https://img/a.jpg', 'https://img/b.jpg', 'https://img/c.jpg', ''],
    );
  });

  test('falls back to the first picture in the body', () => {
    const items = parseFeed(
      rss(`<item><title>E</title><link>https://m/e</link>
        <content:encoded><![CDATA[<p>Hi</p><img src="https://img/e.jpg" alt="x"/>]]></content:encoded></item>`),
    );

    assert.equal(items[0].imageUrl, 'https://img/e.jpg');
  });

  test('decodes entities and trims titles', () => {
    const items = parseFeed(
      rss(`<item><title>  Tom &amp; Jerry&#8217;s look  </title><link>https://m/f</link></item>`),
    );

    assert.equal(items[0].title, 'Tom & Jerry’s look');
  });

  test('handles a feed with a single item', () => {
    assert.equal(
      parseFeed(rss(`<item><title>Only</title><link>https://m/o</link></item>`)).length,
      1,
    );
  });

  test('skips items with no title or no link', () => {
    const items = parseFeed(
      rss(`<item><title>No link</title></item>
           <item><link>https://m/x</link></item>
           <item><title>Good</title><link>https://m/g</link></item>`),
    );

    assert.deepEqual(items.map((item) => item.title), ['Good']);
  });

  test('an unreadable date gives null', () => {
    const items = parseFeed(
      rss(`<item><title>T</title><link>https://m/t</link><pubDate>soon</pubDate></item>`),
    );

    assert.equal(items[0].publishedAt, null);
  });
});

describe('parseFeed (Atom)', () => {
  const atom = `<?xml version="1.0"?>
  <feed xmlns="http://www.w3.org/2005/Atom" xmlns:media="http://search.yahoo.com/mrss/">
    <entry>
      <title>Atom story</title>
      <link rel="alternate" href="https://a.example/story"/>
      <link rel="self" href="https://a.example/self"/>
      <updated>2026-10-26T10:00:00Z</updated>
      <category term="Style"/>
      <media:thumbnail url="https://img/atom.jpg"/>
    </entry>
  </feed>`;

  test('reads the alternate link, date, category and picture', () => {
    const [item] = parseFeed(atom);

    assert.equal(item.title, 'Atom story');
    assert.equal(item.link, 'https://a.example/story');
    assert.equal(item.publishedAt.toISOString(), '2026-10-26T10:00:00.000Z');
    assert.deepEqual(item.categories, ['Style']);
    assert.equal(item.imageUrl, 'https://img/atom.jpg');
  });
});

describe('parseFeed (bad input)', () => {
  test('returns nothing for HTML or garbage', () => {
    assert.deepEqual(parseFeed('<!doctype html><html><body>Just a moment</body></html>'), []);
    assert.deepEqual(parseFeed('not xml at all'), []);
    assert.deepEqual(parseFeed(''), []);
  });
});
