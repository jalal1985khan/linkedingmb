import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/gmb_posts_repository.dart';
import '../business_flow/providers/active_location_provider.dart';

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

  void _onGenerateAIAssist() async {
    setState(() => _busy = true);
    final activeLoc = ref.read(activeLocationProvider).activeLocation;
    final name = activeLoc?.name ?? 'our business';
    final category = activeLoc?.category ?? 'Services';

    await Future.delayed(const Duration(milliseconds: 1200));

    if (mounted) {
      if (_topicType == 'OFFER') {
        _titleController.text = "Special 20% Discount!";
        _summaryController.text = "Enjoy 20% off all $category services at $name this week! Limited time offer — show this post at checkout to redeem. ✨ #SpecialOffer #Discount";
        _couponCodeController.text = "SAVE20";
      } else if (_topicType == 'EVENT') {
        _titleController.text = "$name Community Event";
        _summaryController.text = "Join us at $name for our upcoming customer appreciation event! Meet the team, enjoy refreshments, and experience our latest offerings. 🎉 #CommunityEvent #JoinUs";
      } else {
        _summaryController.text = "Exciting updates from $name! We are proud to deliver top-quality $category tailored for our customers. Visit us today or tap below to learn more! 🚀 #BusinessUpdate #LocalService";
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
        const SnackBar(content: Text('Post description is required.')),
      );
      return;
    }

    if (_topicType == 'EVENT' || _topicType == 'OFFER') {
      if (_titleController.text.trim().isEmpty || _startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Title, Start Date, and End Date are required for Events and Offers.')),
        );
        return;
      }
    }

    if (_actionType != 'NONE' && _actionType != 'CALL' && _actionUrlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Button Link is required for the selected button type.')),
      );
      return;
    }

    if (_isScheduled && (_scheduleDate == null || _scheduleTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both Date and Time for scheduled post.')),
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
                _isScheduled ? 'Post scheduled successfully!' : 'Post published to Google Business Profile!',
              ),
              backgroundColor: AppColors.success,
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
              backgroundColor: AppColors.error,
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
            backgroundColor: AppColors.error,
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

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final body = SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location Header Banner
            if (activeLocation != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.storefront_outlined, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activeLocation.name,
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Publishing directly to Google Search & Maps',
                            style: GoogleFonts.inter(fontSize: 11, color: textSecondary),
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
                color: cardBgColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildTopicSegment('STANDARD', 'Update', Icons.article_outlined, isDark, textPrimary, textSecondary)),
                  Expanded(child: _buildTopicSegment('OFFER', 'Offer', Icons.local_offer_outlined, isDark, textPrimary, textSecondary)),
                  Expanded(child: _buildTopicSegment('EVENT', 'Event', Icons.event_outlined, isDark, textPrimary, textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 1. Media Upload Box & Photo URL Fallback
            _buildCardContainer(
              isDark: isDark,
              cardBgColor: cardBgColor,
              borderColor: borderColor,
              children: [
                Text('Media Attachment', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary)),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, style: BorderStyle.solid),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.add_photo_alternate_outlined, size: 36, color: AppColors.primary),
                      const SizedBox(height: 8),
                      Text('Photos & Videos', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                      const SizedBox(height: 4),
                      Text('Provide an image or video URL to display on Google', style: GoogleFonts.inter(fontSize: 12, color: textSecondary), textAlign: TextAlign.center),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildInputField(
                  controller: _mediaUrlController,
                  label: 'Photo / Video URL',
                  hint: 'https://example.com/image.jpg',
                  icon: Icons.link_outlined,
                  isDark: isDark,
                  borderColor: borderColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. Event or Offer Specific Fields
            if (_topicType == 'EVENT' || _topicType == 'OFFER') ...[
              _buildCardContainer(
                isDark: isDark,
                cardBgColor: cardBgColor,
                borderColor: borderColor,
                children: [
                  Text(
                    _topicType == 'EVENT' ? 'Event Details' : 'Offer Details',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                  const SizedBox(height: 12),
                  _buildInputField(
                    controller: _titleController,
                    label: 'Title *',
                    hint: _topicType == 'EVENT' ? 'e.g. Grand Re-Opening Party' : 'e.g. 20% Off Storewide',
                    icon: Icons.title_outlined,
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
                          icon: Icons.calendar_today_outlined,
                          onTap: () => _pickDate(isStart: true, isSchedule: false),
                          isDark: isDark,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPickerTile(
                          label: 'Start Time',
                          value: _startTime != null ? _startTime!.format(context) : 'Select Time',
                          icon: Icons.access_time_outlined,
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
                          icon: Icons.calendar_today_outlined,
                          onTap: () => _pickDate(isStart: false, isSchedule: false),
                          isDark: isDark,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPickerTile(
                          label: 'End Time',
                          value: _endTime != null ? _endTime!.format(context) : 'Select Time',
                          icon: Icons.access_time_outlined,
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
              const SizedBox(height: 16),
            ],

            // 3. Main Description / Content Card
            _buildCardContainer(
              isDark: isDark,
              cardBgColor: cardBgColor,
              borderColor: borderColor,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Post Content *', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary)),
                    TextButton.icon(
                      onPressed: _busy ? null : _onGenerateAIAssist,
                      icon: const Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                      label: Text('AI Assist', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _summaryController,
                  maxLines: 5,
                  maxLength: 1500,
                  style: GoogleFonts.inter(fontSize: 14, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: "Write your Google Business post update, promo, or event details...",
                    hintStyle: GoogleFonts.inter(color: textSecondary, fontSize: 13),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                  ),
                  onChanged: (val) => setState(() {}),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. Offer Extended Details (if Offer)
            if (_topicType == 'OFFER') ...[
              _buildCardContainer(
                isDark: isDark,
                cardBgColor: cardBgColor,
                borderColor: borderColor,
                children: [
                  Text('Offer Redemption Details (Optional)', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary)),
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
                      const SizedBox(width: 12),
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
                    icon: Icons.gavel_outlined,
                    isDark: isDark,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // 5. Call to Action Button Selector
            _buildCardContainer(
              isDark: isDark,
              cardBgColor: cardBgColor,
              borderColor: borderColor,
              children: [
                Text('Add Action Button (Optional)', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary)),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _actionType,
                  dropdownColor: cardBgColor,
                  style: GoogleFonts.inter(fontSize: 14, color: textPrimary),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'NONE', child: Text('None')),
                    DropdownMenuItem(value: 'BOOK', child: Text('Book')),
                    DropdownMenuItem(value: 'ORDER', child: Text('Order online')),
                    DropdownMenuItem(value: 'SHOP', child: Text('Buy')),
                    DropdownMenuItem(value: 'LEARN_MORE', child: Text('Learn more')),
                    DropdownMenuItem(value: 'SIGN_UP', child: Text('Sign up')),
                    DropdownMenuItem(value: 'CALL', child: Text('Call now')),
                  ],
                  onChanged: (val) => setState(() => _actionType = val ?? 'NONE'),
                ),
                if (_actionType != 'NONE' && _actionType != 'CALL') ...[
                  const SizedBox(height: 12),
                  _buildInputField(
                    controller: _actionUrlController,
                    label: 'Button Link *',
                    hint: 'https://example.com/target-page',
                    icon: Icons.link_outlined,
                    isDark: isDark,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

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
                        Text('Schedule Post', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary)),
                        Text('Set future date & time for auto-publishing', style: GoogleFonts.inter(fontSize: 12, color: textSecondary)),
                      ],
                    ),
                    Switch(
                      value: _isScheduled,
                      activeTrackColor: AppColors.primary,
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
                          icon: Icons.calendar_month_outlined,
                          onTap: () => _pickDate(isStart: false, isSchedule: true),
                          isDark: isDark,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPickerTile(
                          label: 'Publish Time *',
                          value: _scheduleTime != null ? _scheduleTime!.format(context) : 'Select Time',
                          icon: Icons.access_time_outlined,
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
    );

    final scaffoldContent = Scaffold(
      backgroundColor: bgColor,
      appBar: widget.showScaffold
          ? AppBar(
              backgroundColor: cardBgColor,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: Icon(Icons.close_rounded, color: textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                'Create Post',
                style: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              centerTitle: true,
            )
          : null,
      body: body,
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
              onPressed: _busy ? null : _publishPost,
              icon: _busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(_isScheduled ? Icons.schedule_outlined : Icons.send_rounded, size: 18),
              label: Text(
                _busy
                    ? (_isScheduled ? 'Scheduling...' : 'Publishing...')
                    : (_isScheduled ? 'Schedule Post' : 'Publish Post to GMB'),
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
    );

    return scaffoldContent;
  }

  Widget _buildTopicSegment(String type, String label, IconData icon, bool isDark, Color textPrimary, Color textSecondary) {
    final isSelected = _topicType == type;
    return GestureDetector(
      onTap: () => setState(() => _topicType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
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
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
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
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
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
                    style: GoogleFonts.inter(fontSize: 13, color: textPrimary, fontWeight: FontWeight.w500),
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
