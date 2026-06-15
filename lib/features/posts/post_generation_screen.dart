import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/scheduled_post.dart';
import '../business_flow/business_flow_controller.dart';
import '../dashboard/dashboard_controller.dart';
import 'post_editor_screen.dart';
import '../scheduler/scheduler_screen.dart';
import '../settings/automation_settings_controller.dart';

class PostGenerationScreen extends ConsumerStatefulWidget {
  const PostGenerationScreen({
    super.key,
    this.showScaffold = true,
  });

  final bool showScaffold;

  @override
  ConsumerState<PostGenerationScreen> createState() => _PostGenerationScreenState();
}

class _PostGenerationScreenState extends ConsumerState<PostGenerationScreen> {
  final _topicController = TextEditingController();
  String _goal = 'Engagement';
  String _contentType = 'Image';
  String _mediaStyle = 'Professional';
  bool _generating = false;
  ScheduledPost? _draft;

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final business = ref.watch(selectedBusinessProvider);
    if (business == null) {
      return const Scaffold(body: Center(child: Text('No business selected')));
    }

    final body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Business: ${business.name}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _topicController,
            decoration: InputDecoration(
              hintText: 'Post topic (e.g. Monsoon Offer, New Service)',
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
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _goal,
            decoration: const InputDecoration(
              labelText: 'Goal',
              filled: true,
              fillColor: Colors.white,
            ),
            items: const [
              DropdownMenuItem(value: 'Engagement', child: Text('Engagement')),
              DropdownMenuItem(value: 'Leads', child: Text('Leads')),
              DropdownMenuItem(value: 'Conversions', child: Text('Conversions')),
              DropdownMenuItem(value: 'Awareness', child: Text('Awareness')),
            ],
            onChanged: (value) => setState(() => _goal = value ?? _goal),
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
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _mediaStyle,
            decoration: const InputDecoration(
              labelText: 'Media style',
              filled: true,
              fillColor: Colors.white,
            ),
            items: const [
              DropdownMenuItem(value: 'Professional', child: Text('Professional')),
              DropdownMenuItem(value: 'Minimal', child: Text('Minimal')),
              DropdownMenuItem(value: 'Bold', child: Text('Bold')),
              DropdownMenuItem(value: 'Seasonal', child: Text('Seasonal')),
            ],
            onChanged: (value) => setState(() => _mediaStyle = value ?? _mediaStyle),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _generating ? null : () => _generatePost(business.name),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: _generating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Generate AI Draft'),
          ),
          if (_draft != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Generated draft', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(_draft!.title),
                    const SizedBox(height: 6),
                    Text(_draft!.preview),
                    const SizedBox(height: 6),
                    Text(
                      'Media style: $_mediaStyle',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.tonal(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PostEditorScreen(postId: _draft!.id),
                ),
              ),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: const Text('Open Post Editor'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SchedulerScreen(postId: _draft!.id),
                ),
              ),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: const Text('Open Scheduler'),
            ),
          ],
        ],
      );

    if (!widget.showScaffold) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Generate AI Post')),
      body: body,
    );
  }

  Future<void> _generatePost(String businessName) async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a topic first')),
      );
      return;
    }

    setState(() => _generating = true);
    try {
      final draft = await ref.read(postRepositoryProvider).generatePostDraft(
            businessName: businessName,
            topic: topic,
            goal: _goal,
            contentType: _contentType,
          );
      ref.invalidate(dashboardDataProvider);

      final autoScheduleEnabled =
          ref.read(automationSettingsProvider).autoSchedulePosts;
      if (autoScheduleEnabled) {
        await ref.read(postRepositoryProvider).schedulePost(
              postId: draft.id,
              scheduledAt: DateTime.now().add(const Duration(days: 1)),
            );
        ref.invalidate(dashboardDataProvider);
      }

      if (!mounted) {
        return;
      }
      final updatedDraft = await ref.read(postRepositoryProvider).updatePostDraft(
            postId: draft.id,
            title: draft.title,
            preview: '${draft.preview} Visual direction: $_mediaStyle.',
            contentType: _contentType,
          );
      if (!mounted) {
        return;
      }
      ref.invalidate(dashboardDataProvider);
      setState(() => _draft = updatedDraft);

      if (autoScheduleEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post generated and auto-scheduled')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _generating = false);
      }
    }
  }
}
