// The "How?" step of the Makeover flow: four ways to get an idea for a look,
// and the input for whichever is selected.
//
// Describe · Style icon · Weather · Trending, per the September 2026 meeting.
import 'package:flutter/material.dart';

import '../../../../data/models/look_request.dart';
import '../../../../data/models/weather.dart';

/// The four idea sources, in display order.
enum LookMethod {
  describe('Describe it', Icons.edit_note),
  styleIcon('Style icon', Icons.star_outline),
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

class LookSourcePicker extends StatelessWidget {
  const LookSourcePicker({
    super.key,
    required this.method,
    required this.onMethodChanged,
    required this.scope,
    required this.describeController,
    required this.archetypes,
    required this.selectedArchetype,
    required this.onArchetypeChanged,
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
  final List<StyleArchetype> archetypes;
  final StyleArchetype? selectedArchetype;
  final ValueChanged<StyleArchetype> onArchetypeChanged;
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
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.6,
          children: [
            for (final option in LookMethod.values)
              _MethodCard(
                method: option,
                isSelected: option == method,
                onTap: enabled ? () => onMethodChanged(option) : null,
              ),
          ],
        ),
        const SizedBox(height: 16),
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
              LookMethod.styleIcon => _OptionList<StyleArchetype>(
                title: 'Pick a style to try',
                options: archetypes,
                selected: selectedArchetype,
                nameOf: (archetype) => archetype.name,
                taglineOf: (archetype) => archetype.tagline,
                onSelected: enabled ? onArchetypeChanged : null,
              ),
              LookMethod.weather => _WeatherPanel(
                state: weather,
                onRetry: onRetryWeather,
              ),
              LookMethod.trending => _OptionList<StyleTrend>(
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

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  final LookMethod method;
  final bool isSelected;
  final VoidCallback? onTap;

  static const Color _navy = Color(0xFF0D0140);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: isSelected ? _navy : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          key: ValueKey('look_method_${method.name}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  method.icon,
                  color: isSelected ? Colors.white : colors.onSurface,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    method.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : colors.onSurface,
                    ),
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
        border: const OutlineInputBorder(),
      ),
    );
  }
}

/// A vertical list of selectable name + tagline tiles.
class _OptionList<T> extends StatelessWidget {
  const _OptionList({
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
    final theme = Theme.of(context);

    if (options.isEmpty) {
      return Text(
        emptyMessage,
        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              ChoiceChip(
                key: ValueKey('look_option_${nameOf(option)}'),
                label: Text(nameOf(option)),
                tooltip: taglineOf(option),
                selected: option == selected,
                onSelected: onSelected == null
                    ? null
                    : (_) => onSelected!(option),
              ),
          ],
        ),
        if (selected case final value?) ...[
          const SizedBox(height: 8),
          Text(
            taglineOf(value),
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: content,
    );
  }
}
