import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../data/providers/machine_providers.dart';
import '../../domain/models/machine_model.dart';
import '../../domain/models/wash_program_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class AddMachineScreen extends ConsumerStatefulWidget {
  final String laundryId;

  const AddMachineScreen({super.key, required this.laundryId});

  @override
  ConsumerState<AddMachineScreen> createState() => _AddMachineScreenState();
}

class _AddMachineScreenState extends ConsumerState<AddMachineScreen> {
  final _nicknameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  final List<WashProgram> _programs = [];
  final List<XFile> _photos = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _capacityCtrl.dispose();
    _yearCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  bool get _isValid {
    return _nicknameCtrl.text.trim().isNotEmpty &&
        _brandCtrl.text.trim().isNotEmpty &&
        int.tryParse(_capacityCtrl.text) != null &&
        _programs.isNotEmpty;
  }

  Future<void> _addProgram() async {
    final result = await showModalBottomSheet<WashProgram>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ProgramBottomSheet(),
    );
    if (result != null && mounted) {
      setState(() => _programs.add(result));
    }
  }

  Future<void> _pickPhotos() async {
    final remaining = 3 - _photos.length;
    if (remaining <= 0) return;
    final picked = await ImagePicker().pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
      limit: remaining,
    );
    if (picked.isNotEmpty && mounted) {
      setState(() => _photos.addAll(picked.take(remaining)));
    }
  }

  Future<void> _submit({bool addAnother = false}) async {
    if (!_isValid) {
      _snack('Veuillez remplir tous les champs obligatoires et ajouter au moins un programme.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Non connecté');

      final capacity = int.parse(_capacityCtrl.text.trim());
      final price = double.tryParse(
              _priceCtrl.text.trim().replaceAll(',', '.')) ??
          4.0;
      final year = int.tryParse(_yearCtrl.text.trim());

      final machine = MachineModel(
        id: '',
        ownerId: uid,
        laundryId: widget.laundryId,
        nickname: _nicknameCtrl.text.trim(),
        brand: _brandCtrl.text.trim(),
        model: _modelCtrl.text.trim().isEmpty ? null : _modelCtrl.text.trim(),
        capacityKg: capacity,
        manufactureYear: year,
        pricePerWash: price,
        description: '',
        latitude: 0,
        longitude: 0,
        photoUrls: const [],
        programs: List.from(_programs),
      );

      final machineId = await ref.read(machineRepositoryProvider).addMachine(
            laundryId: widget.laundryId,
            machine: machine,
          );

      // Upload photos
      if (_photos.isNotEmpty) {
        final urls = <String>[];
        for (int i = 0; i < _photos.length; i++) {
          final bytes = await _photos[i].readAsBytes();
          final storageRef = FirebaseStorage.instance.ref().child(
              'laundries/${widget.laundryId}/machines/$machineId/photos/photo_$i.jpg');
          await storageRef.putData(
              bytes, SettableMetadata(contentType: 'image/jpeg'));
          urls.add(await storageRef.getDownloadURL());
        }
        await ref.read(machineRepositoryProvider).updateMachine(
              laundryId: widget.laundryId,
              machineId: machineId,
              fields: {'media': {'photoUrls': urls}},
            );
      }

      if (mounted) {
        setState(() => _isLoading = false);
        _snack('Machine ajoutée avec succès !');
        if (addAnother) {
          _reset();
        } else {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _snack('Erreur : $e');
      }
    }
  }

  void _reset() {
    _nicknameCtrl.clear();
    _brandCtrl.clear();
    _modelCtrl.clear();
    _capacityCtrl.clear();
    _yearCtrl.clear();
    _priceCtrl.clear();
    setState(() {
      _programs.clear();
      _photos.clear();
    });
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text('Ajouter une machine', style: tt.titleLarge),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: ListView(
        padding: AppSpacing.pagePadding,
        children: [
          // ── Identité ──────────────────────────────────────────
          _SectionCard(
            title: 'IDENTITÉ',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel('Surnom de la machine *'),
                AppSpacing.gapSm,
                _StyledField(
                    controller: _nicknameCtrl,
                    hint: 'Ex: Machine principale, LG du couloir'),
                AppSpacing.gapLg,
                Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel('Marque *'),
                        AppSpacing.gapSm,
                        _StyledField(
                            controller: _brandCtrl, hint: 'Ex: LG, Bosch'),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel('Modèle (optionnel)'),
                        AppSpacing.gapSm,
                        _StyledField(
                            controller: _modelCtrl,
                            hint: 'Ex: F4WV510S0E'),
                      ],
                    ),
                  ),
                ]),
                AppSpacing.gapLg,
                Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel('Capacité (kg) *'),
                        AppSpacing.gapSm,
                        _StyledField(
                          controller: _capacityCtrl,
                          hint: '7',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel('Année fabrication'),
                        AppSpacing.gapSm,
                        _StyledField(
                          controller: _yearCtrl,
                          hint: '2020',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                        ),
                      ],
                    ),
                  ),
                ]),
                AppSpacing.gapLg,
                _FieldLabel('Prix par lavage (€)'),
                AppSpacing.gapSm,
                _StyledField(
                  controller: _priceCtrl,
                  hint: '4.00',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),

          AppSpacing.gapLg,

          // ── Programmes ────────────────────────────────────────
          _SectionCard(
            title: 'PROGRAMMES DE LAVAGE',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_programs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text(
                      'Ajoutez au moins un programme pour valider.',
                      style: tt.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ..._programs.asMap().entries.map((e) {
                  final i = e.key;
                  final p = e.value;
                  return _ProgramTile(
                    program: p,
                    onDelete: () => setState(() => _programs.removeAt(i)),
                  );
                }),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _addProgram,
                    icon: const PhosphorIcon(PhosphorIconsRegular.plus,
                        size: 16),
                    label: const Text('Ajouter un programme'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          AppSpacing.gapLg,

          // ── Photos ────────────────────────────────────────────
          _SectionCard(
            title: 'PHOTOS (MAX 3)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      if (_photos.length < 3)
                        GestureDetector(
                          onTap: _pickPhotos,
                          child: Container(
                            width: 88,
                            margin: const EdgeInsets.only(right: AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.inputBackground,
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                PhosphorIcon(PhosphorIconsRegular.plus,
                                    size: 24, color: AppColors.primary),
                                SizedBox(height: AppSpacing.xs),
                                Text('Ajouter',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ..._photos.asMap().entries.map((e) {
                        final i = e.key;
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd),
                              child: Image.file(
                                File(e.value.path),
                                width: 88,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _photos.removeAt(i)),
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: Colors.black
                                        .withValues(alpha: 0.55),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const PhosphorIcon(
                                      PhosphorIconsRegular.x,
                                      size: 12,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 120),
        ],
      ),

      // ── CTAs ──────────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton(
                      onPressed: _isValid ? () => _submit() : null,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 0),
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg),
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.border,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd)),
                      ),
                      child: const Text('Ajouter la machine'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed:
                          _isValid ? () => _submit(addAnother: true) : null,
                      child: const Text('Ajouter une autre machine'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ProgramBottomSheet
// ─────────────────────────────────────────────────────────────────────────────

class _ProgramBottomSheet extends StatefulWidget {
  const _ProgramBottomSheet();

  @override
  State<_ProgramBottomSheet> createState() => _ProgramBottomSheetState();
}

class _ProgramBottomSheetState extends State<_ProgramBottomSheet> {
  final _nameCtrl = TextEditingController();
  int _temp = 40;
  int _duration = 60;
  bool _hasSpin = true;
  int _spinSpeed = 1000;
  bool _isDelicate = false;

  static const _temps = [20, 30, 40, 60, 90];
  static const _spinSpeeds = [800, 1000, 1200, 1400];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radius2xl)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
            ),
            AppSpacing.gapLg,
            Text('Ajouter un programme', style: tt.titleMedium),
            AppSpacing.gapXl,

            // Nom
            _FieldLabel('Nom du programme *'),
            AppSpacing.gapSm,
            Container(
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Ex: Coton, Synthétiques, Délicat…',
                  hintStyle: TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                ),
              ),
            ),
            AppSpacing.gapLg,

            // Température
            _FieldLabel('Température'),
            AppSpacing.gapSm,
            _SegmentedPicker<int>(
              options: _temps,
              labelBuilder: (t) => '$t°C',
              selected: _temp,
              onChanged: (t) => setState(() => _temp = t),
            ),
            AppSpacing.gapLg,

            // Durée
            Row(children: [
              _FieldLabel('Durée : '),
              Text('$_duration min',
                  style: tt.labelLarge
                      ?.copyWith(color: AppColors.primary)),
            ]),
            Slider(
              value: _duration.toDouble(),
              min: 20,
              max: 150,
              divisions: 26,
              activeColor: AppColors.primary,
              inactiveColor: AppColors.border,
              onChanged: (v) => setState(() => _duration = v.round()),
            ),
            AppSpacing.gapMd,

            // Essorage
            _SwitchRow(
              title: 'Essorage',
              value: _hasSpin,
              onChanged: (v) => setState(() => _hasSpin = v),
            ),
            if (_hasSpin) ...[
              AppSpacing.gapMd,
              _FieldLabel('Vitesse d\'essorage'),
              AppSpacing.gapSm,
              _SegmentedPicker<int>(
                options: _spinSpeeds,
                labelBuilder: (s) => '${s}tr',
                selected: _spinSpeed,
                onChanged: (s) => setState(() => _spinSpeed = s),
              ),
            ],
            AppSpacing.gapMd,

            // Délicat
            _SwitchRow(
              title: 'Programme délicat',
              value: _isDelicate,
              onChanged: (v) => setState(() => _isDelicate = v),
            ),
            AppSpacing.gapXl,

            FilledButton(
              onPressed: _nameCtrl.text.trim().isEmpty
                  ? null
                  : () {
                      Navigator.pop(
                        context,
                        WashProgram(
                          id: DateTime.now()
                              .millisecondsSinceEpoch
                              .toString(),
                          name: _nameCtrl.text.trim(),
                          temperatureCelsius: _temp,
                          durationMinutes: _duration,
                          hasSpin: _hasSpin,
                          spinSpeedRpm: _hasSpin ? _spinSpeed : null,
                          isDelicate: _isDelicate,
                        ),
                      );
                    },
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 0),
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd)),
              ),
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets utilitaires partagés
// ─────────────────────────────────────────────────────────────────────────────

class _ProgramTile extends StatelessWidget {
  final WashProgram program;
  final VoidCallback onDelete;
  const _ProgramTile({required this.program, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.completedBg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          alignment: Alignment.center,
          child: Text('${program.temperatureCelsius}°',
              style: tt.labelLarge
                  ?.copyWith(color: AppColors.primary, fontSize: 11)),
        ),
        AppSpacing.hGapMd,
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(program.name,
                style: tt.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            Text(
              '${program.durationMinutes} min'
              '${program.hasSpin ? ' · ${program.spinSpeedRpm ?? ""}tr/min' : ''}'
              '${program.isDelicate ? ' · Délicat' : ''}',
              style:
                  tt.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ]),
        ),
        IconButton(
          icon: const PhosphorIcon(PhosphorIconsRegular.trash,
              size: 16, color: AppColors.error),
          onPressed: onDelete,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ]),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: tt.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.5)),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700, color: AppColors.textBody, fontSize: 12),
      );
}

class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _StyledField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
              color: AppColors.textSecondary, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        ),
      ),
    );
  }
}

class _SegmentedPicker<T> extends StatelessWidget {
  final List<T> options;
  final String Function(T) labelBuilder;
  final T selected;
  final ValueChanged<T> onChanged;

  const _SegmentedPicker({
    required this.options,
    required this.labelBuilder,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      children: options.map((opt) {
        final isSel = opt == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSel ? AppColors.primary : AppColors.inputBackground,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                    color: isSel ? AppColors.primary : AppColors.border),
              ),
              child: Text(
                labelBuilder(opt),
                style: tt.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isSel
                      ? AppColors.surface
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow(
      {required this.title, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(children: [
      Expanded(child: Text(title, style: tt.bodyMedium)),
      Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.surface,
        activeTrackColor: AppColors.primary,
      ),
    ]);
  }
}
