import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/gmb_posts_repository.dart';
import '../../shared/widgets/app_media_picker.dart';
import '../business_flow/providers/active_location_provider.dart';
import '../dashboard/widgets/dashboard_header_bar.dart';
import '../notifications/notification_end_drawer.dart';
import '../shell/providers/shell_nav_provider.dart';

class CreatePostFlowScreen extends ConsumerStatefulWidget {
  const CreatePostFlowScreen({
    super.key,
    this.showScaffold = true,
  });

  final bool showScaffold;

  @override
  ConsumerState<CreatePostFlowScreen> createState() => _CreatePostFlowScreenState();
}

class _CreatePostFlowScreenState extends ConsumerState<CreatePostFlowScreen> {
  // Topic type: STANDARD, EVENT, OFFER
  String _topicType = 'STANDARD';

  // Common fields
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _mediaUrlController = TextEditingController();

  // CTA
  String _actionType = 'NONE'; // NONE, BOOK, ORDER, SHOP, LEARN_MORE, SIGN_UP, CALL
  final TextEditingController _actionUrlController = TextEditingController();

  // Event / Offer specific
  final TextEditingController _titleController = TextEditingController();
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;

  // Offer specific
  final TextEditingController _couponCodeController = TextEditingController();
  final TextEditingController _redeemUrlController = TextEditingController();
  final TextEditingController _termsController = TextEditingController();

  // Scheduling
  bool _isScheduled = false;
  DateTime? _scheduleDate;
  TimeOfDay? _scheduleTime;

  bool _busy = false;
  bool _showUrlInput = false;

  @override
  void dispose() {
    _summaryController.dispose();
    _mediaUrlController.dispose();
    _actionUrlController.dispose();
    _titleController.dispose();
    _couponCodeController.dispose();
    _redeemUrlController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  void _onGenerateAIPreset(String tone) async {
    setState(() => _busy = true);
    final activeLoc = ref.read(activeLocationProvider).activeLocation;
    final name = activeLoc?.name ?? 'our business';
    final category = activeLoc?.category ?? 'Services';

    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      if (_topicType == 'OFFER') {
        _titleController.text = "Special 20% Discount on $category!";
        _summaryController.text = "Enjoy 20% off all $category services at $name this week! Limited time offer — show this post at checkout to redeem.\n\n#SpecialOffer #Discount #$category #LocalBusiness";
        _couponCodeController.text = "SAVE20";
        _actionType = 'LEARN_MORE';
      } else if (_topicType == 'EVENT') {
        _titleController.text = "$name Community Showcase";
        _summaryController.text = "Join us at $name for our upcoming customer event! Meet the team, enjoy refreshments, and experience our latest $category services firsthand.\n\n#CommunityEvent #JoinUs #$category";
        _actionType = 'BOOK';
      } else {
        if (tone == 'promo') {
          _summaryController.text = "Looking for top-rated $category in your area? $name provides premium results tailored to your exact needs. Book your consultation today!\n\n#Local$category #CustomerFirst #$name";
          _actionType = 'BOOK';
        } else if (tone == 'seo') {
          _summaryController.text = "Did you know $name is recognized for delivering premier $category? We specialize in reliable, fast, and high-quality solutions for our local community.\n\nVisit us today or tap below to learn more! #LocalExperts #$category";
          _actionType = 'LEARN_MORE';
        } else {
          _summaryController.text = "Exciting updates from $name! We are proud to deliver top-quality $category tailored for our customers. Visit us today or tap below to learn more!\n\n#BusinessUpdate #LocalService";
        }
      }
      setState(() => _busy = false);
    }
  }

  Future<void> _pickDate({required bool isStart, required bool isSchedule}) async {
    final now = DateTime.now();
    final initial = isSchedule
        ? (_scheduleDate ?? now)
        : isStart
            ? (_startDate ?? now)
            : (_endDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isSchedule) {
          _scheduleDate = picked;
        } else if (isStart) {
          _startDate = picked;
          if (_endDate == null || _endDate!.isBefore(picked)) {
            _endDate = picked;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickTime({required bool isStart, required bool isSchedule}) async {
    final initial = isSchedule
        ? (_scheduleTime ?? TimeOfDay.now())
        : isStart
            ? (_startTime ?? const TimeOfDay(hour: 9, minute: 0))
            : (_endTime ?? const TimeOfDay(hour: 17, minute: 0));

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked != null) {
      setState(() {
        if (isSchedule) {
          _scheduleTime = picked;
        } else if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Map<String, dynamic>? _buildGMBDate(DateTime? dt) {
    if (dt == null) return null;
    return {
      'year': dt.year,
      'month': dt.month,
      'day': dt.day,
    };
  }

  Map<String, dynamic>? _buildGMBTime(TimeOfDay? time) {
    if (time == null) return null;
    return {
      'hours': time.hour,
      'minutes': time.minute,
      'seconds': 0,
      'nanos': 0,
    };
  }

  String? _buildISOString(DateTime? date, TimeOfDay? time) {
    if (date == null) return null;
    final t = time ?? const TimeOfDay(hour: 9, minute: 0);
    final dt = DateTime(date.year, date.month, date.day, t.hour, t.minute);
    return dt.toUtc().toIso8601String();
  }

  void _publishPost() async {
    final summary = _summaryController.text.trim();
    if (summary.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post description is required.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (_topicType == 'EVENT' || _topicType == 'OFFER') {
      if (_titleController.text.trim().isEmpty || _startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Title, Start Date, and End Date are required for Events and Offers.'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
        return;
      }
    }

    if (_actionType != 'NONE' && _actionType != 'CALL' && _actionUrlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Button Link URL is required for the selected button action.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (_isScheduled && (_scheduleDate == null || _scheduleTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both Date and Time for scheduled post.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() => _busy = true);

    try {
      final activeLoc = ref.read(activeLocationProvider).activeLocation;
      final locationName = activeLoc?.name ?? activeLoc?.id ?? '';

      Map<String, dynamic>? scheduleObj;
      if (_startDate != null && _endDate != null) {
        scheduleObj = {
          'startDate': _buildGMBDate(_startDate),
          'endDate': _buildGMBDate(_endDate),
          if (_startTime != null) 'startTime': _buildGMBTime(_startTime),
          if (_endTime != null) 'endTime': _buildGMBTime(_endTime),
        };
      }

      final postRequest = GMBPostRequest(
        locationName: locationName,
        summary: summary,
        topicType: _topicType,
        callToActionType: _actionType,
        callToActionUrl: _actionUrlController.text.trim(),
        mediaUrl: _mediaUrlController.text.trim(),
        eventTitle: _titleController.text.trim(),
        eventSchedule: scheduleObj,
        couponCode: _couponCodeController.text.trim(),
        redeemUrl: _redeemUrlController.text.trim(),
        termsConditions: _termsController.text.trim(),
        scheduledTime: _isScheduled ? _buildISOString(_scheduleDate, _scheduleTime) : null,
      );

      final repo = GMBPostsRepository();
      final success = await repo.createPost(postRequest);

      if (mounted) {
        setState(() => _busy = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isScheduled ? '✨ Post scheduled successfully!' : '🚀 Post published directly to Google Business Profile!',
              ),
              backgroundColor: const Color(0xFF16A34A),
            ),
          );
          // Clear form
          _summaryController.clear();
          _mediaUrlController.clear();
          _actionUrlController.clear();
          _titleController.clear();
          _couponCodeController.clear();
          _redeemUrlController.clear();
          _termsController.clear();
          setState(() {
            _actionType = 'NONE';
            _isScheduled = false;
            _startDate = null;
            _startTime = null;
            _endDate = null;
            _endTime = null;
            _scheduleDate = null;
            _scheduleTime = null;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to publish post to GMB. Please verify your connection.'),
              backgroundColor: Color(0xFFDC2626),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeLocState = ref.watch(activeLocationProvider);
    final activeLocation = activeLocState.activeLocation;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E1B4B);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final bgGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF0B0F19)],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0F4FF), Color(0xFFFAF8FF), Color(0xFFFFFFFF)],
            stops: [0.0, 0.35, 1.0],
          );

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFFAF8FF),
      endDrawer: const NotificationEndDrawer(),
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
                child: DashboardHeaderBar(
                  title: 'Create Post',
                  subtitle: activeLocation?.name ?? 'SocialHive',
                  showSparkle: true,
                  showBackButton: true,
                  onBack: () => ref.handleSmartBack(context),
                  onOpenNotifications: () {
                    Scaffold.maybeOf(context)?.openEndDrawer();
                  },
                ),
              ),
              const SizedBox(height: 6),

              // Scrollable Form Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location Header Banner
                      if (activeLocation != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: cardBgColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF312E81).withValues(alpha: 0.5) : const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.storefront_rounded, color: Color(0xFF4F46E5), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      activeLocation.name,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Publishing directly to Google Search & Maps',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.5) : const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Live API',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFF16A34A),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Segmented Topic Tabs
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: _buildTopicSegment('STANDARD', 'Update', Icons.article_rounded, isDark, textPrimary, textSecondary)),
                            Expanded(child: _buildTopicSegment('OFFER', 'Offer', Icons.local_offer_rounded, isDark, textPrimary, textSecondary)),
                            Expanded(child: _buildTopicSegment('EVENT', 'Event', Icons.event_rounded, isDark, textPrimary, textSecondary)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 1. Post Content & AI Assist Card
                      _buildCardContainer(
                        isDark: isDark,
                        cardBgColor: cardBgColor,
                        borderColor: borderColor,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Post Content *',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                ),
                              ),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: _busy ? null : () => _onGenerateAIPreset('update'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF312E81).withValues(alpha: 0.5) : const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFF4F46E5)),
                                      const SizedBox(width: 5),
                                      Text(
                                        'AI Assist',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF4F46E5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // AI Preset Quick Chips
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _buildAIChip(Icons.local_fire_department_rounded, 'Promo Boost', () => _onGenerateAIPreset('promo'), isDark, borderColor, textSecondary),
                              _buildAIChip(Icons.trending_up_rounded, 'SEO Boost', () => _onGenerateAIPreset('seo'), isDark, borderColor, textSecondary),
                              _buildAIChip(Icons.event_rounded, 'Event Announcement', () => _onGenerateAIPreset('event'), isDark, borderColor, textSecondary),
                            ],
                          ),
                          const SizedBox(height: 10),

                          TextField(
                            controller: _summaryController,
                            minLines: 5,
                            maxLines: 10,
                            maxLength: 1500,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: textPrimary, height: 1.45),
                            decoration: InputDecoration(
                              hintText: "Write your Google Business post update, promo, or event details...",
                              hintStyle: GoogleFonts.plusJakartaSans(color: textSecondary.withValues(alpha: 0.7), fontSize: 13),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                              counterText: '${_summaryController.text.length}/1500',
                              counterStyle: GoogleFonts.plusJakartaSans(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w600),
                            ),
                            onChanged: (val) => setState(() {}),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 2. Media Attachment Card
                      _buildCardContainer(
                        isDark: isDark,
                        cardBgColor: cardBgColor,
                        borderColor: borderColor,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Media Attachment',
                                style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: textPrimary),
                              ),
                              TextButton(
                                onPressed: () => setState(() => _showUrlInput = !_showUrlInput),
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 24)),
                                child: Text(
                                  _showUrlInput ? 'Use Media Picker' : 'Enter URL',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF4F46E5)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          if (_showUrlInput) ...[
                            _buildInputField(
                              controller: _mediaUrlController,
                              label: 'Photo / Video URL',
                              hint: 'https://example.com/photo.jpg',
                              icon: Icons.link_rounded,
                              isDark: isDark,
                              borderColor: borderColor,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                            ),
                          ] else ...[
                            AppMediaPicker(
                              initialUrl: _mediaUrlController.text,
                              label: 'Select Media',
                              subtitle: 'Pick high-quality photo or video from gallery',
                              onMediaSelected: (pathOrUrl) {
                                setState(() {
                                  _mediaUrlController.text = pathOrUrl;
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 3. Event / Offer Specific Details
                      if (_topicType == 'EVENT' || _topicType == 'OFFER') ...[
                        _buildCardContainer(
                          isDark: isDark,
                          cardBgColor: cardBgColor,
                          borderColor: borderColor,
                          children: [
                            Text(
                              _topicType == 'EVENT' ? 'Event Details' : 'Offer Details',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: textPrimary),
                            ),
                            const SizedBox(height: 12),
                            _buildInputField(
                              controller: _titleController,
                              label: 'Title *',
                              hint: _topicType == 'EVENT' ? 'e.g. Grand Opening Showcase' : 'e.g. 20% Off Storewide',
                              icon: Icons.title_rounded,
                              isDark: isDark,
                              borderColor: borderColor,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildPickerTile(
                                    label: 'Start Date *',
                                    value: _startDate != null ? DateFormat('MMM dd, yyyy').format(_startDate!) : 'Select Date',
                                    icon: Icons.calendar_today_rounded,
                                    onTap: () => _pickDate(isStart: true, isSchedule: false),
                                    isDark: isDark,
                                    borderColor: borderColor,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildPickerTile(
                                    label: 'Start Time',
                                    value: _startTime != null ? _startTime!.format(context) : '09:00 AM',
                                    icon: Icons.access_time_rounded,
                                    onTap: () => _pickTime(isStart: true, isSchedule: false),
                                    isDark: isDark,
                                    borderColor: borderColor,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildPickerTile(
                                    label: 'End Date *',
                                    value: _endDate != null ? DateFormat('MMM dd, yyyy').format(_endDate!) : 'Select Date',
                                    icon: Icons.calendar_today_rounded,
                                    onTap: () => _pickDate(isStart: false, isSchedule: false),
                                    isDark: isDark,
                                    borderColor: borderColor,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildPickerTile(
                                    label: 'End Time',
                                    value: _endTime != null ? _endTime!.format(context) : '05:00 PM',
                                    icon: Icons.access_time_rounded,
                                    onTap: () => _pickTime(isStart: false, isSchedule: false),
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
                        const SizedBox(height: 14),
                      ],

                      // 4. Offer Extended Details (if Offer)
                      if (_topicType == 'OFFER') ...[
                        _buildCardContainer(
                          isDark: isDark,
                          cardBgColor: cardBgColor,
                          borderColor: borderColor,
                          children: [
                            Text(
                              'Offer Redemption Details (Optional)',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: textPrimary),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInputField(
                                    controller: _couponCodeController,
                                    label: 'Coupon Code',
                                    hint: 'e.g. SAVE20',
                                    icon: Icons.confirmation_number_outlined,
                                    isDark: isDark,
                                    borderColor: borderColor,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildInputField(
                                    controller: _redeemUrlController,
                                    label: 'Redeem URL',
                                    hint: 'https://...',
                                    icon: Icons.shopping_bag_outlined,
                                    isDark: isDark,
                                    borderColor: borderColor,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildInputField(
                              controller: _termsController,
                              label: 'Terms & Conditions',
                              hint: 'Valid until supplies last. Cannot be combined with other offers.',
                              icon: Icons.gavel_rounded,
                              isDark: isDark,
                              borderColor: borderColor,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                      ],

                      // 5. Call to Action Button Selector
                      _buildCardContainer(
                        isDark: isDark,
                        cardBgColor: cardBgColor,
                        borderColor: borderColor,
                        children: [
                          Text(
                            'Add Action Button (Optional)',
                            style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: textPrimary),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            initialValue: _actionType,
                            dropdownColor: cardBgColor,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: textPrimary, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'NONE', child: Text('No Action Button')),
                              DropdownMenuItem(value: 'BOOK', child: Text('Book Appointment')),
                              DropdownMenuItem(value: 'ORDER', child: Text('Order Online')),
                              DropdownMenuItem(value: 'SHOP', child: Text('Buy Now / Shop')),
                              DropdownMenuItem(value: 'LEARN_MORE', child: Text('Learn More')),
                              DropdownMenuItem(value: 'SIGN_UP', child: Text('Sign Up')),
                              DropdownMenuItem(value: 'CALL', child: Text('Call Now')),
                            ],
                            onChanged: (val) => setState(() => _actionType = val ?? 'NONE'),
                          ),
                          if (_actionType != 'NONE' && _actionType != 'CALL') ...[
                            const SizedBox(height: 12),
                            _buildInputField(
                              controller: _actionUrlController,
                              label: 'Destination Link URL *',
                              hint: 'https://example.com/booking-page',
                              icon: Icons.link_rounded,
                              isDark: isDark,
                              borderColor: borderColor,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 6. Schedule Card
                      _buildCardContainer(
                        isDark: isDark,
                        cardBgColor: cardBgColor,
                        borderColor: borderColor,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Schedule Post',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Set future date & time for auto-publishing',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: textSecondary),
                                  ),
                                ],
                              ),
                              Switch(
                                value: _isScheduled,
                                activeThumbColor: const Color(0xFF4F46E5),
                                activeTrackColor: const Color(0xFFC7D2FE),
                                onChanged: (val) => setState(() => _isScheduled = val),
                              ),
                            ],
                          ),
                          if (_isScheduled) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildPickerTile(
                                    label: 'Publish Date *',
                                    value: _scheduleDate != null ? DateFormat('MMM dd, yyyy').format(_scheduleDate!) : 'Select Date',
                                    icon: Icons.calendar_month_rounded,
                                    onTap: () => _pickDate(isStart: false, isSchedule: true),
                                    isDark: isDark,
                                    borderColor: borderColor,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildPickerTile(
                                    label: 'Publish Time *',
                                    value: _scheduleTime != null ? _scheduleTime!.format(context) : 'Select Time',
                                    icon: Icons.access_time_rounded,
                                    onTap: () => _pickTime(isStart: false, isSchedule: true),
                                    isDark: isDark,
                                    borderColor: borderColor,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Bottom Sticky Publish Bar
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : _publishPost,
                    icon: _busy
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Icon(_isScheduled ? Icons.schedule_rounded : Icons.send_rounded, size: 18),
                    label: Text(
                      _busy
                          ? (_isScheduled ? 'Scheduling...' : 'Publishing...')
                          : (_isScheduled ? 'Schedule Post' : 'Publish Post to GMB'),
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIChip(IconData icon, String label, VoidCallback onTap, bool isDark, Color borderColor, Color textSecondary) {
    return GestureDetector(
      onTap: _busy ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: const Color(0xFF4F46E5)),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicSegment(String type, String label, IconData icon, bool isDark, Color textPrimary, Color textSecondary) {
    final isSelected = _topicType == type;
    return GestureDetector(
      onTap: () => setState(() => _topicType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardContainer({
    required bool isDark,
    required Color cardBgColor,
    required Color borderColor,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInputField({
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
          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(color: textSecondary.withValues(alpha: 0.6), fontSize: 12.5),
            prefixIcon: Icon(icon, size: 18, color: textSecondary),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildPickerTile({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
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
          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: textPrimary, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
