// The "How?" step of the Makeover flow, as a clear either-or (October 2026
// review, M-4): describe the look in your own words, OR use a look you love
// (a style twin, a style idol, a trend, or today's weather), then the input
// for whichever is selected.
import 'package:flutter/material.dart';

import 'package:banigoba/modules/provider/models/look_request.dart';
import 'package:banigoba/modules/home/models/weather.dart';
import 'package:banigoba/modules/makeover/widgets/makeover_controls.dart';
import 'package:banigoba/shared/widgets/app_network_image.dart';

/// The idea sources, in display order.
enum LookMethod {
  describe('Describe', Icons.edit_note),
  idol('Style idol', Icons.star_outline),
  twin('Style twin', Icons.people_alt_outlined),
  weather('Weather', Icons.wb_sunny_outlined),
  trending('Trending', Icons.trending_up);

  const LookMethod(this.label, this.icon);

  final String label;
  final IconData icon;

  /// Describe is option A; every other source is "a look you love".
  bool get isDescribe => this == describe;

  /// Option B's sources, in display order.
  static const List<LookMethod> lookYouLove = [twin, idol, trending, weather];
}

/// Weather lookup state, owned by the page (it needs location access).
@immutable
class WeatherState {
  const WeatherState({this.weather, this.isLoading = false, this.error = ''});

  final Weather? weather;
  final bool isLoading;
  final String error;
}

/// The Style twin reference and how to choose one; owned by the page.
@immutable
class TwinState {
  const TwinState({
    this.imageUrl = '',
    this.isUploading = false,
    required this.onPickFromCommunity,
    required this.onPickFromPhotos,
  });

  final String imageUrl;
  final bool isUploading;
  final VoidCallback onPickFromCommunity;
  final VoidCallback onPickFromPhotos;
}

class LookSourcePicker extends StatelessWidget {
  const LookSourcePicker({
    super.key,
    required this.method,
    required this.onMethodChanged,
    required this.scope,
    required this.describeController,
    required this.idolController,
    required this.archetypes,
    required this.selectedArchetype,
    required this.onArchetypeChanged,
    required this.twin,
    required this.trends,
    required this.selectedTrend,
    required this.onTrendChanged,
    required this.weather,
    required this.onRetryWeather,
    this.enabled = true,
  });

  final LookMethod method;
  final ValueChanged<LookMethod> onMethodChanged;
  final LookScope scope;
  final TextEditingController describeController;
  final TextEditingController idolController;
  final List<StyleArchetype> archetypes;
  final StyleArchetype? selectedArchetype;

  /// Called with null when the selected archetype is tapped again.
  final ValueChanged<StyleArchetype?> onArchetypeChanged;
  final TwinState twin;
  final List<StyleTrend> trends;
  final StyleTrend? selectedTrend;
  final ValueChanged<StyleTrend> onTrendChanged;
  final WeatherState weather;
  final VoidCallback onRetryWeather;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _OptionCard(
                key: const ValueKey('look_option_describe'),
                icon: Icons.edit_note,
                title: 'Describe it',
                subtitle: 'Say what you want in your own words',
                isSelected: method.isDescribe,
                onTap: enabled
                    ? () => onMethodChanged(LookMethod.describe)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _OptionCard(
                key: const ValueKey('look_option_love'),
                icon: Icons.favorite_border,
                title: 'Use a look you love',
                subtitle: 'A style twin, idol, trend or the weather',
                isSelected: !method.isDescribe,
                onTap: enabled && method.isDescribe
                    ? () => onMethodChanged(LookMethod.lookYouLove.first)
                    : null,
              ),
            ),
          ],
        ),
        if (!method.isDescribe) ...[
          const SizedBox(height: 18),
          Row(
            children: [
              for (final option in LookMethod.lookYouLove)
                Expanded(
                  child: _MethodTile(
                    method: option,
                    isSelected: option == method,
                    onTap: enabled ? () => onMethodChanged(option) : null,
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: KeyedSubtree(
            key: ValueKey(method),
            child: switch (method) {
              LookMethod.describe => _DescribeInput(
                controller: describeController,
                scope: scope,
                enabled: enabled,
              ),
              LookMethod.idol => _IdolInput(
                controller: idolController,
                archetypes: archetypes,
                selected: selectedArchetype,
                onSelected: enabled ? onArchetypeChanged : null,
                enabled: enabled,
              ),
              LookMethod.twin => _TwinPanel(state: twin, enabled: enabled),
              LookMethod.weather => _WeatherPanel(
                state: weather,
                onRetry: onRetryWeather,
              ),
              LookMethod.trending => _OptionPills<StyleTrend>(
                title: 'Trending now',
                options: trends,
                selected: selectedTrend,
                nameOf: (trend) => trend.name,
                taglineOf: (trend) => trend.tagline,
                onSelected: enabled ? onTrendChanged : null,
                emptyMessage:
                    'No trends fit this choice yet. Try another '
                    'option above.',
              ),
            },
          ),
        ),
      ],
    );
  }
}

/// One side of the either-or: a large card with an icon, title and a line
/// saying what it does.
class _OptionCard extends StatelessWidget {
  const _OptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = isSelected ? Colors.white : colors.onSurface;
    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: isSelected ? kMakeoverNavy : colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: foreground),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.85)
                        : colors.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon in a circle over a short label. Four fit across a phone.
class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  final LookMethod method;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: isSelected,
      label: method.label,
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey('look_method_${method.name}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? kMakeoverNavy
                      : colors.surfaceContainerHigh,
                ),
                child: Icon(
                  method.icon,
                  color: isSelected ? Colors.white : colors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              // Two-line slot so "Style idol" can wrap on narrow phones
              // instead of being cut off, and every tile stays aligned.
              SizedBox(
                height: 32,
                child: Text(
                  method.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.2,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? colors.onSurface
                        : colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DescribeInput extends StatelessWidget {
  const _DescribeInput({
    required this.controller,
    required this.scope,
    required this.enabled,
  });

  final TextEditingController controller;
  final LookScope scope;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final example = scope.changesClothing
        ? 'e.g. A white linen shirt and wide-leg trousers'
        : 'e.g. I want a low haircut';
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: 1.2),
    );

    return TextField(
      key: const ValueKey('look_describe_field'),
      controller: controller,
      enabled: enabled,
      minLines: 3,
      maxLines: 4,
      maxLength: 200,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: 'Describe the look you want',
        hintStyle: TextStyle(color: colors.onSurfaceVariant, fontSize: 17),
        helperText: example,
        filled: true,
        fillColor: colors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
        enabledBorder: border(colors.outlineVariant),
        disabledBorder: border(colors.outlineVariant),
        focusedBorder: border(kMakeoverNavy),
      ),
    );
  }
}

/// A person the user admires, or a vibe when nobody comes to mind.
//
// UNCLEAR: whether a list of named public figures (e.g. Winky D) may be
// offered, or only idols who have joined the platform (work plan, open
// question 4). Until then the user types the name themselves; the look takes
// their clothes style only, never their likeness.
class _IdolInput extends StatelessWidget {
  const _IdolInput({
    required this.controller,
    required this.archetypes,
    required this.selected,
    required this.onSelected,
    required this.enabled,
  });

  final TextEditingController controller;
  final List<StyleArchetype> archetypes;
  final StyleArchetype? selected;
  final ValueChanged<StyleArchetype?>? onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('look_idol_field'),
          controller: controller,
          enabled: enabled,
          maxLength: 60,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Who is your style idol?',
            hintText: 'A musician, actor, influencer or friend',
            prefixIcon: Icon(Icons.star_outline),
          ),
        ),
        const SizedBox(height: 4),
        _OptionPills<StyleArchetype>(
          title: controller.text.trim().isEmpty
              ? 'No one in mind? Pick a vibe'
              : 'Add a vibe (optional)',
          options: archetypes,
          selected: selected,
          nameOf: (archetype) => archetype.name,
          taglineOf: (archetype) => archetype.tagline,
          onSelected: onSelected == null
              ? null
              : (archetype) =>
                    onSelected!(archetype == selected ? null : archetype),
        ),
      ],
    );
  }
}

/// A look the user wants to copy onto themselves.
class _TwinPanel extends StatelessWidget {
  const _TwinPanel({required this.state, required this.enabled});

  final TwinState state;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasLook = state.imageUrl.isNotEmpty;

    final Widget preview;
    if (state.isUploading) {
      preview = const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else if (hasLook) {
      preview = AppNetworkImage(
        state.imageUrl,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        fallback: Icon(Icons.broken_image_outlined, color: colors.outline),
      );
    } else {
      preview = Icon(Icons.people_alt_outlined, color: colors.outline);
    }

    final canPick = enabled && !state.isUploading;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            key: const ValueKey('look_twin_preview'),
            width: 84,
            height: 112,
            color: colors.surfaceContainerHigh,
            child: preview,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasLook ? 'Your style twin' : 'Seen a look you love?',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hasLook
                    ? "We'll copy this look onto you, one item at a time."
                    : 'Copy it onto yourself: find one from people you '
                          'follow, your saved looks, or your photos.',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  MakeoverPill(
                    key: const ValueKey('look_twin_community'),
                    icon: Icons.favorite_border,
                    label: 'Find a look',
                    selected: false,
                    onTap: canPick ? state.onPickFromCommunity : null,
                  ),
                  MakeoverPill(
                    key: const ValueKey('look_twin_photos'),
                    icon: Icons.photo_library_outlined,
                    label: 'My photos',
                    selected: false,
                    onTap: canPick ? state.onPickFromPhotos : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A wrap of selectable pills, with the selected option's tagline beneath.
class _OptionPills<T> extends StatelessWidget {
  const _OptionPills({
    required this.title,
    required this.options,
    required this.selected,
    required this.nameOf,
    required this.taglineOf,
    required this.onSelected,
    this.emptyMessage = '',
  });

  final String title;
  final List<T> options;
  final T? selected;
  final String Function(T) nameOf;
  final String Function(T) taglineOf;
  final ValueChanged<T>? onSelected;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (options.isEmpty) {
      return Text(
        emptyMessage,
        style: TextStyle(color: colors.onSurfaceVariant),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              MakeoverPill(
                key: ValueKey('look_option_${nameOf(option)}'),
                label: nameOf(option),
                selected: option == selected,
                onTap: onSelected == null ? null : () => onSelected!(option),
              ),
          ],
        ),
        if (selected case final value?) ...[
          const SizedBox(height: 10),
          Text(
            taglineOf(value),
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ],
    );
  }
}

class _WeatherPanel extends StatelessWidget {
  const _WeatherPanel({required this.state, required this.onRetry});

  final WeatherState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final Widget content;
    if (state.isLoading) {
      content = const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Expanded(child: Text('Checking the weather where you are...')),
        ],
      );
    } else if (state.weather case final weather?) {
      content = Row(
        children: [
          const Icon(Icons.wb_sunny_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${weather.temperatureC.round()}°C · ${weather.condition}'
              '${weather.locationName.isEmpty ? '' : ' · ${weather.locationName}'}'
              '\nWe will style a look for this weather.',
            ),
          ),
        ],
      );
    } else {
      content = Row(
        children: [
          const Icon(Icons.cloud_off_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              state.error.isEmpty
                  ? 'Weather is not available right now.'
                  : state.error,
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: content,
    );
  }
}
