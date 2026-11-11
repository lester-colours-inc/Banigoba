// What the first-run guide's steps do, injected so the guide is testable.
import 'package:flutter/widgets.dart';

/// What the guide's steps do. Each returns true when the person completed it.
abstract interface class GuideActions {
  Future<bool> addPhoto(BuildContext context);
  Future<bool> pickStyle(BuildContext context);
  Future<bool> addPiece(BuildContext context);
  Future<bool> tryMakeover(BuildContext context);

  /// Marks the guide as seen, so it is not shown again.
  Future<void> finish();
}
