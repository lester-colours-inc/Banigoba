// One day cell in the full-calendar dialog.
import 'package:flutter/material.dart';

class CalendarDialogDay extends StatelessWidget {
  const CalendarDialogDay({
    required this.date,
    required this.disabled,
    required this.selected,
    required this.isToday,
    required this.hasOutfit,
    required this.primaryColor,
    required this.onTap,
  });

  final DateTime date;
  final bool disabled;
  final bool selected;
  final bool isToday;
  final bool hasOutfit;
  final Color primaryColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textColor = disabled
        ? colors.onSurface.withValues(alpha: 0.32)
        : selected
        ? Colors.white
        : colors.onSurface;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? primaryColor
                : isToday && !disabled
                ? Colors.orange
                : colors.outlineVariant,
            width: isToday || selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: hasOutfit && !disabled
                    ? (selected ? Colors.orangeAccent : primaryColor)
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
