// The "How?" step of the Makeover flow: five ways to get an idea for a look,
// and the input for whichever is selected.
//
// Describe · Style idol · Style twin · Weather · Trending, per the September
// 2026 meeting and follow-up.
import 'package:flutter/material.dart';

import '../../../../data/models/look_request.dart';
import '../../../../data/models/weather.dart';
import 'makeover_controls.dart';
import '../../../widgets/app_network_image.dart';

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
          children: [
            for (final option in LookMethod.values)
              Expanded(
                child: _MethodTile(
                  method: option,
                  isSelected: option == method,
                  onTap: enabled ? () => onMethodChanged(option) : null,
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
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

/// Icon in a circle over a short label. Five fit across a phone.
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
                width: 50,
                height: 50,
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
              const SizedBox(height: 6),
              Text(
                method.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected
                      ? colors.onSurface
                      : colors.onSurfaceVariant,
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
    final hint = scope.changesClothing
        ? 'e.g. A white linen shirt and wide-leg trousers'
        : 'e.g. I want a low haircut';

    return TextField(
      key: const ValueKey('look_describe_field'),
      controller: controller,
      enabled: enabled,
      minLines: 2,
      maxLines: 4,
      maxLength: 200,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: 'Describe the look you want',
        hintText: hint,
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
                    : 'Copy it onto yourself: pick one from the community or '
                          'your photos.',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  MakeoverPill(
                    key: const ValueKey('look_twin_community'),
                    icon: Icons.explore_outlined,
                    label: 'Community',
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
          Text('Checking the weather where you are...'),
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
