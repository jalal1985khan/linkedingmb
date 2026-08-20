import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/repositories/gmb_qa_repository.dart';
import '../../business_flow/providers/active_location_provider.dart';

class QAEngineScreen extends ConsumerStatefulWidget {
  const QAEngineScreen({super.key});

  @override
  ConsumerState<QAEngineScreen> createState() => _QAEngineScreenState();
}

class _QAEngineScreenState extends ConsumerState<QAEngineScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isGenerating = false;
  List<GMBQAPair> _publishedQAs = [];
  List<GMBQAPair> _drafts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final activeLocation = ref.read(activeLocationProvider).activeLocation;
    if (activeLocation == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(gmbQARepositoryProvider);
      final published = await repo.getPublishedQA(activeLocation.id);
      final drafts = await repo.getDrafts(activeLocation.id);

      if (mounted) {
        setState(() {
          _publishedQAs = published;
          _drafts = drafts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showGenerateDialog() async {
    final activeLocation = ref.read(activeLocationProvider).activeLocation;
    if (activeLocation == null) return;

    final nameController = TextEditingController(text: activeLocation.name);
    final categoryController = TextEditingController(text: activeLocation.category);
    final cityController = TextEditingController(text: activeLocation.address.split(',').last.trim());

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Color(0xFF6366F1)),
            const SizedBox(width: 10),
            Text(
              'Generate High-Intent FAQs',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'AI analyzes local search intent to generate questions and authoritative answers for your business.',
              style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Business Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: categoryController,
              decoration: InputDecoration(
                labelText: 'Category / Industry',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: cityController,
              decoration: InputDecoration(
                labelText: 'City / Area',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.bolt_rounded, size: 18),
            label: const Text('Generate 5 FAQs'),
            onPressed: () {
              Navigator.pop(ctx);
              _generateQAs(
                name: nameController.text.trim(),
                category: categoryController.text.trim(),
                city: cityController.text.trim(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _generateQAs({required String name, required String category, required String city}) async {
    final activeLocation = ref.read(activeLocationProvider).activeLocation;
    if (activeLocation == null) return;

    setState(() => _isGenerating = true);
    try {
      final repo = ref.read(gmbQARepositoryProvider);
      final generated = await repo.generateQA(
        locationId: activeLocation.id,
        businessName: name,
        category: category,
        city: city,
      );

      if (mounted) {
        setState(() {
          _drafts = generated;
          _isGenerating = false;
        });
        _tabController.animateTo(1); // Switch to drafts tab
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generated ${generated.length} high-intent FAQs!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _publishQA(GMBQAPair pair) async {
    final activeLocation = ref.read(activeLocationProvider).activeLocation;
    if (activeLocation == null) return;

    try {
      final repo = ref.read(gmbQARepositoryProvider);
      final ok = await repo.postQA(
        locationId: activeLocation.id,
        question: pair.question,
        answer: pair.answer,
      );

      if (ok && mounted) {
        setState(() {
          _drafts.removeWhere((d) => d.question == pair.question);
          _publishedQAs.insert(0, pair);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Q&A published to Google!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showManualQADialog() async {
    final activeLocation = ref.read(activeLocationProvider).activeLocation;
    if (activeLocation == null) return;

    final qController = TextEditingController();
    final aController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Add Custom FAQ',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qController,
              decoration: InputDecoration(
                labelText: 'Question',
                hintText: 'e.g. Do you offer emergency plumbing?',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: aController,
              decoration: InputDecoration(
                labelText: 'Answer',
                hintText: 'e.g. Yes, our team is available 24/7...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Publish to Google'),
            onPressed: () {
              final q = qController.text.trim();
              final a = aController.text.trim();
              if (q.isNotEmpty && a.isNotEmpty) {
                Navigator.pop(ctx);
                _publishQA(GMBQAPair(question: q, answer: a));
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeLocation = ref.watch(activeLocationProvider).activeLocation;

    if (activeLocation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Q&A Engine')),
        body: const Center(child: Text('Please select a business location first.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Google Q&A Engine',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF1E293B),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            Text(
              activeLocation.name,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Color(0xFF6366F1)),
            onPressed: _showManualQADialog,
            tooltip: 'Add Custom FAQ',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
            onPressed: _loadData,
            tooltip: 'Refresh Q&As',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4F46E5),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF4F46E5),
          labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            Tab(text: 'Live on Google (${_publishedQAs.length})'),
            Tab(text: 'AI Drafts (${_drafts.length})'),
          ],
        ),
      ),
      body: _isLoading || _isGenerating
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF6366F1)),
                  const SizedBox(height: 16),
                  Text(
                    _isGenerating ? 'AI is generating local customer FAQs...' : 'Loading Q&As...',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPublishedTab(),
                _buildDraftsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.auto_awesome_rounded),
        label: const Text('Generate FAQs with AI'),
        onPressed: _showGenerateDialog,
      ),
    );
  }

  Widget _buildPublishedTab() {
    if (_publishedQAs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.help_outline_rounded, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No Q&As Published Yet',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Seed your Google listing with common customer questions to boost SEO authority.',
                style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _publishedQAs.length,
      itemBuilder: (context, index) {
        final item = _publishedQAs[index];
        return _buildQACard(item, isDraft: false);
      },
    );
  }

  Widget _buildDraftsTab() {
    if (_drafts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.edit_note_rounded, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No Drafts Available',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Click the button below to generate high-intent customer FAQs tailored to this business.',
                style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _drafts.length,
      itemBuilder: (context, index) {
        final item = _drafts[index];
        return _buildQACard(item, isDraft: true);
      },
    );
  }

  Widget _buildQACard(GMBQAPair item, {required bool isDraft}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Q', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w800, fontSize: 12)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.question,
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF1E293B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('A', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w800, fontSize: 12)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.answer,
                  style: GoogleFonts.plusJakartaSans(color: const Color(0xFF475569), fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
          if (isDraft) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() => _drafts.remove(item));
                  },
                  child: const Text('Discard', style: TextStyle(color: Colors.redAccent)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 14),
                  label: const Text('Publish to Google', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  onPressed: () => _publishQA(item),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
