// Lets users repeat saved outfits and schedule them against calendar dates.
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../data/services/outfit_service.dart';
import '../../widgets/safe_product_image.dart';
import '../makeover/ai_upload_page.dart';

class WardrobeCalendarPage extends StatefulWidget {
  const WardrobeCalendarPage({
    super.key,
    this.planningMode = false,
    this.eventId,
    this.eventName,
    this.eventStart,
    this.eventEnd,
  });

  final bool planningMode;
  final String? eventId;
  final String? eventName;
  final DateTime? eventStart;
  final DateTime? eventEnd;

  @override
  State<WardrobeCalendarPage> createState() => _WardrobeCalendarPageState();
}

class _WardrobeCalendarPageState extends State<WardrobeCalendarPage> {
  static const Color _primaryColor = Color(0xFF0D0140);
  static const _weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const _months = [
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

  final OutfitService _outfitService = OutfitService();
  late DateTime _selectedDate;
  String? _savingOutfitId;

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOnly(widget.eventStart ?? DateTime.now());
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _dateKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  List<DateTime> get _selectedWeek {
    final sunday = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday % 7),
    );
    return List.generate(7, (index) => sunday.add(Duration(days: index)));
  }

  Future<void> _openFullCalendar(
    Map<String, Map<String, dynamic>> history,
  ) async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => _FullCalendarDialog(
        initialDate: _selectedDate,
        firstDate: _dateOnly(widget.eventStart ?? DateTime(2020)),
        lastDate: _dateOnly(
          widget.eventEnd ?? DateTime(DateTime.now().year + 5, 12, 31),
        ),
        historyKeys: history.keys.toSet(),
        dateKey: _dateKey,
        dateOnly: _dateOnly,
        months: _months,
        weekdays: _weekdays,
        primaryColor: _primaryColor,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedDate = _dateOnly(picked));
  }

  Future<void> _openFullCalendarForUser(String userId) async {
    try {
      final snapshot = await _outfitService.watchWearHistory(userId).first;
      final history = <String, Map<String, dynamic>>{
        for (final doc in snapshot.docs) doc.id: doc.data(),
      };
      if (!mounted) return;
      await _openFullCalendar(history);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open calendar: $error')),
      );
    }
  }

  Future<void> _reuseOutfit(_SavedOutfit outfit) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please sign in first.')));
      return;
    }

    setState(() => _savingOutfitId = outfit.id);
    try {
      await _outfitService.reuseOutfitOnDate(
        userId: user.uid,
        outfitId: outfit.id,
        date: _selectedDate,
        outfit: outfit.data,
        eventId: widget.eventId,
        eventName: widget.eventName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${outfit.name} added to ${_formatSelectedDate(_selectedDate)}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to reuse this outfit: $error')),
      );
    } finally {
      if (mounted) setState(() => _savingOutfitId = null);
    }
  }

  Future<void> _createOutfitForSelectedDate() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiUploadPage(
          plannedDate: _selectedDate,
          eventId: widget.eventId,
          eventName: widget.eventName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.chevron_left_rounded, color: colors.onSurface),
        ),
        title: Text(
          widget.eventName ??
              (widget.planningMode ? 'Week Planner' : 'Quick Wear'),
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Open full calendar',
            onPressed: user == null
                ? null
                : () => _openFullCalendarForUser(user.uid),
            icon: Icon(Icons.calendar_month, color: _primaryColor),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Sign in to view your worn outfits.'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _outfitService.watchWearHistory(user.uid),
              builder: (context, historySnapshot) {
                final history = <String, Map<String, dynamic>>{
                  for (final doc in historySnapshot.data?.docs ?? const [])
                    doc.id: doc.data(),
                };

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildCalendarHeader(context, history),
                    ),
                    SliverToBoxAdapter(
                      child: _buildSelectedDateSummary(context, history),
                    ),
                    if (widget.planningMode)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: FilledButton.icon(
                            onPressed: _createOutfitForSelectedDate,
                            style: FilledButton.styleFrom(
                              backgroundColor: _primaryColor,
                              minimumSize: const Size(double.infinity, 52),
                            ),
                            icon: const Icon(Icons.add_a_photo_outlined),
                            label: Text(
                              'Create outfit for ${_formatSelectedDate(_selectedDate)}',
                            ),
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                      sliver: _buildSavedOutfits(user.uid),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildCalendarHeader(
    BuildContext context,
    Map<String, Map<String, dynamic>> history,
  ) {
    final colors = Theme.of(context).colorScheme;
    final today = _dateOnly(DateTime.now());

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      color: colors.surfaceContainerLow,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_months[_selectedDate.month - 1]} ${_selectedDate.year}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              TextButton.icon(
                onPressed: () => _openFullCalendar(history),
                icon: const Icon(Icons.calendar_month),
                label: const Text('Full calendar'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var index = 0; index < _selectedWeek.length; index++) ...[
                if (index > 0) const SizedBox(width: 6),
                Expanded(
                  child: _buildDay(
                    _selectedWeek[index],
                    _weekdays[index],
                    isToday: _selectedWeek[index] == today,
                    isEventDay: _isEventDay(_selectedWeek[index]),
                    hasOutfit: history.containsKey(
                      _dateKey(_selectedWeek[index]),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDay(
    DateTime date,
    String weekday, {
    required bool isToday,
    required bool isEventDay,
    required bool hasOutfit,
  }) {
    final selected = date == _selectedDate;
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: widget.eventId != null && !isEventDay
          ? null
          : () => setState(() => _selectedDate = date),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? (isEventDay ? Colors.pink.shade600 : _primaryColor)
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
                ? (isEventDay ? Colors.pink.shade600 : _primaryColor)
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
                    ? (selected ? Colors.orangeAccent : _primaryColor)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDateSummary(
    BuildContext context,
    Map<String, Map<String, dynamic>> history,
  ) {
    final colors = Theme.of(context).colorScheme;
    final worn = history[_dateKey(_selectedDate)];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: worn == null
              ? colors.surfaceContainerLow
              : colors.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: worn == null
                  ? Icon(Icons.checkroom_outlined, color: colors.outline)
                  : _OutfitPlannerVisual(data: worn, compact: true),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatSelectedDate(_selectedDate),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    worn == null
                        ? widget.planningMode
                              ? 'Create a new outfit or reuse one below.'
                              : 'Choose a previously worn outfit below.'
                        : 'Wearing ${(worn['outfitName'] ?? 'Completed Look')}',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedOutfits(String userId) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _outfitService.watchSavedOutfits(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: _message('Previously worn outfits could not be loaded.'),
          );
        }
        if (!snapshot.hasData) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final outfits =
            snapshot.data!.docs
                .map((doc) => _SavedOutfit(doc.id, doc.data()))
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (outfits.isEmpty) {
          return SliverToBoxAdapter(
            child: _message(
              'No previous outfits yet. Save a look from Avatar Try-On first.',
            ),
          );
        }

        return SliverMainAxisGroup(
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: 14),
                child: Text(
                  'Previously Worn',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.68,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildOutfitCard(outfits[index]),
                childCount: outfits.length,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOutfitCard(_SavedOutfit outfit) {
    final colors = Theme.of(context).colorScheme;
    final isSaving = _savingOutfitId == outfit.id;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: colors.surface,
              child: _OutfitPlannerVisual(data: outfit.data),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Text(
              outfit.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
            child: FilledButton(
              onPressed: _savingOutfitId == null
                  ? () => _reuseOutfit(outfit)
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: _primaryColor,
                minimumSize: const Size(double.infinity, 40),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Wear Again'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _message(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(Icons.checkroom_outlined, size: 52),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  String _formatSelectedDate(DateTime value) =>
      '${_months[value.month - 1]} ${value.day}, ${value.year}';

  bool _isEventDay(DateTime value) {
    final start = widget.eventStart;
    final end = widget.eventEnd;
    if (start == null || end == null) return false;
    final date = _dateOnly(value);
    return !date.isBefore(_dateOnly(start)) && !date.isAfter(_dateOnly(end));
  }
}

class _FullCalendarDialog extends StatefulWidget {
  const _FullCalendarDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.historyKeys,
    required this.dateKey,
    required this.dateOnly,
    required this.months,
    required this.weekdays,
    required this.primaryColor,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final Set<String> historyKeys;
  final String Function(DateTime value) dateKey;
  final DateTime Function(DateTime value) dateOnly;
  final List<String> months;
  final List<String> weekdays;
  final Color primaryColor;

  @override
  State<_FullCalendarDialog> createState() => _FullCalendarDialogState();
}

class _FullCalendarDialogState extends State<_FullCalendarDialog> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    _visibleMonth = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
    );
  }

  bool get _canGoPrevious {
    final previous = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    final previousLastDay = DateTime(previous.year, previous.month + 1, 0);
    return !previousLastDay.isBefore(widget.firstDate);
  }

  bool get _canGoNext {
    final next = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    return !next.isAfter(widget.lastDate);
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + delta,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month);
    final leadingEmptyDays = firstOfMonth.weekday % 7;
    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;
    final today = widget.dateOnly(DateTime.now());

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(18, 14, 10, 0),
      contentPadding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
      actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      title: Row(
        children: [
          Expanded(
            child: Text(
              '${widget.months[_visibleMonth.month - 1]} ${_visibleMonth.year}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            tooltip: 'Previous month',
            onPressed: _canGoPrevious ? () => _changeMonth(-1) : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          IconButton(
            tooltip: 'Next month',
            onPressed: _canGoNext ? () => _changeMonth(1) : null,
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
                for (final weekday in widget.weekdays)
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
                final normalized = widget.dateOnly(
                  DateTime(_visibleMonth.year, _visibleMonth.month, day),
                );
                final disabled =
                    normalized.isBefore(widget.firstDate) ||
                    normalized.isAfter(widget.lastDate);
                final selected =
                    normalized == widget.dateOnly(widget.initialDate);
                final isToday = normalized == today;
                final hasOutfit = widget.historyKeys.contains(
                  widget.dateKey(normalized),
                );
                return _CalendarDialogDay(
                  date: normalized,
                  disabled: disabled,
                  selected: selected,
                  isToday: isToday,
                  hasOutfit: hasOutfit,
                  primaryColor: widget.primaryColor,
                  onTap: disabled
                      ? null
                      : () => Navigator.of(context).pop(normalized),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _CalendarDialogDay extends StatelessWidget {
  const _CalendarDialogDay({
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

class _OutfitPlannerVisual extends StatelessWidget {
  const _OutfitPlannerVisual({required this.data, this.compact = false});

  final Map<String, dynamic> data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final imageUrl = _outfitImageUrl(data);
    final products = _products(data);
    if (products.isEmpty) {
      return _mainImage(colors, imageUrl);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bottomCount = _bottomCount(products.length);
        final tileSize = _tileSize(
          itemCount: products.length,
          bottomCount: bottomCount,
          width: constraints.maxWidth,
          height: constraints.maxHeight,
        );
        final gap = compact ? 3.0 : 6.0;
        final bottomProducts = products.take(bottomCount).toList();
        final sideProducts = products.skip(bottomCount).toList();
        final bottomGap = _evenGap(
          extent: constraints.maxWidth,
          itemCount: bottomProducts.length,
          tileSize: tileSize,
          fallback: gap,
        );
        final sideAvailableHeight = constraints.maxHeight - tileSize - gap;
        final sideGap = _evenGap(
          extent: sideAvailableHeight,
          itemCount: sideProducts.length,
          tileSize: tileSize,
          fallback: gap,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            _mainImage(colors, imageUrl),
            for (var index = 0; index < sideProducts.length; index++)
              Positioned(
                right: gap,
                top: sideGap + index * (tileSize + sideGap),
                width: tileSize,
                height: tileSize,
                child: _productTile(context, sideProducts[index], compact),
              ),
            for (var index = 0; index < bottomProducts.length; index++)
              Positioned(
                left: bottomGap + index * (tileSize + bottomGap),
                bottom: gap,
                width: tileSize,
                height: tileSize,
                child: _productTile(context, bottomProducts[index], compact),
              ),
          ],
        );
      },
    );
  }

  Widget _mainImage(ColorScheme colors, String imageUrl) {
    if (imageUrl.isEmpty) {
      return Icon(Icons.checkroom_outlined, size: 56, color: colors.outline);
    }
    return SafeProductImage(
      imageUrl: imageUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.contain,
      iconSize: compact ? 24 : 56,
    );
  }

  Widget _productTile(
    BuildContext context,
    Map<String, dynamic> product,
    bool compact,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(compact ? 2 : 5),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(compact ? 6 : 10),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 4 : 8),
        child: SafeProductImage(
          imageUrl: _productImageUrl(product),
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.contain,
          iconSize: compact ? 18 : 30,
        ),
      ),
    );
  }

  static String _outfitImageUrl(Map<String, dynamic> data) {
    final result = (data['imageUrl'] ?? '').toString().trim();
    if (result.isNotEmpty) return result;
    return (data['avatarImageUrl'] ?? '').toString().trim();
  }

  static List<Map<String, dynamic>> _products(Map<String, dynamic> data) {
    final products = data['products'];
    if (products is! Iterable) return const [];
    return products
        .whereType<Map>()
        .map((product) => Map<String, dynamic>.from(product))
        .where((product) => _productImageUrl(product).isNotEmpty)
        .toList();
  }

  static String _productImageUrl(Map<String, dynamic> product) {
    const fields = [
      'rawImageUrl',
      'imageUrl',
      'imageURL',
      'processedImageUrl',
      'processed_url',
      'raw_url',
    ];
    for (final field in fields) {
      final value = product[field];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  static int _bottomCount(int itemCount) {
    if (itemCount <= 3) return itemCount;
    if (itemCount == 4) return 3;
    return math.min(3, itemCount);
  }

  double _tileSize({
    required int itemCount,
    required int bottomCount,
    required double width,
    required double height,
  }) {
    final maxTile = compact ? 38.0 : 96.0;
    final minTile = compact ? 18.0 : 42.0;
    final gap = compact ? 3.0 : 6.0;
    final sideCount = itemCount - bottomCount;
    final bottomFit = bottomCount == 0
        ? maxTile
        : (width - gap * (bottomCount + 1)) / bottomCount;
    final sideFit = sideCount == 0
        ? maxTile
        : (height - bottomFit - gap * (sideCount + 2)) / sideCount;
    final fit = math.min(maxTile, math.min(bottomFit, sideFit));
    return fit.clamp(minTile, maxTile).toDouble();
  }

  static double _evenGap({
    required double extent,
    required int itemCount,
    required double tileSize,
    required double fallback,
  }) {
    if (itemCount <= 0) return fallback;
    final available = extent - itemCount * tileSize;
    if (available <= fallback * (itemCount + 1)) return fallback;
    return available / (itemCount + 1);
  }
}

class _SavedOutfit {
  final String id;
  final Map<String, dynamic> data;

  const _SavedOutfit(this.id, this.data);

  String get name => (data['name'] ?? 'Completed Look').toString();

  DateTime get createdAt {
    final value = data['createdAt'];
    return value is Timestamp ? value.toDate() : DateTime(1970);
  }
}
