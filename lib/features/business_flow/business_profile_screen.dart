import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/business_profile.dart';
import '../../shared/widgets/app_media_picker.dart';
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

  // Categories tab
  late List<TextEditingController> _additionalCategoryControllers;

  // Contact & Address
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _postalController;
  late final TextEditingController _stateController;
  late final TextEditingController _countryController;
  late final TextEditingController _phoneController;
  late final TextEditingController _websiteController;

  // Bookings tab
  late final TextEditingController _bookingUrlController;

  // Photos & Logos tab
  late final TextEditingController _logoUrlController;
  late final TextEditingController _coverUrlController;
  late List<TextEditingController> _photoUrlControllers;

  // Services tab
  late List<String> _servicesList;
  late final TextEditingController _newServiceController;

  // Hours & AI Persona
  late final TextEditingController _hoursController;
  late final TextEditingController _audienceController;
  late final TextEditingController _toneController;
  double _postingFrequency = 4;

  bool _saving = false;
  bool _enhancing = false;

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
        if (detailed.descriptionText.isNotEmpty) _descriptionController.text = detailed.descriptionText;
        if (detailed.address.isNotEmpty) _addressController.text = detailed.address;
        if (detailed.cityText.isNotEmpty) _cityController.text = detailed.cityText;
        if (detailed.postalText.isNotEmpty) _postalController.text = detailed.postalText;
        if (detailed.stateText.isNotEmpty) _stateController.text = detailed.stateText;
        if (detailed.countryCodeText.isNotEmpty) _countryController.text = detailed.countryCodeText;
        if (detailed.phone.isNotEmpty) _phoneController.text = detailed.phone;
        if (detailed.website.isNotEmpty) _websiteController.text = detailed.website;
        if (detailed.hoursSummary.isNotEmpty) _hoursController.text = detailed.hoursSummary;
        if (detailed.bookingUrlText.isNotEmpty) _bookingUrlController.text = detailed.bookingUrlText;
        if (detailed.logoUrlText.isNotEmpty) _logoUrlController.text = detailed.logoUrlText;
        if (detailed.coverPhotoUrlText.isNotEmpty) _coverUrlController.text = detailed.coverPhotoUrlText;

        if (detailed.additionalCategoriesList.isNotEmpty) {
          _additionalCategoryControllers = detailed.additionalCategoriesList
              .map((cat) => TextEditingController(text: cat))
              .toList();
        }
        if (detailed.additionalPhotosList.isNotEmpty) {
          _photoUrlControllers = detailed.additionalPhotosList
              .map((url) => TextEditingController(text: url))
              .toList();
        }
        if (detailed.servicesList.isNotEmpty) {
          _servicesList = List<String>.from(detailed.servicesList);
        }
      });
    }
  }

  void _initControllers() {
    final business = ref.read(activeLocationProvider).activeLocation ?? ref.read(selectedBusinessProvider);
    _nameController = TextEditingController(text: business?.name ?? '');
    _categoryController = TextEditingController(text: business?.category ?? '');
    _descriptionController = TextEditingController(text: business?.descriptionText ?? '');

    _additionalCategoryControllers = (business?.additionalCategoriesList ?? [])
        .map((cat) => TextEditingController(text: cat))
        .toList();

    _addressController = TextEditingController(text: business?.address ?? '');
    _cityController = TextEditingController(text: business?.cityText ?? '');
    _postalController = TextEditingController(text: business?.postalText ?? '');
    _stateController = TextEditingController(text: business?.stateText ?? '');
    _countryController = TextEditingController(text: business?.countryCodeText ?? 'US');
    _phoneController = TextEditingController(text: business?.phone ?? '');
    _websiteController = TextEditingController(text: business?.website ?? '');

    _bookingUrlController = TextEditingController(text: business?.bookingUrlText ?? 'https://www.socialhive.pro/signup');

    _logoUrlController = TextEditingController(text: business?.logoUrlText ?? '');
    _coverUrlController = TextEditingController(text: business?.coverPhotoUrlText ?? '');
    _photoUrlControllers = (business?.additionalPhotosList ?? [])
        .map((url) => TextEditingController(text: url))
        .toList();

    _servicesList = business?.servicesList.isNotEmpty == true
        ? List<String>.from(business!.servicesList)
        : [
            'Branding',
            'Business To Business',
            'Content Management',
            'Digital Marketing',
            'Email Marketing',
            'Lead Generation',
            'Link Building',
            'Logo Design',
            'Paid Advertising',
          ];
    _newServiceController = TextEditingController();

    _hoursController = TextEditingController(text: business?.hoursSummary ?? '');
    _audienceController = TextEditingController(text: business?.targetAudience ?? '');
    _toneController = TextEditingController(text: business?.brandTone ?? '');
    _postingFrequency = (business?.postingFrequency ?? 4).toDouble();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    for (final c in _additionalCategoryControllers) {
      c.dispose();
    }
    _addressController.dispose();
    _cityController.dispose();
    _postalController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _bookingUrlController.dispose();
    _logoUrlController.dispose();
    _coverUrlController.dispose();
    for (final c in _photoUrlControllers) {
      c.dispose();
    }
    _newServiceController.dispose();
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

    final profileScore = ref.watch(profileCompletenessProvider(business));

    return DefaultTabController(
      length: 6,
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

            // Navigation Tabs (Matching Web Settings & Screenshots)
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
                  Tab(icon: Icon(Icons.category_outlined, size: 18), text: 'Categories'),
                  Tab(icon: Icon(Icons.photo_library_outlined, size: 18), text: 'Photos & Logos'),
                  Tab(icon: Icon(Icons.calendar_month_outlined, size: 18), text: 'Bookings'),
                  Tab(icon: Icon(Icons.design_services_outlined, size: 18), text: 'Services'),
                  Tab(icon: Icon(Icons.location_on_outlined, size: 18), text: 'Address & Hours'),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                children: [
                  _buildBasicInfoTab(isDark, cardBgColor, borderColor, textPrimary, textSecondary),
                  _buildCategoriesTab(isDark, cardBgColor, borderColor, textPrimary, textSecondary, business),
                  _buildPhotosLogosTab(isDark, cardBgColor, borderColor, textPrimary, textSecondary),
                  _buildBookingsTab(isDark, cardBgColor, borderColor, textPrimary, textSecondary, business),
                  _buildServicesTab(isDark, cardBgColor, borderColor, textPrimary, textSecondary, business),
                  _buildAddressHoursTab(isDark, cardBgColor, borderColor, textPrimary, textSecondary),
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
              hint: 'e.g. Marketing consultant',
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
              maxLines: 5,
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

  // TAB 2: BUSINESS CATEGORIES (Matching Screenshot 1)
  Widget _buildCategoriesTab(bool isDark, Color cardBgColor, Color borderColor, Color textPrimary, Color textSecondary, BusinessProfile business) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          isDark: isDark,
          cardBgColor: cardBgColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          title: 'Business Category',
          subtitle: 'Help customers find your business by industry. Add additional categories to increase Google Maps visibility.',
          headerAction: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✨ AI Category Research: Analyzing competitor categories...'), backgroundColor: AppColors.primary),
              );
            },
            icon: const Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
            label: Text('AI Category Research', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('PRIMARY CATEGORY *', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: textSecondary, letterSpacing: 0.5)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('PRIMARY', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _categoryController,
              style: GoogleFonts.inter(fontSize: 14, color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Marketing consultant',
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'ADDITIONAL CATEGORIES (${_additionalCategoryControllers.length})',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: textSecondary, letterSpacing: 0.5),
            ),
            const SizedBox(height: 6),
            if (_additionalCategoryControllers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No additional categories added. Click \'AI Category Research\' or \'+ Add another category\' to increase your reach.',
                  style: GoogleFonts.inter(fontSize: 13, fontStyle: FontStyle.italic, color: textSecondary),
                ),
              )
            else
              Column(
                children: [
                  for (int i = 0; i < _additionalCategoryControllers.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _additionalCategoryControllers[i],
                              style: GoogleFonts.inter(fontSize: 14, color: textPrimary),
                              decoration: InputDecoration(
                                hintText: 'e.g. Advertising Agency',
                                filled: true,
                                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.error),
                            onPressed: () {
                              setState(() {
                                _additionalCategoryControllers.removeAt(i);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _additionalCategoryControllers.add(TextEditingController());
                  });
                },
                icon: const Icon(Icons.add, size: 16),
                label: Text('+ Add another category', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: textPrimary,
                  side: BorderSide(color: borderColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _saveProfile(business),
                icon: const Icon(Icons.save_outlined, size: 16),
                label: Text('Save Categories', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // TAB 3: PHOTOS & LOGOS (Matching Screenshot 2)
  Widget _buildPhotosLogosTab(bool isDark, Color cardBgColor, Color borderColor, Color textPrimary, Color textSecondary) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Photos & Logos',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage how your business appears visually on Google.',
          style: GoogleFonts.inter(fontSize: 13, color: textSecondary),
        ),
        const SizedBox(height: 16),

        // Photo Cards Grid
        AppMediaPicker(
          initialUrl: _logoUrlController.text,
          label: 'Business Logo',
          subtitle: 'Help customers recognize your business on Google.',
          onMediaSelected: (pathOrUrl) {
            _logoUrlController.text = pathOrUrl;
          },
        ),
        const SizedBox(height: 16),
        AppMediaPicker(
          initialUrl: _coverUrlController.text,
          label: 'Cover Photo',
          subtitle: 'Showcase the personality of your business. Main photo customers see.',
          onMediaSelected: (pathOrUrl) {
            _coverUrlController.text = pathOrUrl;
          },
        ),
        const SizedBox(height: 16),
        AppMediaPicker(
          initialUrl: _photoUrlControllers.isNotEmpty ? _photoUrlControllers.first.text : '',
          label: 'Additional Photos',
          subtitle: 'Add interior, exterior, product, or team photos.',
          onMediaSelected: (pathOrUrl) {
            if (_photoUrlControllers.isEmpty) {
              _photoUrlControllers.add(TextEditingController(text: pathOrUrl));
            } else {
              _photoUrlControllers.first.text = pathOrUrl;
            }
          },
        ),
      ],
    );
  }

  // TAB 4: BOOKINGS (Matching Screenshot 3)
  Widget _buildBookingsTab(bool isDark, Color cardBgColor, Color borderColor, Color textPrimary, Color textSecondary, BusinessProfile business) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Bookings',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage your online booking links.',
          style: GoogleFonts.inter(fontSize: 13, color: textSecondary),
        ),
        const SizedBox(height: 16),

        _buildSectionCard(
          isDark: isDark,
          cardBgColor: cardBgColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          title: 'Links to your online booking tools',
          subtitle: 'Let customers book you directly through custom links to your online booking pages.',
          children: [
            _buildTextField(
              controller: _bookingUrlController,
              label: 'Booking URL',
              hint: 'https://www.socialhive.pro/signup',
              icon: Icons.link_outlined,
              isDark: isDark,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _saveProfile(business),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _bookingUrlController.text = business.bookingUrlText;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textPrimary,
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // TAB 5: SERVICES (Matching Screenshot 4)
  Widget _buildServicesTab(bool isDark, Color cardBgColor, Color borderColor, Color textPrimary, Color textSecondary, BusinessProfile business) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Services',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          'List the services you offer to attract more customers.',
          style: GoogleFonts.inter(fontSize: 13, color: textSecondary),
        ),
        const SizedBox(height: 16),

        _buildSectionCard(
          isDark: isDark,
          cardBgColor: cardBgColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          title: _categoryController.text.isNotEmpty ? _categoryController.text : 'Marketing Agency',
          subtitle: 'Specific services offered under this primary business category.',
          children: [
            for (int i = 0; i < _servicesList.length; i++)
              Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: borderColor, width: 0.8)),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _servicesList[i],
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                        onPressed: () {
                          setState(() {
                            _servicesList.removeAt(i);
                          });
                        },
                      ),
                      const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newServiceController,
                    style: GoogleFonts.inter(fontSize: 14, color: textPrimary),
                    decoration: InputDecoration(
                      hintText: 'e.g. SEO Optimization',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    final text = _newServiceController.text.trim();
                    if (text.isNotEmpty) {
                      setState(() {
                        _servicesList.add(text);
                        _newServiceController.clear();
                      });
                    }
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: Text('Add Service', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // TAB 6: ADDRESS & HOURS
  Widget _buildAddressHoursTab(bool isDark, Color cardBgColor, Color borderColor, Color textPrimary, Color textSecondary) {
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
        const SizedBox(height: 16),
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

  Widget _buildSectionCard({
    required bool isDark,
    required Color cardBgColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required String title,
    required String subtitle,
    required List<Widget> children,
    Widget? headerAction,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
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
                  ],
                ),
              ),
              ?headerAction,
            ],
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
      final addCats = _additionalCategoryControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      final addPhotos = _photoUrlControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final updated = current.copyWith(
        name: _nameController.text.trim(),
        category: _categoryController.text.trim(),
        description: _descriptionController.text.trim(),
        additionalCategories: addCats,
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        postal: _postalController.text.trim(),
        state: _stateController.text.trim(),
        countryCode: _countryController.text.trim(),
        phone: _phoneController.text.trim(),
        website: _websiteController.text.trim(),
        bookingUrl: _bookingUrlController.text.trim(),
        logoUrl: _logoUrlController.text.trim(),
        coverPhotoUrl: _coverUrlController.text.trim(),
        additionalPhotos: addPhotos,
        services: _servicesList,
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
