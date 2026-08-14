import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/business_profile.dart';
import '../dashboard/providers/dashboard_providers.dart';
import 'business_flow_controller.dart';
import 'providers/active_location_provider.dart';

class BusinessProfileScreen extends ConsumerStatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  ConsumerState<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends ConsumerState<BusinessProfileScreen> {
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
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExtendedProfile();
    });
  }

  Future<void> _loadExtendedProfile() async {
    final activeLocation = ref.read(activeLocationProvider).activeLocation ?? ref.read(selectedBusinessProvider);
    if (activeLocation == null) return;

    final locationId = activeLocation.id;
    final detailed = await ref.read(businessRepositoryProvider).fetchLocationProfile(locationId);
    if (detailed != null && mounted) {
      ref.read(activeLocationProvider.notifier).selectLocation(detailed);
      ref.read(selectedBusinessProvider.notifier).setBusiness(detailed);

      setState(() {
        if (detailed.descriptionText.isNotEmpty) {
          _descriptionController.text = detailed.descriptionText;
        }
        if (detailed.address.isNotEmpty) _addressController.text = detailed.address;
        if (detailed.cityText.isNotEmpty) _cityController.text = detailed.cityText;
        if (detailed.postalText.isNotEmpty) _postalController.text = detailed.postalText;
        if (detailed.stateText.isNotEmpty) _stateController.text = detailed.stateText;
        if (detailed.countryCodeText.isNotEmpty) _countryController.text = detailed.countryCodeText;
        if (detailed.phone.isNotEmpty) _phoneController.text = detailed.phone;
        if (detailed.website.isNotEmpty) _websiteController.text = detailed.website;
        if (detailed.hoursSummary.isNotEmpty) _hoursController.text = detailed.hoursSummary;
      });
    }
  }

  void _initControllers() {
    final business = ref.read(activeLocationProvider).activeLocation ?? ref.read(selectedBusinessProvider);
    _nameController = TextEditingController(text: business?.name ?? '');
    _categoryController = TextEditingController(text: business?.category ?? '');
    _descriptionController = TextEditingController(text: business?.descriptionText ?? '');

    _addressController = TextEditingController(text: business?.address ?? '');
    _cityController = TextEditingController(text: business?.cityText ?? '');
    _postalController = TextEditingController(text: business?.postalText ?? '');
    _stateController = TextEditingController(text: business?.stateText ?? '');
    _countryController = TextEditingController(text: business?.countryCodeText ?? 'US');
    _phoneController = TextEditingController(text: business?.phone ?? '');
    _websiteController = TextEditingController(text: business?.website ?? '');

    _hoursController = TextEditingController(text: business?.hoursSummary ?? '');

    _audienceController = TextEditingController(text: business?.targetAudience ?? '');
    _toneController = TextEditingController(text: business?.brandTone ?? '');
    _postingFrequency = (business?.postingFrequency ?? 4).toDouble();
    _isInitialized = true;
  }

  void _updateControllersIfUnchanged(BusinessProfile business) {
    if (_nameController.text.isEmpty && business.name.isNotEmpty) {
      _nameController.text = business.name;
    }
    if (_categoryController.text.isEmpty && business.category.isNotEmpty) {
      _categoryController.text = business.category;
    }
    if (_descriptionController.text.isEmpty && business.descriptionText.isNotEmpty) {
      _descriptionController.text = business.descriptionText;
    }
    if (_addressController.text.isEmpty && business.address.isNotEmpty) {
      _addressController.text = business.address;
    }
    if (_cityController.text.isEmpty && business.cityText.isNotEmpty) {
      _cityController.text = business.cityText;
    }
    if (_postalController.text.isEmpty && business.postalText.isNotEmpty) {
      _postalController.text = business.postalText;
    }
    if (_stateController.text.isEmpty && business.stateText.isNotEmpty) {
      _stateController.text = business.stateText;
    }
    if (_phoneController.text.isEmpty && business.phone.isNotEmpty) {
      _phoneController.text = business.phone;
    }
    if (_websiteController.text.isEmpty && business.website.isNotEmpty) {
      _websiteController.text = business.website;
    }
    if (_hoursController.text.isEmpty && business.hoursSummary.isNotEmpty) {
      _hoursController.text = business.hoursSummary;
    }
  }

  @override
  void dispose() {
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
    final activeLocState = ref.watch(activeLocationProvider);
    final selectedBusiness = ref.watch(selectedBusinessProvider);

    final business = activeLocState.activeLocation ?? selectedBusiness;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    if (activeLocState.isLoading && business == null) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: cardBgColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            'Business Profile',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: textPrimary),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (business == null) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: cardBgColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            'Business Profile',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: textPrimary),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.storefront_outlined, size: 64, color: textSecondary),
              const SizedBox(height: 16),
              Text(
                'No Business Location Selected',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Please select or connect a location to manage its profile.',
                style: GoogleFonts.inter(color: textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => ref.read(activeLocationProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text('Refresh Locations', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isInitialized) {
      _updateControllersIfUnchanged(business);
    }

    final profileScore = ref.watch(profileCompletenessProvider(business));

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: cardBgColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            'Business Profile',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: textPrimary),
          ),
        ),
        body: Column(
          children: [
            // Business Identity Card & Profile Strength Header
            _buildHeaderCard(context, business, profileScore, isDark, cardBgColor, borderColor, textPrimary, textSecondary),

            // Navigation Tabs
            Container(
              decoration: BoxDecoration(
                color: cardBgColor,
                border: Border(bottom: BorderSide(color: borderColor, width: 1)),
              ),
              child: TabBar(
                isScrollable: true,
                labelColor: AppColors.primary,
                unselectedLabelColor: textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
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
                children: [
                  _buildBasicInfoTab(isDark, cardBgColor, borderColor, textPrimary, textSecondary),
                  _buildContactLocationTab(isDark, cardBgColor, borderColor, textPrimary, textSecondary),
                  _buildHoursTab(isDark, cardBgColor, borderColor, textPrimary, textSecondary),
                  _buildBrandPersonaTab(isDark, cardBgColor, borderColor, textPrimary, textSecondary),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: cardBgColor,
            border: Border(top: BorderSide(color: borderColor, width: 1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : () => _saveProfile(business),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline, size: 18),
                label: Text(
                  _saving ? 'Saving Changes...' : 'Save Profile Changes',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    BusinessProfile business,
    int profileScore,
    bool isDark,
    Color cardBgColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
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
                  gradient: AppColors.blueGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    business.name.isNotEmpty ? business.name[0].toUpperCase() : 'B',
                    style: GoogleFonts.inter(
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
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
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
                            color: business.isManualLocation
                                ? Colors.amber.withValues(alpha: 0.15)
                                : AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: business.isManualLocation
                                  ? Colors.amber.withValues(alpha: 0.3)
                                  : AppColors.success.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            business.isManualLocation ? 'Manual Location' : 'Google Verified',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: business.isManualLocation ? Colors.amber[700] : AppColors.success,
                            ),
                          ),
                        ),
                        if (business.storeCodeText.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            business.storeCodeText,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: textSecondary,
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
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
              Text(
                '$profileScore%',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: profileScore >= 80
                      ? AppColors.success
                      : profileScore >= 50
                          ? Colors.amber[700]
                          : AppColors.error,
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
                    ? AppColors.success
                    : profileScore >= 50
                        ? Colors.amber[500]!
                        : AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // TAB 1: BASIC INFO
  Widget _buildBasicInfoTab(bool isDark, Color cardBgColor, Color borderColor, Color textPrimary, Color textSecondary) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          isDark: isDark,
          cardBgColor: cardBgColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          title: 'Basic Identity',
          subtitle: 'Core business title, primary category, and description.',
          children: [
            _buildTextField(
              controller: _nameController,
              label: 'Business Title / Name',
              hint: 'e.g. Acme Coffee Roasters',
              icon: Icons.storefront_outlined,
              isDark: isDark,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _categoryController,
              label: 'Primary Category',
              hint: 'e.g. Coffee Shop',
              icon: Icons.category_outlined,
              isDark: isDark,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Business Description',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
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
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              maxLength: 750,
              style: GoogleFonts.inter(fontSize: 14, color: textPrimary),
              decoration: InputDecoration(
                hintText: 'A cozy neighborhood coffee shop serving artisanal coffee...',
                hintStyle: GoogleFonts.inter(color: textSecondary, fontSize: 13),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // TAB 2: CONTACT & LOCATION
  Widget _buildContactLocationTab(bool isDark, Color cardBgColor, Color borderColor, Color textPrimary, Color textSecondary) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          isDark: isDark,
          cardBgColor: cardBgColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          title: 'Storefront Address',
          subtitle: 'Physical address visible to Google Search & Maps users.',
          children: [
            _buildTextField(
              controller: _addressController,
              label: 'Street Address',
              hint: '123 Main Street',
              icon: Icons.map_outlined,
              isDark: isDark,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
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
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
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
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
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
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
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
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          isDark: isDark,
          cardBgColor: cardBgColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          title: 'Direct Contact Details',
          subtitle: 'Primary phone number and official website URI.',
          children: [
            _buildTextField(
              controller: _phoneController,
              label: 'Primary Phone Number',
              hint: '+1 (555) 000-0000',
              icon: Icons.phone_outlined,
              isDark: isDark,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _websiteController,
              label: 'Website URI',
              hint: 'https://example.com',
              icon: Icons.language_outlined,
              isDark: isDark,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
          ],
        ),
      ],
    );
  }

  // TAB 3: OPERATING HOURS
  Widget _buildHoursTab(bool isDark, Color cardBgColor, Color borderColor, Color textPrimary, Color textSecondary) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          isDark: isDark,
          cardBgColor: cardBgColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          title: 'Operating Hours Summary',
          subtitle: 'Set open hours summary displayed on profile cards and search results.',
          children: [
            _buildTextField(
              controller: _hoursController,
              label: 'Hours Summary',
              hint: 'Mon - Fri: 9:00 AM - 5:00 PM, Sat: 10:00 AM - 2:00 PM',
              icon: Icons.schedule_outlined,
              isDark: isDark,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildHoursChip('Mon-Fri 9-5', isDark, borderColor),
                _buildHoursChip('Mon-Sat 8-6', isDark, borderColor),
                _buildHoursChip('Open 24/7', isDark, borderColor),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHoursChip(String presetText, bool isDark, Color borderColor) {
    return ActionChip(
      label: Text(presetText, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      side: BorderSide(color: borderColor),
      onPressed: () {
        setState(() {
          _hoursController.text = presetText;
        });
      },
    );
  }

  // TAB 4: BRAND & AI PERSONA
  Widget _buildBrandPersonaTab(bool isDark, Color cardBgColor, Color borderColor, Color textPrimary, Color textSecondary) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          isDark: isDark,
          cardBgColor: cardBgColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          title: 'AI Persona & Content Style',
          subtitle: 'Configure target audience, tone of voice, and weekly posting frequency.',
          children: [
            _buildTextField(
              controller: _audienceController,
              label: 'Target Audience',
              hint: 'e.g. Local professionals, coffee lovers, remote workers',
              icon: Icons.people_outline,
              isDark: isDark,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _toneController,
              label: 'Brand Tone of Voice',
              hint: 'e.g. Friendly, Professional, Energetic, Casual',
              icon: Icons.record_voice_over_outlined,
              isDark: isDark,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Target Auto-Posting Frequency',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
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
                    style: GoogleFonts.inter(
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
    required Color cardBgColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
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
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: textSecondary,
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
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: GoogleFonts.inter(fontSize: 14, color: textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: textSecondary, fontSize: 13),
            prefixIcon: Icon(icon, size: 18, color: textSecondary),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
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
            backgroundColor: AppColors.error,
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
      ref.read(activeLocationProvider.notifier).selectLocation(saved);
      ref.read(selectedBusinessProvider.notifier).setBusiness(saved);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Business profile updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            backgroundColor: AppColors.error,
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
