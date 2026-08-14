import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/business_profile.dart';
import '../dashboard/providers/dashboard_providers.dart';
import 'business_flow_controller.dart';

class BusinessProfileScreen extends ConsumerStatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  ConsumerState<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends ConsumerState<BusinessProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _descriptionController;

  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _postalController;
  late final TextEditingController _stateController;
  late final TextEditingController _countryController;
  late final TextEditingController _phoneController;
  late final TextEditingController _websiteController;

  late final TextEditingController _hoursController;

  late final TextEditingController _audienceController;
  late final TextEditingController _toneController;
  double _postingFrequency = 4;

  bool _saving = false;
  bool _enhancing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    final business = ref.read(selectedBusinessProvider);
    _nameController = TextEditingController(text: business?.name ?? '');
    _categoryController = TextEditingController(text: business?.category ?? '');
    _descriptionController = TextEditingController(text: business?.description ?? '');

    _addressController = TextEditingController(text: business?.address ?? '');
    _cityController = TextEditingController(text: business?.city ?? '');
    _postalController = TextEditingController(text: business?.postal ?? '');
    _stateController = TextEditingController(text: business?.state ?? '');
    _countryController = TextEditingController(text: business?.countryCode ?? 'US');
    _phoneController = TextEditingController(text: business?.phone ?? '');
    _websiteController = TextEditingController(text: business?.website ?? '');

    _hoursController = TextEditingController(text: business?.hoursSummary ?? '');

    _audienceController = TextEditingController(text: business?.targetAudience ?? '');
    _toneController = TextEditingController(text: business?.brandTone ?? '');
    _postingFrequency = (business?.postingFrequency ?? 4).toDouble();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _hoursController.dispose();
    _audienceController.dispose();
    _toneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final business = ref.watch(selectedBusinessProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (business == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Business Profile')),
        body: const Center(child: Text('No business location selected.')),
      );
    }

    final profileScore = ref.watch(profileCompletenessProvider(business));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFAFAFAF).withValues(alpha: 0.05),
      appBar: AppBar(
        title: const Text('Business Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _saving ? null : () => _saveProfile(business),
              icon: _saving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check, size: 16),
              label: Text(_saving ? 'Saving...' : 'Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Business Identity Card & Profile Strength Header
          _buildHeaderCard(context, business, profileScore, isDark),

          // Navigation Tabs
          Container(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: isDark ? Colors.white70 : AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(icon: Icon(Icons.info_outline, size: 18), text: 'Basic Info'),
                Tab(icon: Icon(Icons.location_on_outlined, size: 18), text: 'Contact & Location'),
                Tab(icon: Icon(Icons.access_time_outlined, size: 18), text: 'Operating Hours'),
                Tab(icon: Icon(Icons.auto_awesome_outlined, size: 18), text: 'Brand & AI Persona'),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBasicInfoTab(isDark),
                _buildContactLocationTab(isDark),
                _buildHoursTab(isDark),
                _buildBrandPersonaTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, BusinessProfile business, int profileScore, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    business.name.isNotEmpty ? business.name[0].toUpperCase() : 'B',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: business.isManual
                                ? Colors.amber.withValues(alpha: 0.15)
                                : const Color(0xFF16A34A).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: business.isManual
                                  ? Colors.amber.withValues(alpha: 0.3)
                                  : const Color(0xFF16A34A).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            business.isManual ? 'Manual Location' : 'Google Verified',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: business.isManual ? Colors.amber[700] : const Color(0xFF16A34A),
                            ),
                          ),
                        ),
                        if (business.storeCode.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            business.storeCode,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white70 : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dynamic Profile Completeness Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profile Strength',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
              Text(
                '$profileScore%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: profileScore >= 80
                      ? const Color(0xFF16A34A)
                      : profileScore >= 50
                          ? Colors.amber[700]
                          : Colors.red[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: profileScore / 100.0,
              minHeight: 6,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                profileScore >= 80
                    ? const Color(0xFF16A34A)
                    : profileScore >= 50
                        ? Colors.amber[500]!
                        : Colors.red[500]!,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // TAB 1: BASIC INFO
  Widget _buildBasicInfoTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          isDark: isDark,
          title: 'Basic Identity',
          subtitle: 'Core business title, primary category, and description.',
          children: [
            _buildTextField(
              controller: _nameController,
              label: 'Business Title / Name',
              hint: 'e.g. Acme Coffee Roasters',
              icon: Icons.storefront_outlined,
              isDark: isDark,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _categoryController,
              label: 'Primary Category',
              hint: 'e.g. Coffee Shop',
              icon: Icons.category_outlined,
              isDark: isDark,
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Business Description',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: _enhancing ? null : _enhanceDescriptionWithAI,
                  icon: _enhancing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        )
                      : const Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                  label: Text(
                    _enhancing ? 'Generating...' : 'Enhance with AI',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              maxLength: 750,
              style: TextStyle(fontSize: 14, color: isDark ? Colors.white : AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'A cozy neighborhood coffee shop serving artisanal coffee...',
                hintStyle: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary, fontSize: 13),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // TAB 2: CONTACT & LOCATION
  Widget _buildContactLocationTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          isDark: isDark,
          title: 'Storefront Address',
          subtitle: 'Physical address visible to Google Search & Maps users.',
          children: [
            _buildTextField(
              controller: _addressController,
              label: 'Street Address',
              hint: '123 Main Street',
              icon: Icons.map_outlined,
              isDark: isDark,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _cityController,
                    label: 'City',
                    hint: 'New York',
                    icon: Icons.location_city_outlined,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _postalController,
                    label: 'Postal Code',
                    hint: '10001',
                    icon: Icons.markunread_outlined,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _stateController,
                    label: 'State / Province',
                    hint: 'NY',
                    icon: Icons.explore_outlined,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _countryController,
                    label: 'Country Code',
                    hint: 'US',
                    icon: Icons.flag_outlined,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          isDark: isDark,
          title: 'Direct Contact Details',
          subtitle: 'Primary phone number and official website URI.',
          children: [
            _buildTextField(
              controller: _phoneController,
              label: 'Primary Phone Number',
              hint: '+1 (555) 000-0000',
              icon: Icons.phone_outlined,
              isDark: isDark,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _websiteController,
              label: 'Website URI',
              hint: 'https://example.com',
              icon: Icons.language_outlined,
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }

  // TAB 3: OPERATING HOURS
  Widget _buildHoursTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          isDark: isDark,
          title: 'Operating Hours Summary',
          subtitle: 'Set open hours summary displayed on profile cards and search results.',
          children: [
            _buildTextField(
              controller: _hoursController,
              label: 'Hours Summary',
              hint: 'Mon - Fri: 9:00 AM - 5:00 PM, Sat: 10:00 AM - 2:00 PM',
              icon: Icons.schedule_outlined,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildHoursChip('Mon-Fri 9-5', isDark),
                _buildHoursChip('Mon-Sat 8-6', isDark),
                _buildHoursChip('Open 24/7', isDark),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHoursChip(String presetText, bool isDark) {
    return ActionChip(
      label: Text(presetText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
      side: BorderSide(color: isDark ? const Color(0xFF334155) : AppColors.border),
      onPressed: () {
        setState(() {
          _hoursController.text = presetText;
        });
      },
    );
  }

  // TAB 4: BRAND & AI PERSONA
  Widget _buildBrandPersonaTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          isDark: isDark,
          title: 'AI Persona & Content Style',
          subtitle: 'Configure target audience, tone of voice, and weekly posting frequency.',
          children: [
            _buildTextField(
              controller: _audienceController,
              label: 'Target Audience',
              hint: 'e.g. Local professionals, coffee lovers, remote workers',
              icon: Icons.people_outline,
              isDark: isDark,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _toneController,
              label: 'Brand Tone of Voice',
              hint: 'e.g. Friendly, Professional, Energetic, Casual',
              icon: Icons.record_voice_over_outlined,
              isDark: isDark,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Target Auto-Posting Frequency',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_postingFrequency.round()} posts / week',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primary,
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: _postingFrequency,
                min: 1,
                max: 14,
                divisions: 13,
                label: '${_postingFrequency.round()}',
                onChanged: (val) => setState(() => _postingFrequency = val),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required bool isDark,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: TextStyle(fontSize: 14, color: isDark ? Colors.white : AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary, fontSize: 13),
            prefixIcon: Icon(icon, size: 18, color: isDark ? Colors.white70 : AppColors.textSecondary),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Future<void> _enhanceDescriptionWithAI() async {
    final name = _nameController.text.trim();
    final category = _categoryController.text.trim();
    final currentDesc = _descriptionController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a business title first.')),
      );
      return;
    }

    setState(() => _enhancing = true);
    try {
      final enhanced = await ref.read(businessRepositoryProvider).enhanceDescription(
            businessName: name,
            category: category.isNotEmpty ? category : 'Local Business',
            currentDescription: currentDesc,
          );

      setState(() {
        _descriptionController.text = enhanced;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Description enhanced with local SEO AI!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to enhance description: ${e.toString()}'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _enhancing = false);
      }
    }
  }

  Future<void> _saveProfile(BusinessProfile current) async {
    setState(() => _saving = true);
    try {
      final updated = current.copyWith(
        name: _nameController.text.trim(),
        category: _categoryController.text.trim(),
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        postal: _postalController.text.trim(),
        state: _stateController.text.trim(),
        countryCode: _countryController.text.trim(),
        phone: _phoneController.text.trim(),
        website: _websiteController.text.trim(),
        hoursSummary: _hoursController.text.trim(),
        targetAudience: _audienceController.text.trim(),
        brandTone: _toneController.text.trim(),
        postingFrequency: _postingFrequency.round(),
      );

      final saved = await ref.read(businessRepositoryProvider).updateBusinessProfile(updated);
      ref.read(selectedBusinessProvider.notifier).setBusiness(saved);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Business profile updated successfully!'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
