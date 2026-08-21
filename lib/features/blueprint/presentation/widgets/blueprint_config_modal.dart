import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BlueprintConfigModal extends StatefulWidget {
  final int planDays;
  final int initialPostsPerWeek;
  final List<String> initialFormats;
  final bool isGenerating;
  final Function(int postsPerWeek, List<String> selectedFormats, bool autoSchedule) onGenerateLocation;
  final Function(Map<String, String> profilerInputs) onGenerateWebsite;

  const BlueprintConfigModal({
    super.key,
    this.planDays = 30,
    this.initialPostsPerWeek = 5,
    this.initialFormats = const [
      'VIDEO',
      'TEXT_IMAGE',
      'OFFER',
      'EVENT',
      'PRODUCT',
      'SERVICE',
      'TEXT_ONLY',
    ],
    required this.isGenerating,
    required this.onGenerateLocation,
    required this.onGenerateWebsite,
  });

  @override
  State<BlueprintConfigModal> createState() => _BlueprintConfigModalState();
}

class _BlueprintConfigModalState extends State<BlueprintConfigModal> {
  int _mode = 0; // 0: Location Context, 1: Web Crawler & AI Profiler
  late int _postsPerWeek;
  late List<String> _selectedFormats;
  bool _autoSchedule = false;

  final TextEditingController _websiteUrlController = TextEditingController();
  final TextEditingController _targetAudienceController = TextEditingController();
  final TextEditingController _brandPersonaController = TextEditingController();
  final TextEditingController _productsServicesController = TextEditingController();
  final TextEditingController _goalsController = TextEditingController();

  final List<Map<String, dynamic>> _availableFormats = [
    {'id': 'TEXT_IMAGE', 'label': 'Photo & Graphic', 'icon': Icons.image_outlined},
    {'id': 'VIDEO', 'label': 'Video Script', 'icon': Icons.videocam_outlined},
    {'id': 'OFFER', 'label': 'Special Offer', 'icon': Icons.local_offer_outlined},
    {'id': 'EVENT', 'label': 'Event / Meetup', 'icon': Icons.event_outlined},
    {'id': 'PRODUCT', 'label': 'Product Spotlight', 'icon': Icons.shopping_bag_outlined},
    {'id': 'SERVICE', 'label': 'Service Feature', 'icon': Icons.business_center_outlined},
    {'id': 'TEXT_ONLY', 'label': 'Text Announcement', 'icon': Icons.notes_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _postsPerWeek = widget.initialPostsPerWeek;
    _selectedFormats = List.from(widget.initialFormats);
  }

  @override
  void dispose() {
    _websiteUrlController.dispose();
    _targetAudienceController.dispose();
    _brandPersonaController.dispose();
    _productsServicesController.dispose();
    _goalsController.dispose();
    super.dispose();
  }

  void _toggleFormat(String id) {
    setState(() {
      if (_selectedFormats.contains(id)) {
        if (_selectedFormats.length > 1) {
          _selectedFormats.remove(id);
        }
      } else {
        _selectedFormats.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E1B4B);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF312E81).withValues(alpha: 0.5) : const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.settings_suggest_rounded, color: Color(0xFF4F46E5), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Strategy Blueprint Configuration',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'Configure posting frequency and allowed formats for ${widget.planDays}-day plan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Dual Mode Segment Switcher
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _mode = 0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _mode == 0 ? const Color(0xFF4F46E5) : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: _mode == 0
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'GMB Location Context',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: _mode == 0 ? FontWeight.w800 : FontWeight.w600,
                            color: _mode == 0 ? Colors.white : textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _mode = 1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _mode == 1 ? const Color(0xFF4F46E5) : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: _mode == 1
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Web Crawler & Profiler',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: _mode == 1 ? FontWeight.w800 : FontWeight.w600,
                            color: _mode == 1 ? Colors.white : textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Scrollable Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: _mode == 0
                  ? _buildLocationContextForm(isDark, cardBgColor, borderColor, textPrimary, textSecondary)
                  : _buildWebCrawlerForm(isDark, cardBgColor, borderColor, textPrimary, textSecondary),
            ),
          ),

          // Footer Action Button
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: cardBgColor,
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textPrimary,
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text('Cancel', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF3730A3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: widget.isGenerating
                          ? null
                          : () {
                              Navigator.pop(context);
                              if (_mode == 0) {
                                widget.onGenerateLocation(_postsPerWeek, _selectedFormats, _autoSchedule);
                              } else {
                                widget.onGenerateWebsite({
                                  'websiteUrl': _websiteUrlController.text.trim(),
                                  'targetAudience': _targetAudienceController.text.trim(),
                                  'brandPersona': _brandPersonaController.text.trim(),
                                  'productsServices': _productsServicesController.text.trim(),
                                  'goals': _goalsController.text.trim(),
                                });
                              }
                            },
                      icon: widget.isGenerating
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.bolt_rounded, size: 18),
                      label: Text(
                        widget.isGenerating ? 'Generating Strategy...' : 'Generate Blueprint',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13.5),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationContextForm(
    bool isDark,
    Color cardBgColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Posting Frequency
        Text(
          'POSTING FREQUENCY',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [3, 5, 7].map((p) {
            final isSelected = _postsPerWeek == p;
            final label = p == 3 ? '3 posts/wk' : (p == 5 ? '5 posts/wk' : '7 (Daily)');
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _postsPerWeek = p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: EdgeInsets.only(right: p == 7 ? 0 : 8),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF4F46E5)
                        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF4F46E5) : borderColor,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : textPrimary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),

        // Allowed Post Formats
        Text(
          'ALLOWED POST FORMATS',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 3.2,
          ),
          itemCount: _availableFormats.length,
          itemBuilder: (context, index) {
            final fmt = _availableFormats[index];
            final id = fmt['id'] as String;
            final icon = fmt['icon'] as IconData;
            final isChecked = _selectedFormats.contains(id);

            return GestureDetector(
              onTap: () => _toggleFormat(id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isChecked
                      ? (isDark ? const Color(0xFF312E81).withValues(alpha: 0.4) : const Color(0xFFEEF2FF))
                      : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isChecked ? const Color(0xFF4F46E5) : borderColor,
                    width: isChecked ? 1.2 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: isChecked ? const Color(0xFF4F46E5) : textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        fmt['label'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: isChecked ? FontWeight.w700 : FontWeight.w500,
                          color: isChecked ? textPrimary : textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isChecked)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF4F46E5),
                        size: 15,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Auto-schedule Toggle Card
        GestureDetector(
          onTap: () => setState(() => _autoSchedule = !_autoSchedule),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _autoSchedule ? const Color(0xFF4F46E5).withValues(alpha: 0.4) : borderColor,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _autoSchedule
                        ? const Color(0xFF4F46E5).withValues(alpha: 0.1)
                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.schedule_send_rounded,
                    color: _autoSchedule ? const Color(0xFF4F46E5) : textSecondary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-schedule to Post Queue',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Directly queue rendered posts into calendar',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _autoSchedule,
                  activeThumbColor: const Color(0xFF4F46E5),
                  activeTrackColor: const Color(0xFFC7D2FE),
                  onChanged: (val) => setState(() => _autoSchedule = val),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildWebCrawlerForm(
    bool isDark,
    Color cardBgColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFF4F46E5), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Enter your website URL to auto-extract products, services, and goals to build an enriched blueprint.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        _buildTextField('Website URL', _websiteUrlController, 'https://mybusiness.com', textPrimary, textSecondary, borderColor),
        const SizedBox(height: 12),
        _buildTextField('Target Audience', _targetAudienceController, 'Local homeowners, small businesses...', textPrimary, textSecondary, borderColor),
        const SizedBox(height: 12),
        _buildTextField('Brand Persona / Voice', _brandPersonaController, 'Professional, Friendly, Informative...', textPrimary, textSecondary, borderColor),
        const SizedBox(height: 12),
        _buildTextField('Featured Products / Services (comma separated)', _productsServicesController, 'SEO Audit, Marketing Consulting, Web Design', textPrimary, textSecondary, borderColor),
        const SizedBox(height: 12),
        _buildTextField('Primary Business Goals (comma separated)', _goalsController, 'Lead Generation, Local Awareness, Bookings', textPrimary, textSecondary, borderColor),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String placeholder,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: textPrimary),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: textSecondary.withValues(alpha: 0.6)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
