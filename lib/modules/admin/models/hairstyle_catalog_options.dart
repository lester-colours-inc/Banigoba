// The choices a curator picks from when uploading a catalogue hairstyle.
import 'package:flutter/painting.dart';

const hairNavy = Color(0xFF17008A);

const hairOrange = Color(0xFFFFB51B);

const hairCatalogLengths = [
  'Bald',
  'Very Short',
  'Short',
  'Medium',
  'Long',
  'Extra Long',
  'Other',
];

const hairCatalogGenders = [
  "Women's Hairstyles",
  "Men's Hairstyles",
  'Unisex Hairstyles',
  'Other',
];

const hairCatalogTypes = [
  'Afro',
  'Braids',
  'Curly',
  'Locs',
  'Straight',
  'Wavy',

  'Other',
];

const hairstylePreferenceOptions = [
  'Casual',
  'Corporate',
  'Formal',
  'Glamour',
  'Afro-Chic',
  'Edgy',
  'Sporty',
  'Bohemian',
];

const hairCatalogStyleTypes = [...hairstylePreferenceOptions, 'Other'];

const hairCatalogCutTypes = {
  "Women's": [
    'Bob',
    'Lob',
    'Pixie Cut',
    'Layered Cut',
    'Blunt Cut',
    'Shag Cut',
    'Wolf Cut',
    'Butterfly Cut',
    'Curtain Layers',
    'Other',
  ],
  "Men's": [
    'Buzz Cut',
    'Crew Cut',
    'Fade',
    'Taper Fade',
    'Skin Fade',
    'Undercut',
    'Pompadour',
    'Quiff',
    'Comb Over',
    'French Crop',
    'Caesar Cut',
    'Mullet',
    'Other',
  ],
  'Afro & Protective Styles': [
    'Box Braids',
    'Knotless Braids',
    'Cornrows',
    'Fulani Braids',
    'Ghana Braids',
    'Twists',
    'Senegalese Twists',
    'Passion Twists',
    'Faux Locs',
    'Dreadlocks',
    'Bantu Knots',
    'Afro',
    'High Puff',
    'Finger Coils',
    'Other',
  ],
  'Updos': [
    'Bun',
    'High Bun',
    'Low Bun',
    'Chignon',
    'Ponytail',
    'High Ponytail',
    'Braided Updo',
    'Half Up Half Down',
    'Other',
  ],
  'Other': ['Other'],
};

const hairCatalogOccasions = [
  'Everyday',
  'Work',
  'Wedding',
  'Party',
  'Prom',
  'Festival',
  'Vacation',
  'Photoshoot',
  'Other',
];

const hairCatalogColours = [
  'Black',
  'Brown',
  'Blonde',
  'Red',
  'Auburn',
  'Grey',
  'Platinum',
  'Ombre',
  'Balayage',
  'Highlights',
  'Fantasy Colours',
  'Other',
];

const hairCatalogMaintenanceLevels = [
  'Low Maintenance',
  'Medium Maintenance',
  'High Maintenance',
  'Other',
];

List<String> stringListFromDynamic(Object? value) {
  if (value is Iterable) {
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? const [] : [text];
}
