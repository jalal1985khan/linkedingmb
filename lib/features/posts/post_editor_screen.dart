import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
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
  String _contentType = 'Image';
  bool _loading = true;
  bool _saving = false;

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
      appBar: AppBar(title: const Text('Edit Post')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _titleController,
                  decoration: _fieldDecoration('Post title'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _previewController,
                  maxLines: 6,
                  decoration: _fieldDecoration('Post caption / content'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _contentType,
                  decoration: const InputDecoration(
                    labelText: 'Content type',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Image', child: Text('Image')),
                    DropdownMenuItem(value: 'Offer', child: Text('Offer')),
                    DropdownMenuItem(value: 'Update', child: Text('Update')),
                    DropdownMenuItem(value: 'Event', child: Text('Event')),
                  ],
                  onChanged: (value) => setState(() => _contentType = value ?? _contentType),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: _saving ? null : _saveDraft,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Draft'),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SchedulerScreen(postId: widget.postId)),
                  ),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: const Text('Open Scheduler'),
                ),
              ],
            ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
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
        const SnackBar(content: Text('Draft updated')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
