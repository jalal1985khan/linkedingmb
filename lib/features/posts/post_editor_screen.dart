import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/scheduled_post.dart';
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
  final _previewController = TextEditingController();
  String _contentType = 'STANDARD';
  bool _loading = true;
  bool _saving = false;
  ScheduledPost? _post;

  String _normalizeContentType(String raw) {
    final upper = raw.trim().toUpperCase();
    if (upper == 'STANDARD' || upper == 'UPDATE' || upper == 'IMAGE') return 'STANDARD';
    if (upper == 'OFFER') return 'OFFER';
    if (upper == 'EVENT') return 'EVENT';
    if (upper == 'PRODUCT') return 'PRODUCT';
    if (upper == 'ALERT') return 'ALERT';
    return 'STANDARD';
  }

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _previewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Text(
          'Edit Post',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Info Card
                  _buildHeaderCard(),

                  const SizedBox(height: 16),

                  // Form Fields Card
                  _buildFormCard(),

                  const SizedBox(height: 24),

                  // Action Buttons Card
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              color: Color(0xFF4F46E5),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Post Content Editor',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Modify post title, caption, and GMB topic type.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          if (_post != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _post!.status == PostStatus.scheduled
                    ? const Color(0xFFDEF7EC)
                    : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _post!.status == PostStatus.scheduled ? 'Scheduled' : 'Draft',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _post!.status == PostStatus.scheduled
                      ? const Color(0xFF03543F)
                      : const Color(0xFF92400E),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Label
          Text(
            'POST TITLE',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
            decoration: _inputDecoration('Enter a clear headline or title'),
          ),

          const SizedBox(height: 20),

          // Caption / Content Label
          Text(
            'CAPTION / CONTENT',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _previewController,
            maxLines: 6,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              height: 1.5,
              color: const Color(0xFF0F172A),
            ),
            decoration: _inputDecoration('Write your Google Business update or offer content...'),
          ),

          const SizedBox(height: 20),

          // Topic / Content Type Label
          Text(
            'GMB TOPIC TYPE',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _normalizeContentType(_contentType),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
            decoration: _inputDecoration('Select Content Type'),
            dropdownColor: Colors.white,
            items: [
              DropdownMenuItem(
                value: 'STANDARD',
                child: Text('Standard Update', style: GoogleFonts.plusJakartaSans()),
              ),
              DropdownMenuItem(
                value: 'OFFER',
                child: Text('Special Offer / Promo', style: GoogleFonts.plusJakartaSans()),
              ),
              DropdownMenuItem(
                value: 'EVENT',
                child: Text('Upcoming Event', style: GoogleFonts.plusJakartaSans()),
              ),
              DropdownMenuItem(
                value: 'PRODUCT',
                child: Text('Product Spotlight', style: GoogleFonts.plusJakartaSans()),
              ),
              DropdownMenuItem(
                value: 'ALERT',
                child: Text('Business Alert', style: GoogleFonts.plusJakartaSans()),
              ),
            ],
            onChanged: (value) => setState(() => _contentType = value ?? _contentType),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _saving ? null : _saveDraft,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Save Draft Changes',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => SchedulerScreen(postId: widget.postId)),
            ),
            icon: const Icon(Icons.schedule_rounded, size: 20, color: Color(0xFF4F46E5)),
            label: Text(
              'Open Scheduler',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4F46E5),
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF4F46E5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        color: const Color(0xFF94A3B8),
        fontSize: 14,
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.8),
      ),
    );
  }

  Future<void> _loadPost() async {
    final post = await ref.read(postRepositoryProvider).getPostById(widget.postId);
    if (!mounted) {
      return;
    }
    if (post == null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post not found')),
      );
      return;
    }
    _post = post;
    _titleController.text = post.title;
    _previewController.text = post.preview;
    _contentType = post.contentType;
    setState(() => _loading = false);
  }

  Future<void> _saveDraft() async {
    setState(() => _saving = true);
    try {
      await ref.read(postRepositoryProvider).updatePostDraft(
            postId: widget.postId,
            title: _titleController.text.trim(),
            preview: _previewController.text.trim(),
            contentType: _contentType,
          );
      ref.invalidate(dashboardDataProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft updated successfully')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
