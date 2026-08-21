import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../data/repositories/gmb_blueprint_repository.dart';

class EditConceptModal extends StatefulWidget {
  final GMBBlueprintItem item;
  final String locationId;
  final GMBBlueprintRepository repository;
  final VoidCallback onSaved;

  const EditConceptModal({
    super.key,
    required this.item,
    required this.locationId,
    required this.repository,
    required this.onSaved,
  });

  @override
  State<EditConceptModal> createState() => _EditConceptModalState();
}

class _EditConceptModalState extends State<EditConceptModal> {
  late TextEditingController _titleController;
  late TextEditingController _captionController;
  late TextEditingController _mediaConceptController;
  late TextEditingController _customInstructionController;
  late String _ctaType;

  bool _isImprovising = false;
  bool _isSaving = false;

  final List<Map<String, String>> _improvePresets = [
    {'type': 'ENGAGING', 'label': '⚡ Make engaging'},
    {'type': 'LOCAL_SEO', 'label': '📍 Add local SEO'},
    {'type': 'SHORTER', 'label': '✂️ Make shorter'},
    {'type': 'PROMOTIONAL', 'label': '🏷️ Add promo focus'},
  ];

  final List<String> _ctaOptions = [
    'LEARN_MORE',
    'BOOK',
    'SHOP',
    'GET_OFFER',
    'CALL_NOW',
    'SIGN_UP',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _captionController = TextEditingController(text: widget.item.caption);
    _mediaConceptController = TextEditingController(text: widget.item.mediaConcept);
    _customInstructionController = TextEditingController();
    _ctaType = widget.item.ctaType;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _captionController.dispose();
    _mediaConceptController.dispose();
    _customInstructionController.dispose();
    super.dispose();
  }

  Future<void> _improvise(String improvementType, [String? instruction]) async {
    setState(() => _isImprovising = true);
    try {
      final updated = await widget.repository.improviseBlueprintItem(
        locationId: widget.locationId,
        itemId: widget.item.id,
        improvementType: improvementType,
        customInstruction: instruction ?? _customInstructionController.text.trim(),
        currentTitle: _titleController.text.trim(),
        currentCaption: _captionController.text.trim(),
        currentMediaConcept: _mediaConceptController.text.trim(),
      );

      if (updated != null && mounted) {
        setState(() {
          _titleController.text = updated.title;
          _captionController.text = updated.caption;
          _mediaConceptController.text = updated.mediaConcept;
          if (updated.ctaType.isNotEmpty) _ctaType = updated.ctaType;
          _isImprovising = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Concept improvised with AI!'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      } else {
        setState(() => _isImprovising = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImprovising = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to improvise: ${e.toString()}'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      final success = await widget.repository.updateBlueprintItem(
        locationId: widget.locationId,
        itemId: widget.item.id,
        title: _titleController.text.trim(),
        caption: _captionController.text.trim(),
        mediaConcept: _mediaConceptController.text.trim(),
        ctaType: _ctaType,
      );

      if (mounted) {
        setState(() => _isSaving = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Concept saved successfully!'),
              backgroundColor: Color(0xFF16A34A),
            ),
          );
          Navigator.pop(context);
          widget.onSaved();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save changes.'),
              backgroundColor: Color(0xFFDC2626),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: ${e.toString()}'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
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
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_fix_high_rounded, color: Color(0xFF4F46E5), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit & AI Improvise Concept',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'Day ${widget.item.dayNumber} · ${widget.item.format}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: textSecondary,
                          fontWeight: FontWeight.w600,
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

          // Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Real-time AI Assistant Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome_rounded, color: Color(0xFF4F46E5), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Real-Time AI Assistant',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF4F46E5),
                              ),
                            ),
                            const Spacer(),
                            if (_isImprovising)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(color: Color(0xFF4F46E5), strokeWidth: 2),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Preset Chips
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _improvePresets.map((p) {
                            return GestureDetector(
                              onTap: _isImprovising ? null : () => _improvise(p['type']!),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.25)),
                                ),
                                child: Text(
                                  p['label']!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),

                        // Custom Instruction Input Row
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _customInstructionController,
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: textPrimary),
                                decoration: InputDecoration(
                                  hintText: 'Or type custom instruction (e.g. focus on discount)',
                                  hintStyle: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: textSecondary),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  filled: true,
                                  fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: borderColor),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: borderColor),
                                  ),
                                ),
                                onSubmitted: (val) {
                                  if (val.trim().isNotEmpty) _improvise('CUSTOM', val.trim());
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _isImprovising
                                  ? null
                                  : () => _improvise('CUSTOM', _customInstructionController.text.trim()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                              ),
                              child: Text(
                                'Improvise',
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 11.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title Input
                  _buildInputLabel('Post Title / Headline', textPrimary),
                  const SizedBox(height: 6),
                  _buildTextField(_titleController, 'Post headline', 1, textPrimary, textSecondary, borderColor),
                  const SizedBox(height: 14),

                  // Caption Input
                  _buildInputLabel('Post Copy / Caption', textPrimary),
                  const SizedBox(height: 6),
                  _buildTextField(_captionController, 'Full post caption text', 4, textPrimary, textSecondary, borderColor),
                  const SizedBox(height: 14),

                  // Media Concept Input
                  _buildInputLabel('Media Concept Prompt (image / video)', textPrimary),
                  const SizedBox(height: 6),
                  _buildTextField(_mediaConceptController, 'Description for the AI visual', 2, textPrimary, textSecondary, borderColor),
                  const SizedBox(height: 14),

                  // CTA Dropdown
                  _buildInputLabel('Call to Action (CTA)', textPrimary),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _ctaOptions.contains(_ctaType) ? _ctaType : 'LEARN_MORE',
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: borderColor),
                      ),
                    ),
                    items: _ctaOptions.map((cta) {
                      return DropdownMenuItem(
                        value: cta,
                        child: Text(
                          cta.replaceAll('_', ' '),
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: textPrimary),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _ctaType = val);
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Footer Save Action
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
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveChanges,
                    icon: _isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      _isSaving ? 'Saving Changes...' : 'Save Changes',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
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

  Widget _buildInputLabel(String label, Color textPrimary) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String placeholder,
    int maxLines,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
  ) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: maxLines > 1 ? maxLines : 1,
      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: textPrimary, height: 1.4),
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
    );
  }
}
