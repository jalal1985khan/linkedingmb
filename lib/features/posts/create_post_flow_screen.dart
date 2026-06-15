import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/scheduled_post.dart';
import '../business_flow/business_flow_controller.dart';
import '../dashboard/dashboard_controller.dart';
import '../settings/automation_settings_controller.dart';

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
  int _step = 0;
  bool _busy = false;

  final _topicController = TextEditingController();
  final _titleController = TextEditingController();
  final _captionController = TextEditingController();

  String _goal = 'Engagement';
  String _contentType = 'Image';
  String _mediaStyle = 'Professional';
  bool _publishNow = false;
  DateTime _scheduledAt = DateTime.now().add(const Duration(hours: 4));

  ScheduledPost? _draft;

  @override
  void dispose() {
    _topicController.dispose();
    _titleController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final business = ref.watch(selectedBusinessProvider);
    if (business == null) {
      return const Scaffold(body: Center(child: Text('No business selected')));
    }

    final body = Stepper(
      currentStep: _step,
      type: StepperType.vertical,
      controlsBuilder: (context, details) {
        return const SizedBox.shrink();
      },
      steps: [
        Step(
          title: const Text('Generate'),
          isActive: _step >= 0,
          state: _step > 0 ? StepState.complete : StepState.indexed,
          content: _GenerateStep(
            topicController: _topicController,
            goal: _goal,
            contentType: _contentType,
            mediaStyle: _mediaStyle,
            busy: _busy,
            onGoalChanged: (value) => setState(() => _goal = value),
            onContentTypeChanged: (value) => setState(() => _contentType = value),
            onMediaStyleChanged: (value) => setState(() => _mediaStyle = value),
            onGenerate: () => _generateDraft(business.name),
          ),
        ),
        Step(
          title: const Text('Edit Draft'),
          isActive: _step >= 1,
          state: _step > 1 ? StepState.complete : StepState.indexed,
          content: _EditStep(
            enabled: _draft != null,
            titleController: _titleController,
            captionController: _captionController,
            busy: _busy,
            onSave: _saveDraftEdits,
          ),
        ),
        Step(
          title: const Text('Schedule'),
          isActive: _step >= 2,
          state: _step > 2 ? StepState.complete : StepState.indexed,
          content: _ScheduleStep(
            enabled: _draft != null,
            publishNow: _publishNow,
            scheduledAt: _scheduledAt,
            onPublishNowChanged: (value) => setState(() => _publishNow = value),
            onPickDate: _pickDate,
            onPickTime: _pickTime,
          ),
        ),
        Step(
          title: const Text('Review & Finish'),
          isActive: _step >= 3,
          content: _ReviewStep(
            draft: _draft,
            busy: _busy,
            publishNow: _publishNow,
            scheduledAt: _scheduledAt,
            onSubmit: _finishFlow,
            onReset: _resetFlow,
          ),
        ),
      ],
    );

    if (!widget.showScaffold) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('AI Content Studio')),
      body: body,
    );
  }

  Future<void> _generateDraft(String businessName) async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) {
      _showSnackBar('Please enter a topic first');
      return;
    }

    setState(() => _busy = true);
    try {
      final draft = await ref.read(postRepositoryProvider).generatePostDraft(
            businessName: businessName,
            topic: topic,
            goal: _goal,
            contentType: _contentType,
          );
      final updated = await ref.read(postRepositoryProvider).updatePostDraft(
            postId: draft.id,
            title: draft.title,
            preview: '${draft.preview} Visual direction: $_mediaStyle.',
            contentType: _contentType,
          );
      if (!mounted) {
        return;
      }
      _draft = updated;
      _titleController.text = updated.title;
      _captionController.text = updated.preview;
      setState(() => _step = 1);
      ref.invalidate(dashboardDataProvider);

      if (ref.read(automationSettingsProvider).autoSchedulePosts) {
        _publishNow = false;
        _scheduledAt = DateTime.now().add(const Duration(days: 1));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _saveDraftEdits() async {
    if (_draft == null) {
      return;
    }
    setState(() => _busy = true);
    try {
      final updated = await ref.read(postRepositoryProvider).updatePostDraft(
            postId: _draft!.id,
            title: _titleController.text.trim(),
            preview: _captionController.text.trim(),
            contentType: _contentType,
          );
      if (!mounted) {
        return;
      }
      _draft = updated;
      setState(() => _step = 2);
      ref.invalidate(dashboardDataProvider);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _finishFlow() async {
    if (_draft == null) {
      return;
    }
    setState(() => _busy = true);
    try {
      if (_publishNow) {
        await ref.read(postRepositoryProvider).publishNow(_draft!.id);
      } else {
        await ref.read(postRepositoryProvider).schedulePost(
              postId: _draft!.id,
              scheduledAt: _scheduledAt,
            );
      }
      ref.invalidate(dashboardDataProvider);
      if (!mounted) {
        return;
      }
      setState(() => _step = 3);
      _showSnackBar(_publishNow ? 'Post published' : 'Post scheduled');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _resetFlow() {
    _topicController.clear();
    _titleController.clear();
    _captionController.clear();
    _goal = 'Engagement';
    _contentType = 'Image';
    _mediaStyle = 'Professional';
    _publishNow = false;
    _scheduledAt = DateTime.now().add(const Duration(hours: 4));
    _draft = null;
    setState(() => _step = 0);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _scheduledAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _scheduledAt.hour,
        _scheduledAt.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _scheduledAt = DateTime(
        _scheduledAt.year,
        _scheduledAt.month,
        _scheduledAt.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _GenerateStep extends StatelessWidget {
  const _GenerateStep({
    required this.topicController,
    required this.goal,
    required this.contentType,
    required this.mediaStyle,
    required this.busy,
    required this.onGoalChanged,
    required this.onContentTypeChanged,
    required this.onMediaStyleChanged,
    required this.onGenerate,
  });

  final TextEditingController topicController;
  final String goal;
  final String contentType;
  final String mediaStyle;
  final bool busy;
  final ValueChanged<String> onGoalChanged;
  final ValueChanged<String> onContentTypeChanged;
  final ValueChanged<String> onMediaStyleChanged;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: topicController,
          decoration: const InputDecoration(
            hintText: 'Post topic (e.g. Monsoon Offer, New Service)',
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: goal,
          decoration: const InputDecoration(labelText: 'Goal'),
          items: const [
            DropdownMenuItem(value: 'Engagement', child: Text('Engagement')),
            DropdownMenuItem(value: 'Leads', child: Text('Leads')),
            DropdownMenuItem(value: 'Conversions', child: Text('Conversions')),
            DropdownMenuItem(value: 'Awareness', child: Text('Awareness')),
          ],
          onChanged: (value) => onGoalChanged(value ?? goal),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: contentType,
          decoration: const InputDecoration(labelText: 'Content type'),
          items: const [
            DropdownMenuItem(value: 'Image', child: Text('Image')),
            DropdownMenuItem(value: 'Offer', child: Text('Offer')),
            DropdownMenuItem(value: 'Update', child: Text('Update')),
            DropdownMenuItem(value: 'Event', child: Text('Event')),
          ],
          onChanged: (value) => onContentTypeChanged(value ?? contentType),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: mediaStyle,
          decoration: const InputDecoration(labelText: 'Media style'),
          items: const [
            DropdownMenuItem(value: 'Professional', child: Text('Professional')),
            DropdownMenuItem(value: 'Minimal', child: Text('Minimal')),
            DropdownMenuItem(value: 'Bold', child: Text('Bold')),
            DropdownMenuItem(value: 'Seasonal', child: Text('Seasonal')),
          ],
          onChanged: (value) => onMediaStyleChanged(value ?? mediaStyle),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: busy ? null : onGenerate,
          child: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Generate AI Draft'),
        ),
      ],
    );
  }
}

class _EditStep extends StatelessWidget {
  const _EditStep({
    required this.enabled,
    required this.titleController,
    required this.captionController,
    required this.busy,
    required this.onSave,
  });

  final bool enabled;
  final TextEditingController titleController;
  final TextEditingController captionController;
  final bool busy;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return const Text('Generate a draft first.');
    }
    return Column(
      children: [
        TextField(
          controller: titleController,
          decoration: const InputDecoration(hintText: 'Draft title'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: captionController,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'Draft caption'),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: busy ? null : onSave,
          child: const Text('Save & Continue'),
        ),
      ],
    );
  }
}

class _ScheduleStep extends StatelessWidget {
  const _ScheduleStep({
    required this.enabled,
    required this.publishNow,
    required this.scheduledAt,
    required this.onPublishNowChanged,
    required this.onPickDate,
    required this.onPickTime,
  });

  final bool enabled;
  final bool publishNow;
  final DateTime scheduledAt;
  final ValueChanged<bool> onPublishNowChanged;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return const Text('Generate and edit a draft first.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: publishNow,
          onChanged: onPublishNowChanged,
          title: const Text('Publish now'),
          subtitle: const Text('Disable to schedule for later'),
        ),
        if (!publishNow) ...[
          Text(
            DateFormat('EEE, MMM d, y • h:mm a').format(scheduledAt),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onPickDate,
                  child: const Text('Pick date'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onPickTime,
                  child: const Text('Pick time'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.draft,
    required this.busy,
    required this.publishNow,
    required this.scheduledAt,
    required this.onSubmit,
    required this.onReset,
  });

  final ScheduledPost? draft;
  final bool busy;
  final bool publishNow;
  final DateTime scheduledAt;
  final VoidCallback onSubmit;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    if (draft == null) {
      return const Text('Complete previous steps first.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          draft!.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          draft!.preview,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Text(
          publishNow
              ? 'Action: Publish immediately'
              : 'Action: Schedule at ${DateFormat('MMM d, y • h:mm a').format(scheduledAt)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: busy ? null : onSubmit,
          child: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Finish'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: busy ? null : onReset,
          child: const Text('Create another post'),
        ),
      ],
    );
  }
}
