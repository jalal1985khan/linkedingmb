import 'package:flutter/material.dart';

class DarkSettingsScreen extends StatefulWidget {
  const DarkSettingsScreen({super.key});

  @override
  State<DarkSettingsScreen> createState() => _DarkSettingsScreenState();
}

class _DarkSettingsScreenState extends State<DarkSettingsScreen> {
  bool _aiAutomation = true;
  bool _smartContent = true;
  bool _autoReview = false;
  String _frequency = 'Daily';

  final Color _bgColor = const Color(0xFF282C3D);
  final Color _cardColor = const Color(0xFF35394C);
  final Color _textColor = Colors.white;
  final Color _subTextColor = Colors.grey.shade400;
  final Color _primaryColor = const Color(0xFF00E5FF); // Cyan toggle
  final Color _accentPurple = const Color(0xFF633BFF); // Active bottom tab
  final Color _headerTextColor = const Color(0xFF00E5FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: _textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Settings',
          style: TextStyle(color: _textColor, fontWeight: FontWeight.w700, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: _textColor),
            onPressed: () {},
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('ACCOUNT & PROFILE'),
              _buildCard([
                _buildListTile(
                  icon: Icons.person_outline_rounded,
                  iconBg: const Color(0xFF633BFF),
                  title: 'Personal Info',
                  subtitle: 'Manage your data and privacy',
                ),
                const Divider(color: Color(0xFF45495E), height: 1),
                _buildListTile(
                  icon: Icons.domain_rounded,
                  iconBg: const Color(0xFF00E5FF),
                  title: 'Business Profile',
                  subtitle: 'Company details and branding',
                ),
              ]),
              const SizedBox(height: 24),

              Row(
                children: [
                  _buildSectionHeader('AI SETTINGS', padding: false),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBF008B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('PREMIUM', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildCard([
                _buildToggleTile(
                  title: 'AI Automation',
                  subtitle: 'Let AI handle routine tasks',
                  value: _aiAutomation,
                  onChanged: (v) => setState(() => _aiAutomation = v),
                ),
                const Divider(color: Color(0xFF45495E), height: 1),
                _buildToggleTile(
                  title: 'Smart Content Generation',
                  subtitle: 'Enable draft suggestions',
                  icon: Icons.edit_note_rounded,
                  value: _smartContent,
                  onChanged: (v) => setState(() => _smartContent = v),
                ),
                const Divider(color: Color(0xFF45495E), height: 1),
                _buildToggleTile(
                  title: 'Auto-Review Responses',
                  subtitle: 'Audit AI output quality',
                  icon: Icons.shield_outlined,
                  value: _autoReview,
                  onChanged: (v) => setState(() => _autoReview = v),
                ),
                const Divider(color: Color(0xFF45495E), height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_graph_rounded, color: _primaryColor, size: 20),
                          const SizedBox(width: 12),
                          Text('AI Insights Frequency', style: TextStyle(color: _textColor, fontWeight: FontWeight.w600, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildFrequencyPill('Daily'),
                          const SizedBox(width: 8),
                          _buildFrequencyPill('Weekly'),
                          const SizedBox(width: 8),
                          _buildFrequencyPill('Real-time'),
                        ],
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 24),

              _buildSectionHeader('PREFERENCES'),
              _buildCard([
                _buildSimpleTile(Icons.notifications_none_rounded, 'Notifications'),
                const Divider(color: Color(0xFF45495E), height: 1),
                _buildSimpleTile(Icons.security_rounded, 'Security'),
              ]),
              const SizedBox(height: 24),

              _buildSectionHeader('SUPPORT'),
              _buildCard([
                _buildSimpleTile(Icons.help_outline_rounded, 'Help Center'),
                const Divider(color: Color(0xFF45495E), height: 1),
                _buildSimpleTile(Icons.info_outline_rounded, 'About', showChevron: false, trailingIcon: Icons.open_in_new_rounded),
              ]),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.logout_rounded, color: Color(0xFFBA1A1A)),
                  label: const Text('Sign Out', style: TextStyle(color: Color(0xFFBA1A1A), fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cardColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Center(
                child: Text('AI Business Suite © 2024', style: TextStyle(color: _subTextColor, fontSize: 12)),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: _cardColor,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBottomNavItem('Dashboard', Icons.grid_view_rounded, false),
                _buildBottomNavItem('Operations', Icons.work_outline_rounded, false),
                _buildBottomNavItem('AI Hub', Icons.psychology_outlined, false),
                _buildBottomNavItem('Settings', Icons.settings_rounded, true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool padding = true}) {
    return Padding(
      padding: EdgeInsets.only(left: 4, bottom: 12, top: padding ? 8 : 0),
      child: Text(
        title,
        style: TextStyle(color: _headerTextColor, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildListTile({required IconData icon, required Color iconBg, required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: _textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: _subTextColor, fontSize: 13)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: _subTextColor),
        ],
      ),
    );
  }

  Widget _buildToggleTile({required String title, required String subtitle, IconData? icon, required bool value, required ValueChanged<bool> onChanged}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: _primaryColor, size: 20),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: _textColor, fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: _subTextColor, fontSize: 13)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: _primaryColor,
            inactiveTrackColor: const Color(0xFF45495E),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyPill(String label) {
    final isSelected = _frequency == label;
    return GestureDetector(
      onTap: () => setState(() => _frequency = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor : const Color(0xFF45495E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF131B2E) : _subTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleTile(IconData icon, String title, {bool showChevron = true, IconData? trailingIcon}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF45495E), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: _primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title, style: TextStyle(color: _textColor, fontWeight: FontWeight.w600, fontSize: 15)),
          ),
          if (showChevron) Icon(Icons.chevron_right, color: _subTextColor),
          if (trailingIcon != null) Icon(trailingIcon, color: _subTextColor, size: 16),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(String label, IconData icon, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isSelected)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: _accentPurple,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          )
        else
          Icon(icon, color: _subTextColor, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : _subTextColor,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
