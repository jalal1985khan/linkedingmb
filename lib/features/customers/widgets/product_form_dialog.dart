import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/models/gmb_product.dart';
import '../../../data/repositories/backend_business_repository.dart';

class ProductFormDialog extends StatefulWidget {
  final GmbProduct? product;
  final Future<bool> Function(GmbProduct product) onSave;

  const ProductFormDialog({
    super.key,
    this.product,
    required this.onSave,
  });

  static Future<bool?> show(
    BuildContext context, {
    GmbProduct? product,
    required Future<bool> Function(GmbProduct product) onSave,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductFormDialog(
        product: product,
        onSave: onSave,
      ),
    );
  }

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _discountedPriceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _landingPageUrlController;
  late final TextEditingController _imageUrlController;
  late String _selectedCategory;
  late bool _isSpecial;

  bool _isUploadingImage = false;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'SaaS',
    'Software',
    'Marketing Tools',
    'Digital Products',
    'Services',
    'Consulting',
    'Subscription',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _priceController = TextEditingController(text: p?.price ?? '');
    _discountedPriceController = TextEditingController(text: p?.discountedPrice ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _landingPageUrlController = TextEditingController(text: p?.landingPageUrl ?? '');
    _imageUrlController = TextEditingController(text: p?.imageUrl ?? '');
    _selectedCategory = (p != null && p.category.isNotEmpty) ? p.category : 'SaaS';
    if (!_categories.contains(_selectedCategory)) {
      _categories.insert(0, _selectedCategory);
    }
    _isSpecial = p?.isSpecial ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _discountedPriceController.dispose();
    _descriptionController.dispose();
    _landingPageUrlController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
      if (pickedFile == null) return;

      setState(() => _isUploadingImage = true);
      final bytes = await pickedFile.readAsBytes();
      final repository = BackendBusinessRepository();
      final url = await repository.uploadProductImage(bytes, pickedFile.name);

      if (url != null && url.isNotEmpty) {
        setState(() {
          _imageUrlController.text = url;
          _isUploadingImage = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo uploaded successfully!'), duration: Duration(seconds: 2)),
          );
        }
      } else {
        setState(() => _isUploadingImage = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not upload photo. You can paste an image URL directly.')),
          );
        }
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final productToSave = GmbProduct(
      id: widget.product?.id ?? '',
      name: _nameController.text.trim(),
      category: _selectedCategory,
      price: _priceController.text.trim(),
      discountedPrice: _discountedPriceController.text.trim(),
      description: _descriptionController.text.trim(),
      imageUrl: _imageUrlController.text.trim(),
      landingPageUrl: _landingPageUrlController.text.trim(),
      isSpecial: _isSpecial,
      isSyncedToGmb: widget.product?.isSyncedToGmb ?? false,
    );

    final success = await widget.onSave(productToSave);
    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.product != null;

    final dialogBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final inputFill = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    final screenHeight = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.92,
        ),
        padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: dialogBg,
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
          mainAxisSize: MainAxisSize.min,
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

            // Dialog Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Edit Product' : 'Add Product',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEditing
                              ? 'Update product details on your Google Business Profile.'
                              : 'Create a product to display on your Google Business Profile.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: textSecondary,
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

            // Dialog Scrollable Body Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name
                      _buildLabel('Product name *', textPrimary),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        maxLength: 58,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textPrimary),
                        decoration: _inputDecoration(
                          hint: 'e.g. Linkedin Marketing Tools',
                          fillColor: inputFill,
                          borderColor: borderColor,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Product name is required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Category & Pricing Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Category *', textPrimary),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedCategory,
                                  dropdownColor: dialogBg,
                                  decoration: _inputDecoration(
                                    hint: 'Select Category',
                                    fillColor: inputFill,
                                    borderColor: borderColor,
                                  ),
                                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textPrimary),
                                  items: _categories.map((cat) {
                                    return DropdownMenuItem(
                                      value: cat,
                                      child: Text(cat),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedCategory = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Price (\$)', textPrimary),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _priceController,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textPrimary),
                                  decoration: _inputDecoration(
                                    hint: '399',
                                    fillColor: inputFill,
                                    borderColor: borderColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Discount (\$)', textPrimary),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _discountedPriceController,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textPrimary),
                                  decoration: _inputDecoration(
                                    hint: '299',
                                    fillColor: inputFill,
                                    borderColor: borderColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Description
                      _buildLabel('Product description', textPrimary),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descriptionController,
                        maxLength: 1000,
                        maxLines: 3,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: textPrimary),
                        decoration: _inputDecoration(
                          hint: 'Describe your product features, benefits, and specifications...',
                          fillColor: inputFill,
                          borderColor: borderColor,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Photo Banner / Uploader
                      _buildLabel('Photo', textPrimary),
                      const SizedBox(height: 6),
                      Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: inputFill,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, style: BorderStyle.solid),
                        ),
                        child: _imageUrlController.text.isNotEmpty
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: Image.network(
                                      _imageUrlController.text,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Center(
                                        child: Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Row(
                                      children: [
                                        InkWell(
                                          onTap: _pickAndUploadImage,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.75),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Change',
                                              style: GoogleFonts.plusJakartaSans(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        InkWell(
                                          onTap: () => setState(() => _imageUrlController.clear()),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDC2626).withValues(alpha: 0.85),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Remove',
                                              style: GoogleFonts.plusJakartaSans(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : Center(
                                child: _isUploadingImage
                                    ? Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(strokeWidth: 2.5),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Uploading image...',
                                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: textSecondary),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_photo_alternate_outlined, size: 30, color: textSecondary),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Upload photo or paste URL below',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              color: textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            height: 32,
                                            child: OutlinedButton.icon(
                                              onPressed: _pickAndUploadImage,
                                              icon: const Icon(Icons.upload_rounded, size: 14),
                                              label: Text(
                                                'Select Photo',
                                                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: const Color(0xFF4F46E5),
                                                side: const BorderSide(color: Color(0xFF4F46E5)),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _imageUrlController,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: textPrimary),
                        decoration: _inputDecoration(
                          hint: 'Or direct Image URL (https://...)',
                          fillColor: inputFill,
                          borderColor: borderColor,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 14),

                      // Landing page URL
                      _buildLabel('Landing page URL (optional)', textPrimary),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _landingPageUrlController,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: textPrimary),
                        decoration: _inputDecoration(
                          hint: 'https://yoursite.com/products/example',
                          fillColor: inputFill,
                          borderColor: borderColor,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Mark as Special Checkbox
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: inputFill,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _isSpecial,
                              activeColor: const Color(0xFF4F46E5),
                              onChanged: (val) => setState(() => _isSpecial = val ?? false),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mark as Special Offer',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Products marked Special are highlighted at the top of your catalog',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Divider(height: 1, color: borderColor),
            // Actions Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textSecondary,
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    child: Text('Cancel', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            isEditing ? 'Update Product' : 'Publish',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                          ),
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

  Widget _buildLabel(String text, Color color) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required Color fillColor,
    required Color borderColor,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey),
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
    );
  }
}
