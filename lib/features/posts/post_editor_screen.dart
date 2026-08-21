import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_media_picker.dart';
import '../dashboard/dashboard_controller.dart';
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
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Edit Post',
          style: GoogleFonts.inter(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
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

                  const SizedBox(height: 24),
                ],
              ),
            ),
      bottomNavigationBar: _loading
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
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
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SchedulerScreen(postId: widget.postId),
                          ),
                        ),
                        icon: const Icon(Icons.schedule_rounded, size: 18),
                        label: Text('Schedule', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textPrimary,
                          side: BorderSide(color: borderColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _saveDraft,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save_rounded, size: 18),
                        label: Text(
                          _saving ? 'Saving...' : 'Save Changes',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'POST TOPIC TYPE',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: textSecondary, letterSpacing: 0.5),
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
                ? AppColors.primary.withValues(alpha: 0.12)
                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : borderColor,
              width: isSelected ? 1.8 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: isSelected ? AppColors.primary : Colors.grey),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? AppColors.primary : Colors.grey[600],
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Headline / Title',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _titleController,
            style: GoogleFonts.inter(fontSize: 14, color: textPrimary),
            decoration: _inputDecoration('e.g. Special Weekend Announcement', isDark, borderColor, textSecondary),
          ),
          const SizedBox(height: 16),
          Text(
            'Post Summary / Description',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _summaryController,
            minLines: 7,
            maxLines: 12,
            style: GoogleFonts.inter(fontSize: 14, color: textPrimary, height: 1.5),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CALL TO ACTION BUTTON',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: textSecondary, letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _actionType,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
            decoration: _inputDecoration('Select Button Action', isDark, borderColor, textSecondary),
            dropdownColor: cardBgColor,
            items: [
              for (final action in _actionTypes)
                DropdownMenuItem(
                  value: action,
                  child: Text(
                    action == 'NONE' ? 'No Button' : action.replaceAll('_', ' '),
                    style: GoogleFonts.inter(color: textPrimary),
                  ),
                ),
            ],
            onChanged: (val) => setState(() => _actionType = val ?? 'NONE'),
          ),
          if (_actionType != 'NONE' && _actionType != 'CALL') ...[
            const SizedBox(height: 14),
            Text(
              'Action Destination URL',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _actionUrlController,
              style: GoogleFonts.inter(fontSize: 14, color: textPrimary),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _topicType == 'OFFER' ? 'OFFER DETAILS' : 'EVENT SCHEDULE',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: textSecondary, letterSpacing: 0.5),
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
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
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
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
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
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _couponCodeController,
              style: GoogleFonts.inter(fontSize: 14, color: textPrimary),
              decoration: _inputDecoration('e.g. SAVE20', isDark, borderColor, textSecondary),
            ),
            const SizedBox(height: 14),
            Text(
              'Terms & Conditions',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _termsController,
              maxLines: 2,
              style: GoogleFonts.inter(fontSize: 14, color: textPrimary),
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
      hintStyle: GoogleFonts.inter(color: textSecondary, fontSize: 13),
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
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
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
        const SnackBar(
          content: Text('Post changes saved successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save changes: ${e.toString()}'),
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
