// The style directions and trends offered in the Makeover flow.
//
// Both lists are curated by hand for now (decision, September 2026):
//
//  * Archetypes are the "pick a vibe" choices under Style idol, for people
//    with no particular idol in mind. The app does not list real public
//    figures until it is decided which may be named (likeness and
//    endorsement questions); users may type an idol's name themselves.
//  * Trends are curated until there are enough public posts to compute them.
//
// Keep entries short: the name and tagline are shown on small cards.
import 'package:banigoba/modules/provider/models/look_request.dart';

// UNCLEAR: which real fashion idols (e.g. Winky D was mentioned in the
// meeting) can be listed, and whether they must have joined the platform
// first. Until then Style idol offers a free-text name plus these vibes.
const List<StyleArchetype> styleArchetypes = [
  StyleArchetype(
    id: 'afro_chic',
    name: 'Afro-Chic',
    tagline: 'African prints, modern cuts',
    promptHint:
        'modern African-print pieces with clean contemporary tailoring and '
        'bold, confident colour',
  ),
  StyleArchetype(
    id: 'street',
    name: 'Street',
    tagline: 'Relaxed, urban, sneakers',
    promptHint:
        'relaxed urban streetwear: oversized fits, layered basics and '
        'statement sneakers',
  ),
  StyleArchetype(
    id: 'traditional',
    name: 'Traditional',
    tagline: 'Heritage for occasions',
    promptHint:
        'elegant traditional southern African occasion wear, respectful and '
        'celebratory',
  ),
  StyleArchetype(
    id: 'smart',
    name: 'Smart',
    tagline: 'Polished for work',
    promptHint:
        'polished smart workwear: tailored trousers or skirt, crisp shirt or '
        'blouse, neat structured lines',
  ),
  StyleArchetype(
    id: 'elegant',
    name: 'Elegant',
    tagline: 'Evening and events',
    promptHint:
        'refined evening elegance: flowing fabrics, rich colours and minimal '
        'accessories',
  ),
  StyleArchetype(
    id: 'minimal',
    name: 'Minimal',
    tagline: 'Neutral and clean',
    promptHint:
        'minimalist style in neutral tones with simple, well-fitted pieces',
  ),
];

// UNCLEAR: curated placeholders. Replace with the stakeholder's list, and
// later compute "what's trending" from recent public posts in the user's
// community or area once there is enough activity to be meaningful.
const List<StyleTrend> curatedTrends = [
  StyleTrend(
    id: 'earth_tones',
    name: 'Earth tones',
    tagline: 'Rust, olive, sand',
    promptHint: 'an outfit in warm earth tones such as rust, olive and sand',
  ),
  StyleTrend(
    id: 'wide_leg',
    name: 'Wide-leg',
    tagline: 'Flowing trousers',
    promptHint: 'high-waisted wide-leg trousers with a fitted top',
  ),
  StyleTrend(
    id: 'print_accent',
    name: 'Print accents',
    tagline: 'One bold print piece',
    promptHint:
        'a single bold African-print piece balanced with plain neutral items',
  ),
  StyleTrend(
    id: 'braids',
    name: 'Braided styles',
    tagline: 'Knotless and updos',
    promptHint: 'neat knotless braids styled in a modern updo',
    isHair: true,
  ),
  StyleTrend(
    id: 'monochrome',
    name: 'Monochrome',
    tagline: 'One colour, head to toe',
    promptHint: 'a head-to-toe monochrome outfit in a single rich colour',
  ),
  StyleTrend(
    id: 'low_cut',
    name: 'Low cut',
    tagline: 'Clean, sharp fade',
    promptHint: 'a clean low haircut with a sharp fade',
    isHair: true,
  ),
];
