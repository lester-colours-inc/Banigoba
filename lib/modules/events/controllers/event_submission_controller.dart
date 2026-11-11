// ignore_for_file: use_build_context_synchronously
// (the context is Get.context, re-read after the await)
// Submitting or editing an event: the form fields, flyer, date and sending it
// for curator approval.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:banigoba/core/services/image_crop.dart';
import 'package:banigoba/core/supabase/rows.dart';
import 'package:banigoba/modules/events/services/event_service.dart';
import 'package:banigoba/modules/events/widgets/event_card.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

class EventSubmissionController extends GetxController {
  EventSubmissionController({
    this.eventId,
    this.initialData,
    EventService? service,
  }) : _service = service ?? EventService();

  final String? eventId;
  final Map<String, dynamic>? initialData;
  final EventService _service;
  final ImagePicker _picker = ImagePicker();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController title = TextEditingController();
  final TextEditingController description = TextEditingController();
  final TextEditingController location = TextEditingController();
  final TextEditingController amenities = TextEditingController();
  final TextEditingController price = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController whatsapp = TextEditingController();
  final TextEditingController bookingLink = TextEditingController();

  final Rxn<DateTime> eventDateTime = Rxn<DateTime>();
  final Rxn<Uint8List> flyerBytes = Rxn<Uint8List>();
  final RxString existingFlyerUrl = ''.obs;
  final RxBool saving = false.obs;
  String? _flyerName;

  bool get isEditing => eventId?.isNotEmpty == true;

  @override
  void onInit() {
    super.onInit();
    final data = initialData;
    if (data == null) return;
    title.text = (data['title'] ?? '').toString();
    description.text = (data['description'] ?? '').toString();
    location.text = (data['location'] ?? '').toString();
    amenities.text = List<String>.from(
      data['amenities'] ?? const [],
    ).join(', ');
    price.text = (data['price'] ?? '').toString();
    phone.text = (data['phoneNumber'] ?? '').toString();
    whatsapp.text = (data['whatsappNumber'] ?? '').toString();
    bookingLink.text = (data['bookingLink'] ?? '').toString();
    existingFlyerUrl.value = (data['flyerUrl'] ?? '').toString();
    eventDateTime.value = asDateTime(data['eventDateTime']);
  }

  @override
  void onClose() {
    for (final field in [
      title,
      description,
      location,
      amenities,
      price,
      phone,
      whatsapp,
      bookingLink,
    ]) {
      field.dispose();
    }
    super.onClose();
  }

  Future<void> pickFlyer() async {
    final picked = await _picker.pickAndCropImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (isClosed) return;
    flyerBytes.value = bytes;
    _flyerName = picked.name;
  }

  Future<void> pickDateTime() async {
    final context = Get.context;
    if (context == null) return;
    final now = DateTime.now();
    final current = eventDateTime.value;
    final date = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 3),
    );
    final timeContext = Get.context;
    if (date == null || isClosed || timeContext == null) return;

    final time = await showTimePicker(
      context: timeContext,
      initialTime: current == null
          ? TimeOfDay.now()
          : TimeOfDay.fromDateTime(current),
    );
    if (time == null) return;

    eventDateTime.value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  Future<void> submit() async {
    if (saving.value) return;
    if (!formKey.currentState!.validate()) return;
    final when = eventDateTime.value;
    if (when == null) {
      AppToast.say('Choose the event date and time.');
      return;
    }
    final bytes = flyerBytes.value;
    if (bytes == null && existingFlyerUrl.value.isEmpty) {
      AppToast.say('Upload the event flyer.');
      return;
    }

    saving.value = true;
    try {
      final flyerUrl = bytes == null
          ? existingFlyerUrl.value
          : await _service.uploadEventFlyer(
              bytes: bytes,
              fileName: _flyerName ?? 'event-flyer.jpg',
            );
      if (isEditing) {
        await _service.updateEvent(
          eventId: eventId!,
          title: title.text,
          description: description.text,
          location: location.text,
          eventDateTime: when,
          amenities: splitCsv(amenities.text),
          price: price.text,
          phoneNumber: phone.text,
          whatsappNumber: whatsapp.text,
          bookingLink: bookingLink.text,
          flyerUrl: flyerUrl,
        );
      } else {
        await _service.submitEvent(
          title: title.text,
          description: description.text,
          location: location.text,
          eventDateTime: when,
          amenities: splitCsv(amenities.text),
          price: price.text,
          phoneNumber: phone.text,
          whatsappNumber: whatsapp.text,
          bookingLink: bookingLink.text,
          flyerUrl: flyerUrl,
        );
      }

      if (isClosed) return;
      AppToast.say(
        isEditing
            ? 'Event updated and sent for curator approval.'
            : 'Event submitted for curator approval.',
      );
      Get.back<void>();
    } catch (error) {
      AppToast.say('Unable to submit event: $error');
    } finally {
      if (!isClosed) saving.value = false;
    }
  }
}
