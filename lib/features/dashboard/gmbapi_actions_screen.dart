import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/gmbapi_repository.dart';

class GmbapiActionsScreen extends ConsumerStatefulWidget {
  const GmbapiActionsScreen({super.key});

  @override
  ConsumerState<GmbapiActionsScreen> createState() => _GmbapiActionsScreenState();
}

class _GmbapiActionsScreenState extends ConsumerState<GmbapiActionsScreen> {
  final _postSummaryController = TextEditingController();
  final _reviewIdController = TextEditingController();
  final _reviewReplyController = TextEditingController();
  final _qnaQuestionController = TextEditingController();
  final _qnaAnswerController = TextEditingController();

  bool _isBusy = false;

  @override
  void dispose() {
    _postSummaryController.dispose();
    _reviewIdController.dispose();
    _reviewReplyController.dispose();
    _qnaQuestionController.dispose();
    _qnaAnswerController.dispose();
    super.dispose();
  }

  Future<void> _handleAction(Future<void> Function() action) async {
    setState(() => _isBusy = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Success!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GMBAPI Actions')),
      body: _isBusy
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSection(
                  title: 'Create Post',
                  children: [
                    TextField(
                      controller: _postSummaryController,
                      decoration: const InputDecoration(labelText: 'Post Summary'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (_postSummaryController.text.trim().isEmpty) return;
                        _handleAction(() => ref.read(gmbapiRepositoryProvider).createPost(
                          _postSummaryController.text.trim(),
                        ));
                      },
                      child: const Text('Post to GMBAPI'),
                    ),
                  ],
                ),
                const Divider(height: 32),
                _buildSection(
                  title: 'Reply to Review',
                  children: [
                    TextField(
                      controller: _reviewIdController,
                      decoration: const InputDecoration(labelText: 'Review ID'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _reviewReplyController,
                      decoration: const InputDecoration(labelText: 'Reply Text'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (_reviewIdController.text.trim().isEmpty || _reviewReplyController.text.trim().isEmpty) return;
                        _handleAction(() => ref.read(gmbapiRepositoryProvider).replyToReview(
                          _reviewIdController.text.trim(),
                          _reviewReplyController.text.trim(),
                        ));
                      },
                      child: const Text('Send Reply'),
                    ),
                  ],
                ),
                const Divider(height: 32),
                _buildSection(
                  title: 'Post Q&A',
                  children: [
                    TextField(
                      controller: _qnaQuestionController,
                      decoration: const InputDecoration(labelText: 'Question'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _qnaAnswerController,
                      decoration: const InputDecoration(labelText: 'Answer'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (_qnaQuestionController.text.trim().isEmpty || _qnaAnswerController.text.trim().isEmpty) return;
                        _handleAction(() => ref.read(gmbapiRepositoryProvider).postQna(
                          _qnaQuestionController.text.trim(),
                          _qnaAnswerController.text.trim(),
                        ));
                      },
                      child: const Text('Post Q&A'),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}
