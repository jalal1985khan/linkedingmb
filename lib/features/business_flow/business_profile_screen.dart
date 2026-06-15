import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/business_profile.dart';
import 'business_flow_controller.dart';

class BusinessProfileScreen extends ConsumerStatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  ConsumerState<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends ConsumerState<BusinessProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _locationController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _hoursController;
  late final TextEditingController _websiteController;
  late final TextEditingController _audienceController;
  late final TextEditingController _toneController;
  double _postingFrequency = 4;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final business = ref.read(selectedBusinessProvider);
    _nameController = TextEditingController(text: business?.name ?? '');
    _categoryController = TextEditingController(text: business?.category ?? '');
    _locationController = TextEditingController(text: business?.location ?? '');
    _addressController = TextEditingController(text: business?.address ?? '');
    _phoneController = TextEditingController(text: business?.phone ?? '');
    _hoursController = TextEditingController(text: business?.hoursSummary ?? '');
    _websiteController = TextEditingController(text: business?.website ?? '');
    _audienceController = TextEditingController(text: business?.targetAudience ?? '');
    _toneController = TextEditingController(text: business?.brandTone ?? '');
    _postingFrequency = (business?.postingFrequency ?? 4).toDouble();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _hoursController.dispose();
    _websiteController.dispose();
    _audienceController.dispose();
    _toneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final business = ref.watch(selectedBusinessProvider);
    if (business == null) {
      return const Scaffold(
        body: Center(child: Text('No business selected')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Business Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field(_nameController, 'Business name'),
          _field(_categoryController, 'Category'),
          _field(_locationController, 'Location / service area'),
          _field(_addressController, 'Address'),
          _field(_phoneController, 'Phone number'),
          _field(_hoursController, 'Hours summary'),
          _field(_websiteController, 'Website'),
          _field(_audienceController, 'Target audience'),
          _field(_toneController, 'Brand tone'),
          const SizedBox(height: 8),
          Text(
            'Posting frequency: ${_postingFrequency.round()} per week',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Slider(
            value: _postingFrequency,
            min: 1,
            max: 14,
            divisions: 13,
            label: _postingFrequency.round().toString(),
            onChanged: (value) => setState(() => _postingFrequency = value),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _saving ? null : () => _saveProfile(business),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save Profile'),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile(BusinessProfile current) async {
    setState(() => _saving = true);
    try {
      final updated = current.copyWith(
        name: _nameController.text.trim(),
        category: _categoryController.text.trim(),
        location: _locationController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        hoursSummary: _hoursController.text.trim(),
        website: _websiteController.text.trim(),
        targetAudience: _audienceController.text.trim(),
        brandTone: _toneController.text.trim(),
        postingFrequency: _postingFrequency.round(),
      );
      final saved = await ref.read(businessRepositoryProvider).updateBusinessProfile(updated);
      ref.read(selectedBusinessProvider.notifier).setBusiness(saved);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business profile updated')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
