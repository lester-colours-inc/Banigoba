// Reads an RSS or Atom feed into plain items: title, link, date, categories
// and a picture address. Nothing is downloaded beyond the feed itself; the
// picture is only ever linked to, never copied.

import { XMLParser } from 'fast-xml-parser';

const parser = new XMLParser({
  ignoreAttributes: false,
  attributeNamePrefix: '@_',
  textNodeName: '#text',
  processEntities: true,
  htmlEntities: true,
  trimValues: true,
});

const list = (value) => (value === undefined || value === null ? [] : Array.isArray(value) ? value : [value]);

/** The text of a node that may carry attributes, or a plain string. */
function textOf(node) {
  if (node === undefined || node === null) return '';
  if (typeof node === 'object') return textOf(node['#text']);
  return String(node).trim();
}

const isImage = (node) => {
  const type = String(node['@_type'] || node['@_medium'] || '').toLowerCase();
  return type === '' ? /\.(jpe?g|png|webp|gif)(\?|$)/i.test(node['@_url'] || '') : type.startsWith('image');
};

function imageIn(html) {
  const match = /<img[^>]+src=["']([^"']+)["']/i.exec(html || '');
  return match ? match[1] : '';
}

/** The best picture the item offers, or ''. */
function pictureOf(item) {
  for (const node of list(item['media:content'])) {
    if (node['@_url'] && isImage(node)) return node['@_url'];
  }
  for (const node of list(item['media:thumbnail'])) {
    if (node['@_url']) return node['@_url'];
  }
  for (const node of list(item.enclosure)) {
    if (node['@_url'] && String(node['@_type'] || '').toLowerCase().startsWith('image')) {
      return node['@_url'];
    }
  }
  return (
    imageIn(textOf(item['content:encoded'])) ||
    imageIn(textOf(item.content)) ||
    imageIn(textOf(item.description))
  );
}

function dateOf(value) {
  const text = textOf(value);
  if (text === '') return null;
  const date = new Date(text);
  return Number.isNaN(date.getTime()) ? null : date;
}

function atomLink(links) {
  const all = list(links);
  const alternate = all.find((link) => !link['@_rel'] || link['@_rel'] === 'alternate');
  return (alternate || all[0] || {})['@_href'] || '';
}

function categoriesOf(item) {
  return list(item.category)
    .map((node) => (typeof node === 'object' && node['@_term'] ? node['@_term'] : textOf(node)))
    .map((name) => String(name).trim())
    .filter(Boolean);
}

/** Items from RSS 2.0 or Atom text; [] for anything else. */
function parseFeed(xml) {
  let tree;
  try {
    tree = parser.parse(String(xml || ''));
  } catch (_) {
    return [];
  }
  const rawItems = [
    ...list(tree?.rss?.channel?.item),
    ...list(tree?.feed?.entry),
  ];
  const items = [];
  for (const raw of rawItems) {
    const title = textOf(raw.title);
    const link = raw.link && !Array.isArray(raw.link) && typeof raw.link !== 'object'
      ? textOf(raw.link)
      : atomLink(raw.link) || textOf(list(raw.link)[0]);
    if (title === '' || link === '') continue;
    items.push({
      title,
      link,
      publishedAt: dateOf(raw.pubDate) || dateOf(raw.published) || dateOf(raw.updated) || dateOf(raw['dc:date']),
      categories: categoriesOf(raw),
      imageUrl: pictureOf(raw),
    });
  }
  return items;
}

export { parseFeed };
