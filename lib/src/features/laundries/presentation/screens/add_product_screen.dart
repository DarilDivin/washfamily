import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../domain/models/laundry_product_model.dart';
import '../../data/repositories/laundry_product_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class AddProductScreen extends StatefulWidget {
  final String laundryId;
  const AddProductScreen({super.key, required this.laundryId});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _repo = LaundryProductRepository();

  String _category = 'DETERGENT';
  String _unit = 'dose';
  XFile? _pickedImage;
  bool _isLoading = false;

  static const _categories = [
    ('DETERGENT', 'Lessive'),
    ('SOFTENER', 'Adoucissant'),
    ('ACCESSORY', 'Accessoire'),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 800, imageQuality: 80);
    if (file != null) setState(() => _pickedImage = file);
  }

  Future<String?> _uploadPhoto(String productId) async {
    if (_pickedImage == null) return null;
    try {
      final ref = FirebaseStorage.instance.ref(
          'laundries/${widget.laundryId}/products/$productId/photo.jpg');
      await ref.putFile(File(_pickedImage!.path));
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final product = LaundryProductModel(
        id: '',
        laundryId: widget.laundryId,
        name: _nameCtrl.text.trim(),
        category: _category,
        description:
            _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
        pricePerUnit: double.parse(_priceCtrl.text.trim().replaceAll(',', '.')),
        stockQuantity: int.parse(_stockCtrl.text.trim()),
        unit: _unit,
      );

      final productId = await _repo.addProduct(
          laundryId: widget.laundryId, product: product);

      final photoUrl = await _uploadPhoto(productId);
      if (photoUrl != null) {
        await _repo.updateProduct(
          laundryId: widget.laundryId,
          productId: productId,
          fields: {'photoUrl': photoUrl},
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produit ajouté !'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur : $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text('Ajouter un produit', style: tt.titleLarge),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // ── Photo ──────────────────────────────────────────────────
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: _pickedImage != null
                    ? ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        child: Image.file(File(_pickedImage!.path),
                            fit: BoxFit.cover, width: double.infinity),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const PhosphorIcon(PhosphorIconsRegular.image,
                              size: 32, color: AppColors.textSecondary),
                          const SizedBox(height: AppSpacing.xs),
                          Text('Ajouter une photo (optionnel)',
                              style: tt.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Nom ────────────────────────────────────────────────────
            _FieldLabel('Nom du produit', tt),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: _nameCtrl,
              style: tt.bodyMedium,
              decoration: _inputDeco('Ariel Pods, Lenor Adoucissant…', tt),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Champ obligatoire' : null,
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Catégorie ──────────────────────────────────────────────
            _FieldLabel('Catégorie', tt),
            const SizedBox(height: AppSpacing.xs),
            Container(
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _category,
                  isExpanded: true,
                  style: tt.bodyMedium?.copyWith(color: AppColors.textPrimary),
                  items: _categories
                      .map((c) => DropdownMenuItem(
                            value: c.$1,
                            child: Text(c.$2),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _category = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Description ────────────────────────────────────────────
            _FieldLabel('Description (optionnel)', tt),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: _descCtrl,
              style: tt.bodyMedium,
              maxLines: 3,
              decoration: _inputDeco('Informations complémentaires…', tt),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Prix ───────────────────────────────────────────────────
            _FieldLabel('Prix par unité', tt),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: _priceCtrl,
              style: tt.bodyMedium,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
              ],
              decoration: _inputDeco('0.30', tt).copyWith(suffixText: '€'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Champ obligatoire';
                final parsed =
                    double.tryParse(v.trim().replaceAll(',', '.'));
                if (parsed == null || parsed < 0) return 'Prix invalide';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Quantité ───────────────────────────────────────────────
            _FieldLabel('Stock initial', tt),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: _stockCtrl,
              style: tt.bodyMedium,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _inputDeco('Ex : 50', tt),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Champ obligatoire';
                final parsed = int.tryParse(v.trim());
                if (parsed == null || parsed < 0) return 'Quantité invalide';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Unité ──────────────────────────────────────────────────
            _FieldLabel('Unité', tt),
            const SizedBox(height: AppSpacing.xs),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'dose', label: Text('dose')),
                ButtonSegment(value: 'unité', label: Text('unité')),
              ],
              selected: {_unit},
              onSelectionChanged: (s) =>
                  setState(() => _unit = s.first),
              style: ButtonStyle(
                side: WidgetStateProperty.all(
                    const BorderSide(color: AppColors.border)),
                backgroundColor: WidgetStateProperty.resolveWith((states) =>
                    states.contains(WidgetState.selected)
                        ? AppColors.primary
                        : AppColors.surface),
                foregroundColor: WidgetStateProperty.resolveWith((states) =>
                    states.contains(WidgetState.selected)
                        ? AppColors.surface
                        : AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          child: FilledButton(
            onPressed: _isLoading ? null : _submit,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: AppColors.surface, strokeWidth: 2.5))
                : const Text('Ajouter le produit'),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, TextTheme tt) => InputDecoration(
        hintText: hint,
        hintStyle: tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final TextTheme tt;
  const _FieldLabel(this.text, this.tt);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: tt.labelSmall?.copyWith(
            fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      );
}
