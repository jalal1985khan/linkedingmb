import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../shared/widgets/app_media_picker.dart';
import '../dashboard/dashboard_controller.dart';
import '../dashboard/widgets/dashboard_header_bar.dart';
import '../notifications/notification_end_drawer.dart';
import '../scheduler/scheduler_screen.dart';

class PostEditorScreen extends ConsumerStatefulWidget {
  const PostEditorScreen({
    super.key,
    required this.postId,
  });

  final String postId;

  @override
  ConsumerState<PostEditorScreen> createState() => _PostEditorScreenState();
}

class _PostEditorScreenState extends ConsumerState<PostEditorScreen> {
  GlobalKey<ScaffoldState>? _scaffoldKey;
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _mediaUrlController = TextEditingController();
  final _actionUrlController = TextEditingController();

  // Offer / Event Specific
  final _couponCodeController = TextEditingController();
  final _termsController = TextEditingController();

  String _topicType = 'STANDARD';
  String _actionType = 'LEARN_MORE';
  DateTime? _startDate;
  DateTime? _endDate;

  bool _loading = true;
  bool _saving = false;

  final List<String> _actionTypes = [
    'NONE',
    'BOOK',
    'ORDER',
    'SHOP',
    'LEARN_MORE',
    'SIGN_UP',
    'CALL',
  ];

  @override
  void initState() {
    super.initState();
    _scaffoldKey ??= GlobalKey<ScaffoldState>();
    _loadPost();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _mediaUrlController.dispose();
    _actionUrlController.dispose();
    _couponCodeController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldKey = _scaffoldKey ??= GlobalKey<ScaffoldState>();

    // Design System Tokens
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
      key: scaffoldKey,
      backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFFAF8FF),
      endDrawer: const NotificationEndDrawer(),
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // 1. Standard Unified DashboardHeaderBar
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
                child: DashboardHeaderBar(
                  title: 'Edit Post',
                  subtitle: 'Update GMB post content & scheduling',
                  showSparkle: true,
                  showBackButton: true,
                  onBack: () => Navigator.of(context).maybePop(),
                  onOpenNotifications: () {
                    if (scaffoldKey.currentState != null) {
                      scaffoldKey.currentState!.openEndDrawer();
                    } else {
                      Scaffold.maybeOf(context)?.openEndDrawer();
                    }
                  },
                ),
              ),

              // 2. Main Scrollable Form Content
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Topic Type Segmented Cards
                            _buildTopicSelector(isDark, cardBgColor, borderColor, textPrimary, textSecondary),

                            const SizedBox(height: 16),

                            // Main Content Card
                            _buildContentCard(isDark, cardBgColor, borderColor, textPrimary, textSecondary),

                            const SizedBox(height: 16),

                            // Call To Action Card
                            _buildCallToActionCard(isDark, cardBgColor, borderColor, textPrimary, textSecondary),

                            if (_topicType == 'EVENT' || _topicType == 'OFFER') ...[
                              const SizedBox(height: 16),
                              _buildEventOfferCard(isDark, cardBgColor, borderColor, textPrimary, textSecondary),
                            ],
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _loading
          ? null
          : Container(
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
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SchedulerScreen(postId: widget.postId),
                            ),
                          ),
                          icon: const Icon(Icons.schedule_rounded, size: 18),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Schedule',
                              maxLines: 1,
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textPrimary,
                            side: BorderSide(color: borderColor),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : _saveDraft,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.save_rounded, size: 18),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _saving ? 'Saving...' : 'Save Changes',
                              maxLines: 1,
                              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
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

  Widget _buildTopicSelector(bool isDark, Color cardBgColor, Color borderColor, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.category_rounded, size: 13, color: Color(0xFF4F46E5)),
              ),
              const SizedBox(width: 8),
              Text(
                'POST TOPIC TYPE',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF6366F1),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTopicOption('STANDARD', 'Update', Icons.article_outlined, isDark, borderColor),
              const SizedBox(width: 8),
              _buildTopicOption('OFFER', 'Offer', Icons.local_offer_outlined, isDark, borderColor),
              const SizedBox(width: 8),
              _buildTopicOption('EVENT', 'Event', Icons.event_outlined, isDark, borderColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopicOption(String key, String label, IconData icon, bool isDark, Color borderColor) {
    final isSelected = _topicType == key;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _topicType = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF312E81).withValues(alpha: 0.6) : const Color(0xFFEEF2FF))
                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF4F46E5) : borderColor,
              width: isSelected ? 1.8 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: isSelected ? const Color(0xFF4F46E5) : (isDark ? Colors.white60 : Colors.grey.shade600)),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? const Color(0xFF4F46E5) : (isDark ? Colors.white70 : Colors.grey.shade700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentCard(bool isDark, Color cardBgColor, Color borderColor, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Headline / Title',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _titleController,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textPrimary, fontWeight: FontWeight.w600),
            decoration: _inputDecoration('e.g. Special Weekend Announcement', isDark, borderColor, textSecondary),
          ),
          const SizedBox(height: 16),
          Text(
            'Post Summary / Description',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _summaryController,
            minLines: 7,
            maxLines: 12,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textPrimary, height: 1.5),
            decoration: _inputDecoration('Write detailed update or promotional text...', isDark, borderColor, textSecondary),
          ),
          const SizedBox(height: 16),
          AppMediaPicker(
            initialUrl: _mediaUrlController.text,
            label: 'Post Media / Image',
            subtitle: 'Select an image from gallery, take a photo, or provide a URL.',
            onMediaSelected: (pathOrUrl) {
              setState(() {
                _mediaUrlController.text = pathOrUrl;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCallToActionCard(bool isDark, Color cardBgColor, Color borderColor, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.touch_app_rounded, size: 13, color: Color(0xFF4F46E5)),
              ),
              const SizedBox(width: 8),
              Text(
                'CALL TO ACTION BUTTON',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF6366F1),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _actionType,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
            decoration: _inputDecoration('Select Button Action', isDark, borderColor, textSecondary),
            dropdownColor: cardBgColor,
            items: [
              for (final action in _actionTypes)
                DropdownMenuItem(
                  value: action,
                  child: Text(
                    action == 'NONE' ? 'No Button' : action.replaceAll('_', ' '),
                    style: GoogleFonts.plusJakartaSans(color: textPrimary, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
            onChanged: (val) => setState(() => _actionType = val ?? 'NONE'),
          ),
          if (_actionType != 'NONE' && _actionType != 'CALL') ...[
            const SizedBox(height: 14),
            Text(
              'Action Destination URL',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _actionUrlController,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textPrimary),
              decoration: _inputDecoration('https://www.socialhive.pro/signup', isDark, borderColor, textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventOfferCard(bool isDark, Color cardBgColor, Color borderColor, Color textPrimary, Color textSecondary) {
    final dateFormat = DateFormat('MMM d, yyyy');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _topicType == 'OFFER' ? 'OFFER DETAILS' : 'EVENT SCHEDULE',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF6366F1),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => _startDate = picked);
                  },
                  icon: const Icon(Icons.calendar_month_outlined, size: 16),
                  label: Text(
                    _startDate != null ? dateFormat.format(_startDate!) : 'Start Date',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textPrimary,
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => _endDate = picked);
                  },
                  icon: const Icon(Icons.event_available_outlined, size: 16),
                  label: Text(
                    _endDate != null ? dateFormat.format(_endDate!) : 'End Date',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textPrimary,
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          if (_topicType == 'OFFER') ...[
            const SizedBox(height: 14),
            Text(
              'Coupon Code (Optional)',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _couponCodeController,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textPrimary),
              decoration: _inputDecoration('e.g. SAVE20', isDark, borderColor, textSecondary),
            ),
            const SizedBox(height: 14),
            Text(
              'Terms & Conditions',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _termsController,
              maxLines: 2,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textPrimary),
              decoration: _inputDecoration('e.g. Valid in-store only.', isDark, borderColor, textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, bool isDark, Color borderColor, Color textSecondary) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(color: textSecondary, fontSize: 13),
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
      ),
    );
  }

  Future<void> _loadPost() async {
    final post = await ref.read(postRepositoryProvider).getPostById(widget.postId);
    if (!mounted) return;

    if (post == null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post not found')),
      );
      return;
    }

    _titleController.text = post.title;
    _summaryController.text = post.preview;
    _topicType = post.contentType.toUpperCase();
    if (_topicType != 'STANDARD' && _topicType != 'OFFER' && _topicType != 'EVENT') {
      _topicType = 'STANDARD';
    }

    setState(() => _loading = false);
  }

  Future<void> _saveDraft() async {
    setState(() => _saving = true);
    try {
      await ref.read(postRepositoryProvider).updatePostDraft(
            postId: widget.postId,
            title: _titleController.text.trim(),
            preview: _summaryController.text.trim(),
            contentType: _topicType,
          );
      ref.invalidate(dashboardDataProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Post changes saved successfully!',
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save changes: ${e.toString()}',
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
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
