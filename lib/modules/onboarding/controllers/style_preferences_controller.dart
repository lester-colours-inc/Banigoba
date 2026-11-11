import 'package:get/get.dart';

import 'package:banigoba/modules/onboarding/models/style_preferences.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

class StylePreferencesController extends GetxController {
  StylePreferencesController({
    required this.onSave,
    required this.onSkip,
    this.initial = const StylePreferences(),
  });

  /// Called with the user's answers.
  final Future<void> Function(StylePreferences preferences) onSave;

  /// Called when the user chooses to answer later.
  final Future<void> Function() onSkip;

  final StylePreferences initial;

  // UNCLEAR: placeholder list; confirm the style options with the
  // stakeholder. Existing users are also asked once on their next launch,
  // because nobody has answered this yet.
  static const List<String> styleOptions = [
    'Casual',
    'Smart',
    'Traditional',
    'Streetwear',
    'Elegant',
    'Sporty',
  ];

  late final RxSet<String> styles = initial.styles.toSet().obs;
  late final Rxn<MakeoverFocus> focus = Rxn<MakeoverFocus>(initial.focus);
  final RxBool isSaving = false.obs;

  void toggleStyle(String style) {
    if (!styles.remove(style)) styles.add(style);
  }

  void setFocus(MakeoverFocus value, {required bool selected}) =>
      focus.value = selected ? value : null;

  Future<void> save() => _run(
    () => onSave(
      StylePreferences(
        styles: styleOptions.where(styles.contains).toList(),
        focus: focus.value,
      ),
    ),
  );

  Future<void> skip() => _run(onSkip);

  Future<void> _run(Future<void> Function() action) async {
    isSaving.value = true;
    try {
      await action();
    } on Exception catch (error) {
      if (isClosed) return;
      AppToast.say('Unable to save preferences: $error');
    } finally {
      if (!isClosed) isSaving.value = false;
    }
  }
}
