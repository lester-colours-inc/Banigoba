// Edit Profile screen: photo, name, @username, city, gender, date of birth.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/settings/controllers/edit_profile_controller.dart';

const Color _primary = Color(0xFF0D0140);

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  static String formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EditProfileController>(
      init: EditProfileController(),
      global: false,
      builder: (c) => Scaffold(
        appBar: AppBar(title: const Text('Edit profile')),
        body: Obx(
          () => c.loading.value
              ? const Center(child: CircularProgressIndicator())
              : _form(context, c),
        ),
      ),
    );
  }

  Widget _form(BuildContext context, EditProfileController c) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Center(
          child: Obx(
            () => CircleAvatar(
              radius: 48,
              backgroundColor: _primary,
              backgroundImage: c.photoUrl.value.isEmpty
                  ? null
                  : CachedNetworkImageProvider(c.photoUrl.value),
              child: c.photoUrl.value.isEmpty
                  ? const Icon(Icons.person, color: Colors.white, size: 48)
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Obx(
            () => Text(
              c.username.value.isEmpty ? '' : '@${c.username.value}',
              style: TextStyle(color: muted),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _heading('About you'),
        TextField(
          controller: c.name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: c.city,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'City (public, for Near me)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        _heading('Private details'),
        Text(
          'Only you can see these. We use your gender to show the right '
          'clothes first in the shop.',
          style: TextStyle(color: muted, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in kGenderOptions.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  selected: c.gender.value == entry.key,
                  selectedColor: _primary,
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    color: c.gender.value == entry.key ? Colors.white : null,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (on) => c.setGender(on ? entry.key : null),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Obx(() {
          final dob = c.dateOfBirth.value;
          return InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () => c.pickDateOfBirth(context),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Date of birth',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.cake_outlined),
                suffixIcon: dob == null
                    ? const Icon(Icons.calendar_today_outlined)
                    : IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.close),
                        onPressed: c.clearDateOfBirth,
                      ),
              ),
              child: Text(dob == null ? 'Not set' : formatDate(dob)),
            ),
          );
        }),
        const SizedBox(height: 28),
        Obx(
          () => FilledButton(
            onPressed: c.saving.value ? null : c.save,
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              minimumSize: const Size(double.infinity, 52),
            ),
            child: Text(c.saving.value ? 'Saving...' : 'Save changes'),
          ),
        ),
      ],
    );
  }

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
    ),
  );
}
