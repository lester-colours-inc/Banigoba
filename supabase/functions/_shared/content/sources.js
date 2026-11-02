// The feeds the fashion-content engine reads (review items E-2, E-3, F-2).
//
// Only the publishers' own RSS/Atom feeds, which they offer for syndication:
// no page scraping. Every feed below answered with real stories when checked
// on 28 Oct 2026. `requireFashion` is for general news feeds, where only the
// fashion stories are kept. To add a source, add a line and run the tests.

const SOURCES = [
  { id: 'vogue', name: 'Vogue', url: 'https://www.vogue.com/feed/rss', region: 'intl' },
  { id: 'fashionista', name: 'Fashionista', url: 'https://fashionista.com/.rss/full/', region: 'intl' },
  { id: 'elle', name: 'ELLE', url: 'https://www.elle.com/rss/all.xml/', region: 'intl', requireFashion: true },
  {
    id: 'harpers-bazaar',
    name: "Harper's Bazaar",
    url: 'https://www.harpersbazaar.com/rss/all.xml/',
    region: 'intl',
    requireFashion: true,
  },
  { id: 'guardian-fashion', name: 'The Guardian', url: 'https://www.theguardian.com/fashion/rss', region: 'intl' },
  { id: 'fashion-week-online', name: 'Fashion Week Online', url: 'https://fashionweekonline.com/feed', region: 'intl' },
  { id: 'bellanaija', name: 'BellaNaija', url: 'https://www.bellanaija.com/feed/', region: 'ng', requireFashion: true },
  { id: 'herald-zw', name: 'The Herald', url: 'https://www.herald.co.zw/feed/', region: 'zw', requireFashion: true },
  { id: 'newzimbabwe', name: 'NewZimbabwe', url: 'https://www.newzimbabwe.com/feed/', region: 'zw', requireFashion: true },
  {
    id: 'zimbabwe-mail',
    name: 'The Zimbabwe Mail',
    url: 'https://www.thezimbabwemail.com/feed/',
    region: 'zw',
    requireFashion: true,
  },
  { id: 'zbc', name: 'ZBC News', url: 'https://www.zbcnews.co.zw/feed/', region: 'zw', requireFashion: true },
  { id: '263chat', name: '263Chat', url: 'https://www.263chat.com/feed/', region: 'zw', requireFashion: true },
  {
    id: 'zimbabwe-independent',
    name: 'The Zimbabwe Independent',
    url: 'https://www.theindependent.co.zw/feed/',
    region: 'zw',
    requireFashion: true,
  },
  {
    id: 'zimbabwe-situation',
    name: 'Zimbabwe Situation',
    url: 'https://www.zimbabwesituation.com/feed/',
    region: 'zw',
    requireFashion: true,
  },
];

export { SOURCES };
