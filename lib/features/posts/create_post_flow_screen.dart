import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../business_flow/business_flow_controller.dart';
import '../dashboard/dashboard_controller.dart';

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
  String _postType = 'Update';
  bool _scheduleForLater = false;
  final TextEditingController _captionController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _onGenerateAIAssist() async {
    setState(() => _busy = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      _captionController.text = "Exciting news! We are launching our new seasonal menu today. Come visit us and try our limited-time specials! ✨ #SeasonalMenu #Launch";
      setState(() => _busy = false);
    }
  }

  void _publish() async {
    setState(() => _busy = true);
    await Future.delayed(const Duration(seconds: 2));
    ref.invalidate(dashboardDataProvider);
    if (mounted) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_scheduleForLater ? 'Post Scheduled!' : 'Post Published!')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final business = ref.watch(selectedBusinessProvider);

    final body = SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Segmented Control
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildSegment('Update')),
                  Expanded(child: _buildSegment('Event')),
                  Expanded(child: _buildSegment('Offer')),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (_postType == 'Update') ...[
              _buildUploadContainer(),
              const SizedBox(height: 24),
              _buildEditorContainer(business?.name ?? 'BizSuite Premium Studio'),
              const SizedBox(height: 24),
              _buildScheduleContainer(),
              const SizedBox(height: 32),
              _buildPrimaryButton('Publish Post', Icons.send_rounded),
            ] else if (_postType == 'Event') ...[
              _buildUploadContainer(),
              const SizedBox(height: 24),
              _buildEventForm(),
              const SizedBox(height: 32),
              _buildPrimaryButton('Publish Event', Icons.rocket_launch_outlined),
            ] else if (_postType == 'Offer') ...[
              _buildUploadContainer(),
              const SizedBox(height: 24),
              _buildOfferForm(),
              const SizedBox(height: 32),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.remove_red_eye_outlined, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPrimaryButton('Publish Offer', Icons.send_rounded),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );

    if (!widget.showScaffold) return body;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _postType == 'Update' ? 'Create Post' : 'Create New Post',
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
      ),
      body: body,
    );
  }

  Widget _buildSegment(String title) {
    final isSelected = _postType == title;
    return GestureDetector(
      onTap: () => setState(() => _postType = title),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.primaryContainer : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildUploadContainer({String? clickText}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryContainer, size: 28),
          ),
          const SizedBox(height: 16),
          const Text(
            'Add photos or videos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          if (clickText != null)
            RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                children: [
                  const TextSpan(text: 'Drag and drop or '),
                  const TextSpan(text: 'click to upload', style: TextStyle(color: AppColors.primaryContainer, fontWeight: FontWeight.bold)),
                  const TextSpan(text: ' visuals'),
                ],
              ),
            )
          else
            Text(
              'Drag and drop or click to browse files',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildEditorContainer(String businessName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage('assets/images/user_avatar.jpg'),
                backgroundColor: AppColors.surfaceContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(businessName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _captionController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: "What's happening? Share an update\nwith your customers...",
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16, height: 1.5),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.surfaceContainer),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.sentiment_satisfied_alt_rounded, color: Colors.grey.shade600, size: 24),
                  const SizedBox(width: 16),
                  Icon(Icons.alternate_email_rounded, color: Colors.grey.shade600, size: 24),
                  const SizedBox(width: 16),
                  Icon(Icons.tag_rounded, color: Colors.grey.shade600, size: 24),
                ],
              ),
              _buildAIAssistButton(),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildScheduleContainer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.access_time_rounded, color: AppColors.primaryContainer, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Schedule for later', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text('Automatically post at peak\nengagement times', style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.3)),
              ],
            ),
          ),
          Switch(
            value: _scheduleForLater,
            onChanged: (val) => setState(() => _scheduleForLater = val),
            activeColor: Colors.white,
            activeTrackColor: AppColors.primaryContainer,
            inactiveTrackColor: Colors.grey.shade300,
            inactiveThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildEventForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField('Event Title', 'What\'s the name of your event?'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildInputField('Start Date', 'Oct 24, 2024', icon: Icons.calendar_today_outlined)),
            const SizedBox(width: 16),
            Expanded(child: _buildInputField('End Date', 'Oct 25, 2024', icon: Icons.calendar_today_outlined)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildInputField('Start Time', '09:00 AM', icon: Icons.access_time_rounded)),
            const SizedBox(width: 16),
            Expanded(child: _buildInputField('End Time', '06:00 PM', icon: Icons.access_time_rounded)),
          ],
        ),
        const SizedBox(height: 16),
        _buildInputField('Event Location', 'Add a place or online link', prefixIcon: Icons.location_on_outlined, prefixColor: AppColors.primaryContainer),
        const SizedBox(height: 16),
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(16),
            image: const DecorationImage(
              image: AssetImage('assets/images/map_placeholder.png'), // Will fail to load gracefully if missing
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Description', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            _buildAIAssistButton(),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Describe your event to attract more\nattendees...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
          ),
        ),
      ],
    );
  }

  Widget _buildOfferForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Offer Headline', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            _buildAIAssistButton(),
          ],
        ),
        const SizedBox(height: 8),
        _buildInputField('', 'e.g. 20% Off Storewide', noLabel: true),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildInputField('Start Date', 'Oct 24, 2024', icon: Icons.calendar_today_outlined)),
            const SizedBox(width: 16),
            Expanded(child: _buildInputField('End Date', 'Nov 10, 2024', icon: Icons.calendar_today_outlined)),
          ],
        ),
        const SizedBox(height: 16),
        _buildInputField('Offer Code (Optional)', 'E.G. SUMMER24', prefixIcon: Icons.local_activity_outlined),
        const SizedBox(height: 16),
        const Text('Locations', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE0F7FA), // Light cyan background to simulate map map
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
                child: const Icon(Icons.location_on, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Applies to 3 Locations', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text('SF Downtown, Oakland, Palo Alto', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('Redemption Instructions', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        TextField(
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'How do customers claim this offer?\n(e.g. Show this post at checkout)',
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(String label, String hint, {IconData? icon, IconData? prefixIcon, Color? prefixColor, bool noLabel = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!noLabel) ...[
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
        ],
        TextField(
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            suffixIcon: icon != null ? Icon(icon, color: Colors.grey.shade600, size: 20) : null,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: prefixColor ?? Colors.grey.shade600, size: 20) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildAIAssistButton() {
    return ElevatedButton.icon(
      onPressed: _busy ? null : _onGenerateAIAssist,
      icon: const Icon(Icons.auto_awesome_rounded, size: 14, color: Colors.black87),
      label: const Text('AI Assist', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amberAccent,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        minimumSize: const Size(0, 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildPrimaryButton(String label, IconData icon) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _busy ? null : _publish,
        icon: _busy ? const SizedBox() : Icon(icon, size: 18),
        label: _busy 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }
}
