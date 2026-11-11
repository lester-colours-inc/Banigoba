// The top-left control on screens that can be both a main tab and a pushed
// page: a back arrow when there is somewhere to go back to, otherwise the
// menu. Every pushed screen then has a visible way back, rather than relying
// on Android's back gesture (October 2026 review, G-3).
import 'package:flutter/material.dart';

class MenuOrBackButton extends StatelessWidget {
  const MenuOrBackButton({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? Theme.of(context).colorScheme.onSurface;
    if (ModalRoute.of(context)?.canPop ?? false) {
      return IconButton(
        key: const ValueKey('app_back'),
        tooltip: 'Back',
        icon: Icon(Icons.arrow_back, color: iconColor),
        onPressed: () => Navigator.of(context).maybePop(),
      );
    }
    return IconButton(
      key: const ValueKey('app_menu'),
      tooltip: 'Menu',
      icon: Icon(Icons.menu, color: iconColor),
      onPressed: () => openNearestDrawer(context),
    );
  }
}

/// Opens the drawer of the nearest enclosing Scaffold that has one, so a tab
/// page inside the main shell opens the shell's menu.
void openNearestDrawer(BuildContext context) {
  ScaffoldState? scaffold = context.findAncestorStateOfType<ScaffoldState>();
  while (scaffold != null && !scaffold.hasDrawer) {
    scaffold = scaffold.context.findAncestorStateOfType<ScaffoldState>();
  }
  scaffold?.openDrawer();
}
