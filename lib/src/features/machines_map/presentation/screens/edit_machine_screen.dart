import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../data/providers/machine_providers.dart';
import '../../domain/models/machine_model.dart';
import '../../domain/models/wash_program_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class EditMachineScreen extends ConsumerStatefulWidget {
  final String laundryId;
  final String machineId;

  const EditMachineScreen({
    super.key,
    required this.laundryId,
    required this.machineId,
  });

  @override
  ConsumerState<EditMachineScreen> createState() => _EditMachineScreenState();
}

class _EditMachineScreenState extends ConsumerState<EditMachineScreen> {
  MachineModel? _machine;
  bool _loadingMachine = true;
  bool _isSaving = false;

  late TextEditingController _nicknameCtrl;
  late TextEditingController _brandCtrl;
  late TextEditingController _modelCtrl;
  late TextEditingController _capacityCtrl;
  late TextEditingController _yearCtrl;

  List<String> _existingPhotos = [];
  final List<XFile> _newPhotos = [];

  @override
  void initState() {
    super.initState();
    _nicknameCtrl = TextEditingController();
    _brandCtrl = TextEditingController();
    _modelCtrl = TextEditingController();
    _capacityCtrl = TextEditingController();
    _yearCtrl = TextEditingController();
    _loadMachine();
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _capacityCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMachine() async {
    final machine = await ref.read(machineRepositoryProvider).getMachine(
          laundryId: widget.laundryId,
          machineId: widget.machineId,
        );
    if (mounted && machine != null) {
      setState(() {
        _machine = machine;
        _nicknameCtrl.text = machine.nickname;
        _brandCtrl.text = machine.brand;
        _modelCtrl.text = machine.model ?? '';
        _capacityCtrl.text = machine.capacityKg.toString();
        _yearCtrl.text = machine.manufactureYear?.toString() ?? '';
        _existingPhotos = List.from(machine.photoUrls);
        _loadingMachine = false;
      });
    } else if (mounted) {
      setState(() => _loadingMachine = false);
    }
  }

  int get _totalPhotos => _existingPhotos.length + _newPhotos.length;

  Future<void> _pickPhotos() async {
    final remaining = 3 - _totalPhotos;
    if (remaining <= 0) return;
    final picked = await ImagePicker().pickMultiImage(
      maxWidth: 1920, maxHeight: 1920, imageQuality: 85, limit: remaining,
    );
    if (picked.isNotEmpty && mounted) {
      setState(() => _newPhotos.addAll(picked.take(remaining)));
    }
  }

  bool get _isValid =>
      _nicknameCtrl.text.trim().isNotEmpty &&
      _brandCtrl.text.trim().isNotEmpty &&
      int.tryParse(_capacityCtrl.text.trim()) != null;

  Future<void> _save() async {
    if (!_isValid) return;
    setState(() => _isSaving = true);
    try {
      // Upload nouvelles photos
      final newUrls = <String>[];
      for (int i = 0; i < _newPhotos.length; i++) {
        final bytes = await _newPhotos[i].readAsBytes();
        final ref = FirebaseStorage.instance.ref().child(
            'laundries/${widget.laundryId}/machines/${widget.machineId}/photos/photo_${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        newUrls.add(await ref.getDownloadURL());
      }

      final allPhotos = [..._existingPhotos, ...newUrls];

      await ref.read(machineRepositoryProvider).updateMachine(
        laundryId: widget.laundryId,
        machineId: widget.machineId,
        fields: {
          'nickname': _nicknameCtrl.text.trim(),
          'characteristics': {
            'brand': _brandCtrl.text.trim(),
            'capacityKg': int.parse(_capacityCtrl.text.trim()),
            'description': _machine?.description ?? '',
          },
          'model': _modelCtrl.text.trim().isEmpty ? null : _modelCtrl.text.trim(),
          'manufactureYear': _yearCtrl.text.trim().isEmpty
              ? null
              : int.tryParse(_yearCtrl.text.trim()),
          'media': {'photoUrls': allPhotos},
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Machine mise à jour avec succès !'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    if (_loadingMachine) {
      return const Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_machine == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(child: Text('Machine introuvable', style: tt.titleMedium)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text('Modifier la machine', style: tt.titleLarge),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: ListView(
        padding: AppSpacing.pagePadding,
        children: [
          // ── Identité ─────────────────────────────────────────────
          _Section(
            title: 'IDENTITÉ',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel('Surnom *'),
                AppSpacing.gapSm,
                _Field(controller: _nicknameCtrl, hint: 'Ex: Machine principale'),
                AppSpacing.gapLg,
                Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _FieldLabel('Marque *'),
                      AppSpacing.gapSm,
                      _Field(controller: _brandCtrl, hint: 'Ex: LG'),
                    ]),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _FieldLabel('Modèle'),
                      AppSpacing.gapSm,
                      _Field(controller: _modelCtrl, hint: 'Optionnel'),
                    ]),
                  ),
                ]),
                AppSpacing.gapLg,
                Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _FieldLabel('Capacité (kg) *'),
                      AppSpacing.gapSm,
                      _Field(
                        controller: _capacityCtrl,
                        hint: '7',
                        keyboardType: TextInputType.number,
                        formatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ]),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _FieldLabel('Année fabrication'),
                      AppSpacing.gapSm,
                      _Field(
                        controller: _yearCtrl,
                        hint: '2020',
                        keyboardType: TextInputType.number,
                        formatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                      ),
                    ]),
                  ),
                ]),
              ],
            ),
          ),

          AppSpacing.gapLg,

          // ── Photos ───────────────────────────────────────────────
          _Section(
            title: 'PHOTOS (MAX 3)',
            child: SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (_totalPhotos < 3)
                    GestureDetector(
                      onTap: _pickPhotos,
                      child: Container(
                        width: 88,
                        margin: const EdgeInsets.only(right: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            PhosphorIcon(PhosphorIconsRegular.plus, size: 24, color: AppColors.primary),
                            SizedBox(height: AppSpacing.xs),
                            Text('Ajouter', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ..._existingPhotos.asMap().entries.map((e) => _PhotoThumb(
                        url: e.value,
                        onRemove: () => setState(() => _existingPhotos.removeAt(e.key)),
                      )),
                  ..._newPhotos.asMap().entries.map((e) => _PhotoThumbLocal(
                        file: File(e.value.path),
                        onRemove: () => setState(() => _newPhotos.removeAt(e.key)),
                      )),
                ],
              ),
            ),
          ),

          AppSpacing.gapLg,

          // ── Programmes (read-only) ───────────────────────────────
          _Section(
            title: 'PROGRAMMES',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Row(children: [
                    const PhosphorIcon(PhosphorIconsRegular.info,
                        size: 14, color: AppColors.textSecondary),
                    AppSpacing.hGapSm,
                    Expanded(
                      child: Text(
                        'Non modifiables après création',
                        style: tt.labelSmall?.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ]),
                ),
                AppSpacing.gapSm,
                Text(
                  'Supprimez et recréez la machine pour changer les programmes.',
                  style: tt.labelSmall?.copyWith(color: AppColors.textSecondary),
                ),
                AppSpacing.gapMd,
                Opacity(
                  opacity: 0.6,
                  child: Column(
                    children: _machine!.programs.map((p) => _ProgramRow(program: p)).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          child: FilledButton(
            onPressed: (_isValid && !_isSaving) ? _save : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.border,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: AppColors.surface, strokeWidth: 2),
                  )
                : const Text('Enregistrer les modifications'),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets internes
// ─────────────────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: tt.labelSmall?.copyWith(
                fontSize: 10, fontWeight: FontWeight.w800,
                color: AppColors.textSecondary, letterSpacing: 1.5)),
        const SizedBox(height: AppSpacing.lg),
        child,
      ]),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700, color: AppColors.textBody, fontSize: 12));
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? formatters;
  const _Field({required this.controller, required this.hint, this.keyboardType, this.formatters});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: formatters,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          ),
        ),
      );
}

class _ProgramRow extends StatelessWidget {
  final WashProgram program;
  const _ProgramRow({required this.program});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.completedBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text('${program.temperatureCelsius}°',
              style: tt.labelSmall?.copyWith(
                  color: AppColors.primary, fontWeight: FontWeight.w700)),
        ),
        AppSpacing.hGapMd,
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(program.name,
                style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            Text(
              '${program.durationMinutes} min'
              '${program.hasSpin ? ' · ${program.spinSpeedRpm ?? ""}tr/min' : ''}'
              '${program.isDelicate ? ' · Délicat' : ''}',
              style: tt.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  final String url;
  final VoidCallback onRemove;
  const _PhotoThumb({required this.url, required this.onRemove});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: AppSpacing.md),
        child: Stack(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Image.network(url, width: 88, height: 100, fit: BoxFit.cover),
          ),
          Positioned(
            top: 4, right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55), shape: BoxShape.circle),
                child: const PhosphorIcon(PhosphorIconsRegular.x, size: 12, color: Colors.white),
              ),
            ),
          ),
        ]),
      );
}

class _PhotoThumbLocal extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;
  const _PhotoThumbLocal({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: AppSpacing.md),
        child: Stack(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Image.file(file, width: 88, height: 100, fit: BoxFit.cover),
          ),
          Positioned(
            top: 4, right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55), shape: BoxShape.circle),
                child: const PhosphorIcon(PhosphorIconsRegular.x, size: 12, color: Colors.white),
              ),
            ),
          ),
        ]),
      );
}

