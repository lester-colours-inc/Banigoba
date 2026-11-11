// Which of the four main destinations is showing, and the drawer.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/core/main_tab.dart';

class MainController extends GetxController {
  MainController({this.initialTab = MainTab.home});

  final MainTab initialTab;

  /// The tab asked for before a [MainController] existed to show it.
  static MainTab? _pending;
  static MainController? _active;

  /// Switches the visible destination from anywhere in the app.
  static void selectTab(MainTab tab) {
    final active = _active;
    if (active == null) {
      _pending = tab;
      return;
    }
    active.currentTab.value = tab;
  }

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  late final Rx<MainTab> currentTab = initialTab.obs;

  @override
  void onInit() {
    super.onInit();
    _active = this;
  }

  @override
  void onReady() {
    super.onReady();
    final pending = _pending;
    if (pending == null) return;
    _pending = null;
    currentTab.value = pending;
  }

  @override
  void onClose() {
    if (identical(_active, this)) _active = null;
    super.onClose();
  }

  /// From the drawer: switch tab and close the drawer.
  void selectFromDrawer(MainTab tab) {
    currentTab.value = tab;
    Get.back<void>();
  }

  void selectIndex(int index) => currentTab.value = MainTab.fromIndex(index);

  /// Closes the drawer if it is open; true when it was.
  bool closeDrawer() {
    final scaffold = scaffoldKey.currentState;
    if (scaffold == null || !scaffold.isDrawerOpen) return false;
    scaffold.closeDrawer();
    return true;
  }
}
