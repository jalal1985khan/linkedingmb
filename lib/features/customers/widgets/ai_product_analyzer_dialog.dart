import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/gmb_product.dart';

class AIProductAnalyzerDialog extends StatefulWidget {
  final String initialWebsiteUrl;
  final Future<List<GmbProduct>> Function(String websiteUrl) onAnalyze;
  final Future<int> Function(List<GmbProduct> selectedProducts) onImport;

  const AIProductAnalyzerDialog({
    super.key,
    required this.initialWebsiteUrl,
    required this.onAnalyze,
    required this.onImport,
  });

  static Future<int?> show(
    BuildContext context, {
    required String initialWebsiteUrl,
    required Future<List<GmbProduct>> Function(String websiteUrl) onAnalyze,
    required Future<int> Function(List<GmbProduct> selectedProducts) onImport,
  }) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AIProductAnalyzerDialog(
        initialWebsiteUrl: initialWebsiteUrl,
        onAnalyze: onAnalyze,
        onImport: onImport,
      ),
    );
  }

  @override
  State<AIProductAnalyzerDialog> createState() => _AIProductAnalyzerDialogState();
}

class _AIProductAnalyzerDialogState extends State<AIProductAnalyzerDialog> {
  late final TextEditingController _urlController;
  bool _isAnalyzing = false;
  bool _isImporting = false;
  List<GmbProduct> _suggestedProducts = [];
  final Set<int> _selectedIndices = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialWebsiteUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _handleAnalyze() async {
    final queryUrl = _urlController.text.trim();
    if (queryUrl.isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _suggestedProducts = [];
      _selectedIndices.clear();
    });

    try {
      final results = await widget.onAnalyze(queryUrl);
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _suggestedProducts = results;
          _selectedIndices.addAll(List.generate(results.length, (i) => i));
          if (results.isEmpty) {
            _errorMessage = 'No products detected from website. Please verify the URL.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _handleImport() async {
    if (_selectedIndices.isEmpty) return;

    setState(() => _isImporting = true);
    final selected = _selectedIndices.map((i) => _suggestedProducts[i]).toList();
    final count = await widget.onImport(selected);

    if (mounted) {
      setState(() => _isImporting = false);
      Navigator.of(context).pop(count);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final inputFill = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    final screenHeight = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: Colors.transparent,
      child: Container(
        height: screenHeight * 0.85,
        padding: EdgeInsets.only(bottom: bottomInset),
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Drag Handle Pill
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Header Section
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9333EA).withValues(alpha: isDark ? 0.25 : 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF9333EA), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Smart Product Suggestion',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Crawl your website to discover products, SaaS tiers & pricing automatically.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded, color: textSecondary, size: 20),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: borderColor),

              // URL Full Width Input & Action Button Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Full-width URL TextField
                    TextField(
                      controller: _urlController,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textPrimary),
                      textInputAction: TextInputAction.go,
                      onSubmitted: (_) => _handleAnalyze(),
                      decoration: InputDecoration(
                        hintText: 'https://example.com/pricing or website URL',
                        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey),
                        prefixIcon: const Icon(Icons.language_rounded, size: 20, color: Color(0xFF6366F1)),
                        suffixIcon: _urlController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _urlController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: inputFill,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Full-width aligned Scan Website Button
                    SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: _isAnalyzing ? null : _handleAnalyze,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        icon: _isAnalyzing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.auto_awesome_rounded, size: 18),
                        label: Text(
                          _isAnalyzing ? 'Scanning & Analyzing Website...' : 'Scan Website with AI',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFFDC2626)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Suggested Products List or Empty State (Inside Expanded)
              Expanded(
                child: _isAnalyzing
                    ? Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF6366F1)),
                              const SizedBox(height: 14),
                              Text(
                                'AI is scanning your website for product offerings...',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: textSecondary, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _suggestedProducts.isEmpty
                        ? Center(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF334155).withValues(alpha: 0.3) : const Color(0xFFF1F5F9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.travel_explore_rounded, size: 32, color: textSecondary.withValues(alpha: 0.7)),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Enter a website URL above to scan for products',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _suggestedProducts.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, idx) {
                              final prod = _suggestedProducts[idx];
                              final isSelected = _selectedIndices.contains(idx);

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedIndices.remove(idx);
                                    } else {
                                      _selectedIndices.add(idx);
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (isDark ? const Color(0xFF312E81).withValues(alpha: 0.3) : const Color(0xFFEEF2FF))
                                        : inputFill,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF6366F1) : borderColor,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Checkbox(
                                        value: isSelected,
                                        activeColor: const Color(0xFF6366F1),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                        onChanged: (val) {
                                          setState(() {
                                            if (val == true) {
                                              _selectedIndices.add(idx);
                                            } else {
                                              _selectedIndices.remove(idx);
                                            }
                                          });
                                        },
                                      ),
                                      if (prod.imageUrl.isNotEmpty) ...[
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            prod.imageUrl,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              width: 60,
                                              height: 60,
                                              color: borderColor,
                                              child: const Icon(Icons.image_not_supported_rounded, size: 22, color: Colors.grey),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                      ],
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    prod.name,
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 14,
                                                      color: textPrimary,
                                                    ),
                                                  ),
                                                ),
                                                if (prod.price.isNotEmpty)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      '\$${prod.price}',
                                                      style: GoogleFonts.plusJakartaSans(
                                                        color: const Color(0xFF16A34A),
                                                        fontWeight: FontWeight.w800,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              prod.category,
                                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w600),
                                            ),
                                            if (prod.description.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                prod.description,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: textSecondary),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),

              Divider(height: 1, color: borderColor),

              // Actions Footer (Responsive & No-Overflow)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_selectedIndices.length} of ${_suggestedProducts.length} selected',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: textSecondary, fontWeight: FontWeight.w600),
                        ),
                        if (_suggestedProducts.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                if (_selectedIndices.length == _suggestedProducts.length) {
                                  _selectedIndices.clear();
                                } else {
                                  _selectedIndices.addAll(List.generate(_suggestedProducts.length, (i) => i));
                                }
                              });
                            },
                            child: Text(
                              _selectedIndices.length == _suggestedProducts.length ? 'Deselect All' : 'Select All',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF6366F1),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textSecondary,
                                side: BorderSide(color: borderColor),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text('Cancel', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              onPressed: _isImporting || _selectedIndices.isEmpty ? null : _handleImport,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isImporting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'Import (${_selectedIndices.length}) Products',
                                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13.5),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
