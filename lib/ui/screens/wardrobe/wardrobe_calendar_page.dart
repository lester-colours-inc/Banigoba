// Lets users repeat saved outfits and schedule them against calendar dates.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../data/services/outfit_service.dart';
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

  Future<void> _openFullCalendar() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: widget.eventStart ?? DateTime(2020),
      lastDate: widget.eventEnd ?? DateTime(DateTime.now().year + 5, 12, 31),
      helpText: 'Choose a date to wear an outfit',
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedDate = _dateOnly(picked));
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
            onPressed: _openFullCalendar,
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
                onPressed: _openFullCalendar,
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
    required bool hasOutfit,
    required bool isEventDay,
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
    final imageUrl = worn == null ? '' : _outfitImageUrl(worn);

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
              child: imageUrl.isEmpty
                  ? Icon(Icons.checkroom_outlined, color: colors.outline)
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          Icon(Icons.checkroom_outlined, color: colors.outline),
                    ),
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
              child: outfit.imageUrl.isEmpty
                  ? Icon(
                      Icons.checkroom_outlined,
                      size: 56,
                      color: colors.outline,
                    )
                  : Image.network(
                      outfit.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.broken_image_outlined,
                        color: colors.outline,
                      ),
                    ),
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

  String _outfitImageUrl(Map<String, dynamic> data) {
    final result = (data['imageUrl'] ?? '').toString().trim();
    if (result.isNotEmpty) return result;
    return (data['avatarImageUrl'] ?? '').toString().trim();
  }
}

class _SavedOutfit {
  final String id;
  final Map<String, dynamic> data;

  const _SavedOutfit(this.id, this.data);

  String get name => (data['name'] ?? 'Completed Look').toString();

  String get imageUrl {
    final result = (data['imageUrl'] ?? '').toString().trim();
    if (result.isNotEmpty) return result;
    return (data['avatarImageUrl'] ?? '').toString().trim();
  }

  DateTime get createdAt {
    final value = data['createdAt'];
    return value is Timestamp ? value.toDate() : DateTime(1970);
  }
}
