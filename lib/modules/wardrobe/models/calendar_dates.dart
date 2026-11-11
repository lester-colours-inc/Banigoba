// Date helpers shared by the wardrobe calendar and its dialog.
const calendarWeekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
const calendarMonths = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// `yyyy-MM-dd`, the key wear-history documents are stored under.
String dateKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

String formatCalendarDate(DateTime value) =>
    '${calendarMonths[value.month - 1]} ${value.day}, ${value.year}';
