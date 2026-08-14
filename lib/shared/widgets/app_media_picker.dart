import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';

class AppMediaPicker extends StatefulWidget {
  const AppMediaPicker({
    super.key,
    required this.initialUrl,
    required this.onMediaSelected,
    this.label = 'Post Media / Photo',
    this.subtitle = 'Attach an image from gallery, take a photo, or provide a link.',
  });

  final String initialUrl;
  final ValueChanged<String> onMediaSelected;
  final String label;
  final String subtitle;

  @override
  State<AppMediaPicker> createState() => _AppMediaPickerState();
}

class _AppMediaPickerState extends State<AppMediaPicker> {
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedFile;
  late final TextEditingController _urlController;
  bool _showUrlInput = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (photo != null) {
        setState(() {
          _pickedFile = photo;
          _urlController.text = photo.path;
        });
        widget.onMediaSelected(photo.path);
      }
    } catch (e) {
      if (source == ImageSource.camera) {
        // Fallback to gallery if camera is unavailable (e.g. simulator)
        _pickImage(ImageSource.gallery);
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an image or enter an Image URL.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  void _clearMedia() {
    setState(() {
      _pickedFile = null;
      _urlController.clear();
    });
    widget.onMediaSelected('');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final currentMedia = _pickedFile?.path ?? _urlController.text.trim();
    final hasMedia = currentMedia.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasMedia)
                IconButton(
                  onPressed: _clearMedia,
                  icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.error),
                  tooltip: 'Remove Media',
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Image Preview Frame
          if (hasMedia)
            Container(
              height: 180,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _pickedFile != null
                    ? (kIsWeb
                        ? Image.network(_pickedFile!.path, fit: BoxFit.cover)
                        : Image.file(File(_pickedFile!.path), fit: BoxFit.cover))
                    : Image.network(
                        currentMedia,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.broken_image_outlined, size: 36, color: Colors.grey),
                              const SizedBox(height: 6),
                              Text('Invalid Image Source', style: GoogleFonts.inter(fontSize: 12, color: textSecondary)),
                            ],
                          ),
                        ),
                      ),
              ),
            ),

          // Pick Buttons Row
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined, size: 16),
                  label: Text('Gallery', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined, size: 16),
                  label: Text('Camera', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textPrimary,
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => setState(() => _showUrlInput = !_showUrlInput),
                icon: Icon(
                  _showUrlInput ? Icons.link_off_outlined : Icons.link_outlined,
                  color: _showUrlInput ? AppColors.primary : textSecondary,
                ),
                tooltip: 'Toggle Image URL input',
              ),
            ],
          ),

          if (_showUrlInput) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              style: GoogleFonts.inter(fontSize: 13, color: textPrimary),
              onChanged: (val) {
                setState(() {
                  _pickedFile = null;
                });
                widget.onMediaSelected(val.trim());
              },
              decoration: InputDecoration(
                hintText: 'https://example.com/image.jpg',
                hintStyle: GoogleFonts.inter(color: textSecondary, fontSize: 13),
                prefixIcon: const Icon(Icons.link, size: 18),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
