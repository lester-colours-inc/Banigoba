// A month-at-a-time calendar dialog for jumping to any day.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/wardrobe/models/calendar_dates.dart';
import 'package:banigoba/modules/wardrobe/widgets/calendar_dialog_day.dart';

const Color _primaryColor = Color(0xFF0D0140);

/// Null when cancelled.
Future<DateTime?> pickCalendarDate({
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  required Set<String> historyKeys,
}) {
  return Get.dialog<DateTime>(
    FullCalendarDialog(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      historyKeys: historyKeys,
    ),
  );
}

class _VisibleMonthController extends GetxController {
  _VisibleMonthController(DateTime initial)
    : month = DateTime(initial.year, initial.month).obs;

  final Rx<DateTime> month;

  void change(int delta) =>
      month.value = DateTime(month.value.year, month.value.month + delta);
}

class FullCalendarDialog extends StatelessWidget {
  const FullCalendarDialog({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.historyKeys,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final Set<String> historyKeys;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<_VisibleMonthController>(
      init: _VisibleMonthController(initialDate),
      global: false,
      builder: (state) => Obx(() => _dialog(context, state)),
    );
  }

  Widget _dialog(BuildContext context, _VisibleMonthController state) {
    final colors = Theme.of(context).colorScheme;
    final visible = state.month.value;
    final firstOfMonth = DateTime(visible.year, visible.month);
    final leadingEmptyDays = firstOfMonth.weekday % 7;
    final daysInMonth = DateTime(visible.year, visible.month + 1, 0).day;
    final today = dateOnly(DateTime.now());
    final previous = DateTime(visible.year, visible.month - 1);
    final canGoPrevious = !DateTime(
      previous.year,
      previous.month + 1,
      0,
    ).isBefore(firstDate);
    final canGoNext = !DateTime(
      visible.year,
      visible.month + 1,
    ).isAfter(lastDate);

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(18, 14, 10, 0),
      contentPadding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
      actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      title: Row(
        children: [
          Expanded(
            child: Text(
              '${calendarMonths[visible.month - 1]} ${visible.year}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            tooltip: 'Previous month',
            onPressed: canGoPrevious ? () => state.change(-1) : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          IconButton(
            tooltip: 'Next month',
            onPressed: canGoNext ? () => state.change(1) : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                for (final weekday in calendarWeekdays)
                  Expanded(
                    child: Center(
                      child: Text(
                        weekday,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 42,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
              ),
              itemBuilder: (context, index) {
                final day = index - leadingEmptyDays + 1;
                if (day < 1 || day > daysInMonth) {
                  return const SizedBox.shrink();
                }
                final normalized = dateOnly(
                  DateTime(visible.year, visible.month, day),
                );
                final disabled =
                    normalized.isBefore(firstDate) ||
                    normalized.isAfter(lastDate);
                return CalendarDialogDay(
                  date: normalized,
                  disabled: disabled,
                  selected: normalized == dateOnly(initialDate),
                  isToday: normalized == today,
                  hasOutfit: historyKeys.contains(dateKey(normalized)),
                  primaryColor: _primaryColor,
                  onTap: disabled
                      ? null
                      : () => Get.back<DateTime>(result: normalized),
                );
              },
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: Get.back, child: const Text('Cancel'))],
    );
  }
}
