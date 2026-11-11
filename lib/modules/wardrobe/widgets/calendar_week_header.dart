// The month title and the week strip on the wardrobe calendar.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/wardrobe/controllers/wardrobe_calendar_controller.dart';
import 'package:banigoba/modules/wardrobe/models/calendar_dates.dart';

const Color calendarPrimary = Color(0xFF0D0140);

class CalendarWeekHeader extends StatelessWidget {
  const CalendarWeekHeader({super.key, required this.controller});

  final WardrobeCalendarController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final today = dateOnly(DateTime.now());

    return Obx(() {
      final selected = controller.selectedDate.value;
      final week = controller.selectedWeek;
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        color: colors.surfaceContainerLow,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${calendarMonths[selected.month - 1]} ${selected.year}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                TextButton.icon(
                  onPressed: controller.openFullCalendar,
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Full calendar'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (var index = 0; index < week.length; index++) ...[
                  if (index > 0) const SizedBox(width: 6),
                  Expanded(
                    child: _DayCell(
                      date: week[index],
                      weekday: calendarWeekdays[index],
                      selected: week[index] == selected,
                      isToday: week[index] == today,
                      isEventDay: controller.isEventDay(week[index]),
                      hasOutfit: controller.history.containsKey(
                        dateKey(week[index]),
                      ),
                      onTap:
                          controller.eventId != null &&
                              !controller.isEventDay(week[index])
                          ? null
                          : () => controller.selectDate(week[index]),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.weekday,
    required this.selected,
    required this.isToday,
    required this.isEventDay,
    required this.hasOutfit,
    required this.onTap,
  });

  final DateTime date;
  final String weekday;
  final bool selected;
  final bool isToday;
  final bool isEventDay;
  final bool hasOutfit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? (isEventDay ? Colors.pink.shade600 : calendarPrimary)
              : isEventDay
              ? Colors.pink.shade50
              : colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEventDay && !selected
                ? Colors.pink.shade400
                : isToday && !selected
                ? Colors.orange
                : selected
                ? (isEventDay ? Colors.pink.shade600 : calendarPrimary)
                : colors.outlineVariant,
            width: isToday || isEventDay ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              weekday,
              style: TextStyle(
                color: selected ? Colors.white70 : colors.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day}',
              style: TextStyle(
                color: selected ? Colors.white : colors.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: hasOutfit
                    ? (selected ? Colors.orangeAccent : calendarPrimary)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
