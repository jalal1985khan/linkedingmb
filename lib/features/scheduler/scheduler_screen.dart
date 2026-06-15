import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/scheduled_post.dart';
import '../dashboard/dashboard_controller.dart';

class SchedulerScreen extends ConsumerStatefulWidget {
  const SchedulerScreen({
    super.key,
    required this.postId,
  });

  final String postId;

  @override
  ConsumerState<SchedulerScreen> createState() => _SchedulerScreenState();
}

class _SchedulerScreenState extends ConsumerState<SchedulerScreen> {
  DateTime _scheduledDateTime = DateTime.now().add(const Duration(hours: 2));
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Post')),
      body: FutureBuilder<ScheduledPost?>(
        future: ref.read(postRepositoryProvider).getPostById(widget.postId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final post = snapshot.data;
          if (post == null) {
            return const Center(child: Text('Post not found'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(post.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(post.preview),
              const SizedBox(height: 18),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Selected date & time'),
                subtitle: Text(DateFormat('EEE, MMM d, y • h:mm a').format(_scheduledDateTime)),
                trailing: const Icon(Icons.schedule_rounded),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _pickDate,
                      child: const Text('Pick date'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _pickTime,
                      child: const Text('Pick time'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _schedulePost,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Schedule'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _scheduledDateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _scheduledDateTime.hour,
        _scheduledDateTime.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledDateTime),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _scheduledDateTime = DateTime(
        _scheduledDateTime.year,
        _scheduledDateTime.month,
        _scheduledDateTime.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _schedulePost() async {
    setState(() => _saving = true);
    try {
      await ref.read(postRepositoryProvider).schedulePost(
            postId: widget.postId,
            scheduledAt: _scheduledDateTime,
          );
      ref.invalidate(dashboardDataProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post scheduled')),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
