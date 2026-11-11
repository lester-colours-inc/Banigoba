// The name, photo and style of whoever made a feed post.
class PostAuthor {
  const PostAuthor({
    required this.displayName,
    required this.fullBodyImageUrl,
    required this.stylePreference,
    this.profileImageUrl = '',
  });

  final String displayName;
  final String fullBodyImageUrl;
  final String profileImageUrl;
  final String stylePreference;

  factory PostAuthor.fallback(String authorId) {
    final suffix = authorId.length >= 4
        ? authorId.substring(0, 4).toUpperCase()
        : authorId.toUpperCase();
    return PostAuthor(
      displayName: suffix.isEmpty ? 'User' : 'User $suffix',
      fullBodyImageUrl: '',
      stylePreference: '',
    );
  }
}

/// "Today", "Yesterday", "3 Days Ago" or a date.
String formatPostTime(DateTime createdAt, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final difference = current.difference(createdAt);
  if (difference.isNegative) return 'Today';

  final today = DateTime(current.year, current.month, current.day);
  final postDay = DateTime(createdAt.year, createdAt.month, createdAt.day);
  final dayGap = today.difference(postDay).inDays;
  if (dayGap == 0) return 'Today';
  if (dayGap == 1) return 'Yesterday';
  if (dayGap < 7) return '$dayGap Days Ago';
  return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
}

/// "casual_chic" -> "Casual Chic".
String titleCase(String value) {
  final words = value
      .trim()
      .split(RegExp(r'[\s_-]+'))
      .where((word) => word.isNotEmpty);
  return words
      .map(
        (word) =>
            '${word.substring(0, 1).toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .join(' ');
}
