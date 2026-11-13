// A small round button that sits above the Makeover button on Home and opens
// the eFitting Room (it lives with the Smart Wardrobe).
import 'package:flutter/material.dart';

const String kEFittingRoomFabLabel = 'eFitting Room';

class EFittingRoomFab extends StatelessWidget {
  const EFittingRoomFab({
    super.key,
    required this.color,
    required this.onPressed,
  });

  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: kEFittingRoomFabLabel,
      excludeSemantics: true,
      child: FloatingActionButton.small(
        key: const ValueKey('home_efitting_room_button'),
        heroTag: null,
        tooltip: kEFittingRoomFabLabel,
        backgroundColor: Colors.white,
        foregroundColor: color,
        elevation: 4,
        shape: CircleBorder(
          side: BorderSide(color: color.withValues(alpha: 0.18)),
        ),
        onPressed: onPressed,
        child: const Icon(Icons.checkroom_outlined),
      ),
    );
  }
}
