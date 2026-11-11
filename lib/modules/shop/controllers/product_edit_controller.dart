// The owner's "Edit Item" sheet: name, style, visibility and tags.
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class ProductEditController extends GetxController {
  ProductEditController({
    required Map<String, dynamic> product,
    required this.isCatalog,
    required this.onSave,
  }) : name = TextEditingController(text: product['name'] as String?),
       styleTag =
           ((product['styleTag'] ?? product['style'] ?? 'casual') as String)
               .obs,
       visibility = ((product['visibility'] ?? 'private') as String).obs,
       colours = List<String>.from(product['colours'] as List? ?? const []).obs,
       weatherTags = List<String>.from(
         product['weatherTags'] as List? ?? const [],
       ).obs,
       functionalTags = List<String>.from(
         product['functionalTags'] as List? ?? const [],
       ).obs;

  static const List<String> availableColours = [
    'black',
    'white',
    'grey',
    'blue',
    'red',
    'green',
    'yellow',
    'orange',
    'pink',
    'purple',
    'brown',
    'beige',
  ];
  static const List<String> styleOptions = [
    'casual',
    'afrochic',
    'corporate',
    'streetwear',
    'glamour',
  ];
  static const List<String> weatherOptions = [
    'hot',
    'mild',
    'cool',
    'cold',
    'rainy',
  ];
  static const List<String> functionalOptions = [
    'waterproof',
    'breathable',
    'insulated',
    'windproof',
  ];

  final bool isCatalog;
  final Future<void> Function(Map<String, dynamic> updated) onSave;

  final TextEditingController name;
  final RxString styleTag;
  final RxString visibility;
  final RxList<String> colours;
  final RxList<String> weatherTags;
  final RxList<String> functionalTags;

  @override
  void onClose() {
    name.dispose();
    super.onClose();
  }

  void toggle(RxList<String> list, String value, {required bool on}) {
    if (on) {
      list.add(value);
    } else {
      list.remove(value);
    }
  }

  Future<void> save() => onSave({
    'name': name.text,
    'styleTag': styleTag.value,
    'colours': colours.toList(),
    'weatherTags': weatherTags.toList(),
    'functionalTags': functionalTags.toList(),
    if (!isCatalog) 'visibility': visibility.value,
  });
}
