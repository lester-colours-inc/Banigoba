// The state of one web look search: the words, the pictures found, and the
// copy of a chosen picture. Shared by "Find a look you love" (its Web source)
// and the Style idol search sheet.
import 'dart:async';

import 'package:get/get.dart';

import 'package:banigoba/modules/makeover/services/web_look_search.dart';

class WebLookSearchState {
  WebLookSearchState(
    this._search, {
    this.debounce = const Duration(milliseconds: 450),
  });

  final WebLookSearch _search;
  final Duration debounce;

  final RxString query = ''.obs;
  final RxList<WebLook> looks = <WebLook>[].obs;
  final RxBool isSearching = false.obs;
  final RxString error = ''.obs;

  /// The picture being copied, while it is copied.
  final Rxn<WebLook> keeping = Rxn<WebLook>();

  Timer? _timer;
  int _requestId = 0;
  bool _disposed = false;

  /// Searches for [value] after a short pause in typing.
  void searchSoon(String value) {
    _timer?.cancel();
    query.value = value.trim();
    _timer = Timer(debounce, () => unawaited(searchNow(value)));
  }

  /// Searches for [value] straight away; only the latest answer is kept.
  Future<void> searchNow(String value) async {
    _timer?.cancel();
    final words = value.trim();
    query.value = words;
    final id = ++_requestId;
    error.value = '';
    if (words.length < 2) {
      looks.clear();
      isSearching.value = false;
      return;
    }
    isSearching.value = true;
    try {
      final found = await _search.search(words);
      if (_disposed || id != _requestId) return;
      looks.assignAll(found);
    } on WebLookSearchException catch (e) {
      if (_disposed || id != _requestId) return;
      looks.clear();
      error.value = e.message;
    } finally {
      if (!_disposed && id == _requestId) isSearching.value = false;
    }
  }

  /// Copies [look] to the user's style references; returns its address, or
  /// null (with [error] set) when it cannot be used.
  Future<String?> keep(WebLook look) async {
    if (keeping.value != null) return null;
    keeping.value = look;
    error.value = '';
    try {
      final url = await _search.keep(look);
      if (_disposed) return null;
      if (url == null) {
        error.value = "We couldn't use that picture. Try another one.";
      }
      return url;
    } on Exception {
      if (!_disposed) {
        error.value = "We couldn't use that picture. Try another one.";
      }
      return null;
    } finally {
      if (!_disposed) keeping.value = null;
    }
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
  }
}
