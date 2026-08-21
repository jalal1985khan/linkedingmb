import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/business_profile.dart';
import '../../data/repositories/backend_business_repository.dart';
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
  // Basic Identity
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _descriptionController;

  // Contact Information
  late final TextEditingController _phoneController;
  late final TextEditingController _websiteController;
  late final TextEditingController _emailController;
  late final TextEditingController _businessEmailController;

  // Categories tab
  late List<TextEditingController> _additionalCategoryControllers;

  // Address & Hours
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _postalController;
  late final TextEditingController _stateController;
  late final TextEditingController _countryController;
  late final TextEditingController _hoursController;

  // Bookings tab
  late final TextEditingController _bookingUrlController;

  // Photos & Logos tab
  late final TextEditingController _logoUrlController;
  late final TextEditingController _coverUrlController;
  late List<TextEditingController> _photoUrlControllers;

  // Services tab
  late List<String> _servicesList;
  late final TextEditingController _newServiceController;

  // Products tab
  List<Map<String, dynamic>> _productsList = [];
  bool _loadingProducts = false;

  // AI Persona
  late final TextEditingController _audienceController;
  late final TextEditingController _toneController;
  double _postingFrequency = 4;

  bool _saving = false;
  bool _enhancing = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _descriptionController.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExtendedProfile();
      _loadProducts();
    });
  }

  void _initControllers() {
    final business = ref.read(activeLocationProvider).activeLocation ?? ref.read(selectedBusinessProvider);
    _nameController = TextEditingController(text: business?.name ?? 'SocialHive');
    _categoryController = TextEditingController(text: business?.category.isNotEmpty == true ? business!.category : 'Marketing consultant');
    _descriptionController = TextEditingController(
      text: business?.descriptionText.isNotEmpty == true
          ? business!.descriptionText
          : 'Elevate your online presence with SocialHive, a results-driven marketing consultant helping brands grow through smart strategies, content, and automation.',
    );

    _phoneController = TextEditingController(text: business?.phone.isNotEmpty == true ? business!.phone : '07553 496132');
    _websiteController = TextEditingController(text: business?.website.isNotEmpty == true ? business!.website : 'www.socialhive.pro');
    _emailController = TextEditingController(text: 'hello@socialhive.pro');
    _businessEmailController = TextEditingController(text: 'info@socialhive.pro');

    _additionalCategoryControllers = (business?.additionalCategoriesList ?? [])
        .map((cat) => TextEditingController(text: cat))
        .toList();

    _addressController = TextEditingController(text: business?.address ?? '');
    _cityController = TextEditingController(text: business?.cityText ?? '');
    _postalController = TextEditingController(text: business?.postalText ?? '');
    _stateController = TextEditingController(text: business?.stateText ?? '');
    _countryController = TextEditingController(text: business?.countryCodeText ?? 'US');
    _hoursController = TextEditingController(text: business?.hoursSummary ?? 'Mon - Fri: 9:00 AM - 6:00 PM');

    _bookingUrlController = TextEditingController(text: business?.bookingUrlText ?? 'https://www.socialhive.pro/signup');
    _logoUrlController = TextEditingController(text: business?.logoUrlText ?? '');
    _coverUrlController = TextEditingController(text: business?.coverPhotoUrlText ?? '');
    _photoUrlControllers = (business?.additionalPhotosList ?? [])
        .map((url) => TextEditingController(text: url))
        .toList();

    _servicesList = business?.servicesList.isNotEmpty == true
        ? List<String>.from(business!.servicesList)
        : [
            'Digital Marketing Strategy',
            'Google My Business Optimization',
            'Local SEO & Reviews Management',
            'Social Media Content Creation',
            'Brand Identity & Design',
            'Automated Lead Generation',
          ];
    _newServiceController = TextEditingController();

    _audienceController = TextEditingController(text: business?.targetAudience ?? 'Local business owners and entrepreneurs');
    _toneController = TextEditingController(text: business?.brandTone ?? 'Professional, engaging, and trustworthy');
    _postingFrequency = (business?.postingFrequency ?? 4).toDouble();
  }

  Future<void> _loadProducts() async {
    final activeLocation = ref.read(activeLocationProvider).activeLocation ?? ref.read(selectedBusinessProvider);
    if (activeLocation == null) return;

    setState(() => _loadingProducts = true);
    try {
      final repo = BackendBusinessRepository();
      final products = await repo.getProducts(activeLocation.id);
      if (mounted) {
        setState(() {
          _productsList = products;
          _loadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingProducts = false);
    }
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
        if (detailed.name.isNotEmpty) _nameController.text = detailed.name;
        if (detailed.category.isNotEmpty) _categoryController.text = detailed.category;
        if (detailed.descriptionText.isNotEmpty) _descriptionController.text = detailed.descriptionText;
        if (detailed.phone.isNotEmpty) _phoneController.text = detailed.phone;
        if (detailed.website.isNotEmpty) _websiteController.text = detailed.website;
        if (detailed.address.isNotEmpty) _addressController.text = detailed.address;
        if (detailed.cityText.isNotEmpty) _cityController.text = detailed.cityText;
        if (detailed.postalText.isNotEmpty) _postalController.text = detailed.postalText;
        if (detailed.stateText.isNotEmpty) _stateController.text = detailed.stateText;
        if (detailed.countryCodeText.isNotEmpty) _countryController.text = detailed.countryCodeText;
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

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _emailController.dispose();
    _businessEmailController.dispose();
    for (final c in _additionalCategoryControllers) {
      c.dispose();
    }
    _addressController.dispose();
    _cityController.dispose();
    _postalController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _hoursController.dispose();
    _bookingUrlController.dispose();
    _logoUrlController.dispose();
    _coverUrlController.dispose();
    for (final c in _photoUrlControllers) {
      c.dispose();
    }
    _newServiceController.dispose();
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

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    if (activeLocState.isLoading && business == null) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: _buildAppBar(context, textPrimary, cardBgColor, borderColor, isDark),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
        ),
      );
    }

    final profileScore = business != null ? ref.watch(profileCompletenessProvider(business)) : 100;

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: _buildAppBar(context, textPrimary, cardBgColor, borderColor, isDark),
        body: Column(
          children: [
            // Business Profile Header Card
            _buildHeaderCard(context, business, profileScore, isDark, cardBgColor, borderColor, textPrimary, textSecondary),

            // Navigation Tabs (6 Tabs matching Screenshot)
            Container(
              color: cardBgColor,
              child: TabBar(
                isScrollable: true,
                labelColor: const Color(0xFF4F46E5),
                unselectedLabelColor: textSecondary,
                indicatorColor: const Color(0xFF4F46E5),
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
                tabs: const [
                  Tab(icon: Icon(Icons.info_outline, size: 20), text: 'Basic Info'),
                  Tab(icon: Icon(Icons.interests_outlined, size: 20), text: 'Categories'),
                  Tab(icon: Icon(Icons.photo_library_outlined, size: 20), text: 'Photos & Logos'),
                  Tab(icon: Icon(Icons.calendar_month_outlined, size: 20), text: 'Bookings'),
                  Tab(icon: Icon(Icons.build_outlined, size: 20), text: 'Services'),
                  Tab(icon: Icon(Icons.more_horiz, size: 20), text: 'More'),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: borderColor),

            // Tab Views
            Expanded(
              child: TabBarView(
                children: [
                  _buildBasicInfoTab(isDark, cardBgColor, borderColor, textPrimary, textSecondary),
                  _buildCategoriesTab(isDark, cardBgColor, borderColor, textPrimary, textSecondary, business),
                  _buildPhotosLogosTab(isDark, cardBgColor, borderColor, textPrimary, textSecondary),
                  _buildBookingsTab(isDark, cardBgColor, borderColor, textPrimary, textSecondary, business),
                  _buildServicesTab(isDark, cardBgColor, borderColor, textPrimary, textSecondary, business),
                  _buildMoreTab(isDark, cardBgColor, borderColor, textPrimary, textSecondary, business),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : () => _saveProfile(business),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline, size: 19),
                label: Text(
                  _saving ? 'Saving Changes...' : 'Save Profile Changes',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4338CA),
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

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    Color textPrimary,
    Color cardBgColor,
    Color borderColor,
    bool isDark,
  ) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: textPrimary, size: 24),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Text(
        'Business Profile',
        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: textPrimary),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cardBgColor,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 20, color: textPrimary),
                  Positioned(
                    top: 9,
                    right: 10,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4F46E5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    BusinessProfile? business,
    int profileScore,
    bool isDark,
    Color cardBgColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final displayName = _nameController.text.isNotEmpty ? _nameController.text : (business?.name ?? 'SocialHive');
    final displayIdentifier = business?.phone.isNotEmpty == true
        ? business!.phone
        : (business?.storeCodeText.isNotEmpty == true
            ? business!.storeCodeText
            : (business?.id.isNotEmpty == true ? business!.id.replaceFirst('locations/', '') : '07553496132851692611'));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
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
              // Avatar with AI Tag
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.white, width: 1.5),
                      ),
                      child: Text(
                        'AI',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle, size: 12, color: Color(0xFF059669)),
                              const SizedBox(width: 4),
                              Text(
                                'Google Verified',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayIdentifier,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Profile Strength
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile Strength',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Your profile is complete and optimized',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Text(
                  '$profileScore%',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: profileScore / 100.0,
              minHeight: 8,
              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4338CA)),
            ),
          ),
        ],
      ),
    );
  }

  // TAB 1: BASIC INFO (Matching Screenshot)
  Widget _buildBasicInfoTab(bool isDark, Color cardBgColor, Color borderColor, Color textPrimary, Color textSecondary) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Card 1: Basic Identity
        _buildSectionCard(
          isDark: isDark,
          cardBgColor: cardBgColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          title: 'Basic Identity',
          subtitle: 'Core business details that represent your brand.',
          children: [
            _buildTextField(
              controller: _nameController,
              label: 'Business Title / Name',
              hint: 'SocialHive',
              icon: Icons.storefront_outlined,
              isDark: isDark,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 16),
            _buildCategorySelector(isDark, borderColor, textPrimary, textSecondary),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Business Description',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                InkWell(
                  onTap: _enhancing ? null : _enhanceDescriptionWithAI,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _enhancing
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)),
                              )
                            : const Icon(Icons.auto_awesome, size: 15, color: Color(0xFF4F46E5)),
                        const SizedBox(width: 4),
                        Text(
                          _enhancing ? 'Generating...' : 'Enhance with AI',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF4F46E5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    maxLength: 750,
                    style: GoogleFonts.inter(fontSize: 13.5, color: textPrimary, height: 1.4),
                    decoration: InputDecoration(
                      hintText: 'Elevate your online presence with SocialHive...',
                      hintStyle: GoogleFonts.inter(color: textSecondary, fontSize: 13),
                      border: InputBorder.none,
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      '${_descriptionController.text.length}/750',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Card 2: Contact Information
        _buildSectionCard(
          isDark: isDark,
          cardBgColor: cardBgColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          title: 'Contact Information',
          subtitle: 'How customers can reach and connect with you.',
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 500) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _phoneController,
                              label: 'Phone Number',
                              hint: '07553 496132',
                              icon: Icons.phone_outlined,
                              isDark: isDark,
                              borderColor: borderColor,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildTextField(
                              controller: _websiteController,
                              label: 'Website',
                              hint: 'www.socialhive.pro',
                              icon: Icons.language_outlined,
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
                              controller: _emailController,
                              label: 'Email Address',
                              hint: 'hello@socialhive.pro',
                              icon: Icons.mail_outline,
                              isDark: isDark,
                              borderColor: borderColor,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildTextField(
                              controller: _businessEmailController,
                              label: 'Business Email',
                              hint: 'info@socialhive.pro',
                              icon: Icons.email_outlined,
                              isDark: isDark,
                              borderColor: borderColor,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hint: '07553 496132',
                        icon: Icons.phone_outlined,
                        isDark: isDark,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
                        controller: _websiteController,
                        label: 'Website',
                        hint: 'www.socialhive.pro',
                        icon: Icons.language_outlined,
                        isDark: isDark,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        hint: 'hello@socialhive.pro',
                        icon: Icons.mail_outline,
                        isDark: isDark,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
                        controller: _businessEmailController,
                        label: 'Business Email',
                        hint: 'info@socialhive.pro',
                        icon: Icons.email_outlined,
                        isDark: isDark,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategorySelector(
    bool isDark,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Primary Category',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _showCategorySearchModal(isDark, borderColor, textPrimary, textSecondary),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(Icons.interests_outlined, size: 18, color: textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _categoryController.text.isNotEmpty ? _categoryController.text : 'Marketing consultant',
                    style: GoogleFonts.inter(fontSize: 14, color: textPrimary, fontWeight: FontWeight.w500),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, size: 20, color: textSecondary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'This helps customers find your business on Google.',
          style: GoogleFonts.inter(
            fontSize: 11.5,
            color: textSecondary,
          ),
        ),
      ],
    );
  }

  void _showCategorySearchModal(
    bool isDark,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final searchCtrl = TextEditingController();
    List<Map<String, dynamic>> searchResults = [];
    bool isSearching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 16,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Primary Category',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: searchCtrl,
                    autofocus: true,
                    style: GoogleFonts.inter(fontSize: 14, color: textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search categories (e.g. Marketing, Dentist)...',
                      hintStyle: GoogleFonts.inter(color: textSecondary, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                    ),
                    onChanged: (val) async {
                      if (val.trim().isEmpty) {
                        setModalState(() => searchResults = []);
                        return;
                      }
                      setModalState(() => isSearching = true);
                      final repo = BackendBusinessRepository();
                      final results = await repo.searchCategories(val.trim());
                      setModalState(() {
                        searchResults = results;
                        isSearching = false;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  if (isSearching)
                    const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                  else if (searchResults.isNotEmpty)
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        itemCount: searchResults.length,
                        itemBuilder: (c, idx) {
                          final item = searchResults[idx];
                          final name = item['displayName'] ?? item['name'] ?? '';
                          return ListTile(
                            leading: const Icon(Icons.interests_outlined, size: 18),
                            title: Text(name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                            onTap: () {
                              setState(() {
                                _categoryController.text = name;
                              });
                              Navigator.pop(modalCtx);
                            },
                          );
                        },
                      ),
                    )
                  else ...[
                    Text('Popular Categories', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: textSecondary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'Marketing consultant',
                        'Marketing agency',
                        'Advertising agency',
                        'Internet marketing service',
                        'Consultant',
                        'Software company',
                      ].map((cat) {
                        return ActionChip(
                          label: Text(cat, style: GoogleFonts.inter(fontSize: 12)),
                          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          onPressed: () {
                            setState(() {
                              _categoryController.text = cat;
                            });
                            Navigator.pop(modalCtx);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  // TAB 2: CATEGORIES
  Widget _buildCategoriesTab(bool isDark, Color cardBgColor, Color borderColor, Color textPrimary, Color textSecondary, BusinessProfile? business) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          isDark: isDark,
          cardBgColor: cardBgColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          title: 'Business Categories',
          subtitle: 'Help customers find your business by industry. Add additional categories to increase Google Maps visibility.',
          headerAction: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✨ AI Category Research: Analyzing competitor categories...'), backgroundColor: Color(0xFF4F46E5)),
              );
            },
            icon: const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF4F46E5)),
            label: Text('AI Category Research', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF4F46E5))),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF4F46E5)),
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
                    color: const Color(0xFF4338CA),
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
                  'No additional categories added. Click \'AI Category Research\' or \'+ Add another category\' to increase reach.',
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
          ],
        ),
      ],
    );
  }

  // TAB 3: PHOTOS & LOGOS
  Widget _buildPhotosLogosTab(bool isDark, Color cardBgColor, Color borderColor, Color textPrimary, Color textSecondary) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          isDark: isDark,
          cardBgColor: cardBgColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          title: 'Photos & Logos',
          subtitle: 'Manage how your business appears visually on Google Maps and Search.',
          children: [
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
        ),
      ],
    );
  }

  // TAB 4: BOOKINGS
  Widget _buildBookingsTab(bool isDark, Color cardBgColor, Color borderColor, Color textPrimary, Color textSecondary, BusinessProfile? business) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          isDark: isDark,
          cardBgColor: cardBgColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          title: 'Online Bookings & Appointment Links',
          subtitle: 'Let customers book you directly through custom links to your booking page.',
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
          ],
        ),
      ],
    );
  }

  // TAB 5: SERVICES
  Widget _buildServicesTab(bool isDark, Color cardBgColor, Color borderColor, Color textPrimary, Color textSecondary, BusinessProfile? business) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          isDark: isDark,
          cardBgColor: cardBgColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          title: _categoryController.text.isNotEmpty ? _categoryController.text : 'Marketing consultant',
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
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                    onPressed: () {
                      setState(() {
                        _servicesList.removeAt(i);
                      });
                    },
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
                    backgroundColor: const Color(0xFF4338CA),
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

  // TAB 6: MORE (Products, Address & Hours)
  Widget _buildMoreTab(bool isDark, Color cardBgColor, Color borderColor, Color textPrimary, Color textSecondary, BusinessProfile? business) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Address & Hours
        _buildSectionCard(
          isDark: isDark,
          cardBgColor: cardBgColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          title: 'Storefront Address & Hours',
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
                    hint: 'Bengaluru',
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
                    hint: '560001',
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
            _buildTextField(
              controller: _hoursController,
              label: 'Operating Hours Summary',
              hint: 'Mon - Fri: 9:00 AM - 6:00 PM',
              icon: Icons.schedule_outlined,
              isDark: isDark,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Products Catalogue
        _buildSectionCard(
          isDark: isDark,
          cardBgColor: cardBgColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          title: 'Products Catalogue',
          subtitle: 'Showcase products on your Business Profile to drive leads and purchases.',
          children: [
            if (_loadingProducts)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else if (_productsList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('No products currently listed. Add products to attract buyers directly on Google.', style: GoogleFonts.inter(fontSize: 13, color: textSecondary)),
              )
            else
              for (final prod in _productsList)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.inventory_2_outlined, color: Color(0xFF4F46E5)),
                  title: Text(prod['title'] ?? 'Product', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: Text(prod['description'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
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
    Widget? headerAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
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
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ?headerAction,
            ],
          ),
          const SizedBox(height: 18),
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
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: GoogleFonts.inter(fontSize: 14, color: textPrimary, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: textSecondary, fontSize: 13),
            prefixIcon: Icon(icon, size: 18, color: textSecondary),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          ),
        ),
      ],
    );
  }

  Future<void> _enhanceDescriptionWithAI() async {
    final businessName = _nameController.text.trim();
    final category = _categoryController.text.trim();
    final currentDescription = _descriptionController.text.trim();

    if (businessName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a business name first.')),
      );
      return;
    }

    setState(() => _enhancing = true);
    try {
      final repo = BackendBusinessRepository();
      final enhanced = await repo.enhanceDescription(
        businessName: businessName,
        category: category.isNotEmpty ? category : 'Local Business',
        currentDescription: currentDescription,
      );

      if (mounted && enhanced.isNotEmpty) {
        setState(() {
          _descriptionController.text = enhanced;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Business description enhanced with AI!'),
            backgroundColor: Color(0xFF4F46E5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI Enhancement failed: ${e.toString()}'),
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

  Future<void> _saveProfile(BusinessProfile? current) async {
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

      final baseProfile = current ?? const BusinessProfile(
        id: 'default',
        name: 'SocialHive',
        category: 'Marketing consultant',
        location: 'Assam',
        address: '',
        phone: '07553 496132',
        hoursSummary: '',
        website: 'www.socialhive.pro',
        targetAudience: '',
        brandTone: '',
        postingFrequency: 4,
      );

      final updated = baseProfile.copyWith(
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
