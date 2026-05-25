import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../data/providers/laundry_providers.dart';
import '../../domain/models/laundry_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class CreateLaundryScreen extends ConsumerStatefulWidget {
  const CreateLaundryScreen({super.key});

  @override
  ConsumerState<CreateLaundryScreen> createState() =>
      _CreateLaundryScreenState();
}

class _CreateLaundryScreenState extends ConsumerState<CreateLaundryScreen> {
  int _step = 0;
  static const _totalSteps = 4;
  bool _isLoading = false;
  bool _guardChecked = false;

  @override
  void initState() {
    super.initState();
    _checkExistingLaundry();
  }

  Future<void> _checkExistingLaundry() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final existing = await ref.read(laundryRepositoryProvider).getOwnerLaundry(uid);
    if (!mounted) return;
    if (existing != null) {
      // Laverie déjà existante : dialog + redirect
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
            title: const Text('Laverie déjà existante'),
            content: const Text(
                'Vous avez déjà créé une laverie. Vous pouvez la modifier '
                'depuis votre tableau de bord.'),
            actions: [
              FilledButton(
                onPressed: () => context.go('/owner-dashboard'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                ),
                child: const Text('Aller à mon tableau de bord'),
              ),
            ],
          ),
        );
      });
    }
    setState(() => _guardChecked = true);
  }

  // ── Étape 1 : Infos générales ──────────────────────────────
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  double? _latitude;
  double? _longitude;
  String? _resolvedAddress;
  bool _addressVerified = false;
  bool _isGeocoding = false;

  // ── Étape 2 : Horaires ────────────────────────────────────
  static const _dayKeys = [
    'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'
  ];
  static const _dayLabels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
  final Map<String, bool> _dayEnabled = {
    for (final d in ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'])
      d: false
  };
  final Map<String, TimeOfDay> _openTimes = {
    for (final d in ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'])
      d: const TimeOfDay(hour: 8, minute: 0)
  };
  final Map<String, TimeOfDay> _closeTimes = {
    for (final d in ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'])
      d: const TimeOfDay(hour: 20, minute: 0)
  };

  // ── Étape 3 : Services ────────────────────────────────────
  bool _offersFolding = false;
  bool _offersPickup = false;
  bool _offersDelivery = false;
  final _deliveryFeeCtrl = TextEditingController();
  final _deliveryZoneCtrl = TextEditingController();

  // ── Étape 4 : Photos ──────────────────────────────────────
  final List<XFile> _photos = [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _deliveryFeeCtrl.dispose();
    _deliveryZoneCtrl.dispose();
    super.dispose();
  }

  // ── Géocodage ─────────────────────────────────────────────
  Future<void> _geocodeAddress() async {
    final raw = _addressCtrl.text.trim();
    if (raw.isEmpty) return;
    setState(() { _isGeocoding = true; _addressVerified = false; });
    try {
      final locs = await locationFromAddress(raw);
      if (locs.isEmpty) throw Exception('Aucun résultat');
      final loc = locs.first;
      String resolved = raw;
      try {
        final placemarks =
            await placemarkFromCoordinates(loc.latitude, loc.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = [
            if (p.street?.isNotEmpty == true) p.street,
            if (p.postalCode?.isNotEmpty == true) p.postalCode,
            if (p.locality?.isNotEmpty == true) p.locality,
          ];
          if (parts.isNotEmpty) resolved = parts.join(', ');
        }
      } catch (_) {}
      setState(() {
        _latitude = loc.latitude;
        _longitude = loc.longitude;
        _resolvedAddress = resolved;
        _addressVerified = true;
        _isGeocoding = false;
      });
    } catch (e) {
      setState(() { _isGeocoding = false; _addressVerified = false; });
      _snack('Adresse introuvable. Vérifiez le format (rue, code postal, ville).');
    }
  }

  // ── Validation par étape ───────────────────────────────────
  bool _validateCurrentStep() {
    if (_step == 0) {
      if (_nameCtrl.text.trim().isEmpty) {
        _snack('Le nom de la laverie est obligatoire.');
        return false;
      }
      if (!_addressVerified) {
        _snack('Veuillez vérifier l\'adresse.');
        return false;
      }
    }
    if (_step == 3 && _offersFolding == false && _offersPickup == false && _offersDelivery == false) {
      // Services optionnels, aucune validation requise
    }
    return true;
  }

  // ── Soumettre ─────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_validateCurrentStep()) return;
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Non connecté');

      final openingHours = <String, String>{};
      for (final d in _dayKeys) {
        if (_dayEnabled[d] == true) {
          final open = _openTimes[d]!;
          final close = _closeTimes[d]!;
          openingHours[d] =
              '${open.hour}h${open.minute.toString().padLeft(2, '0')}-${close.hour}h${close.minute.toString().padLeft(2, '0')}';
        }
      }

      double? deliveryFee;
      int? deliveryZoneKm;
      if (_offersDelivery) {
        deliveryFee = double.tryParse(
            _deliveryFeeCtrl.text.replaceAll(',', '.'));
        deliveryZoneKm = int.tryParse(_deliveryZoneCtrl.text);
      }

      final laundry = LaundryModel(
        id: '',
        ownerId: uid,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        address: _resolvedAddress ?? _addressCtrl.text.trim(),
        latitude: _latitude!,
        longitude: _longitude!,
        openingHours: openingHours,
        offersFolding: _offersFolding,
        offersPickup: _offersPickup,
        offersDelivery: _offersDelivery,
        deliveryFee: deliveryFee,
        deliveryZoneKm: deliveryZoneKm,
      );

      final laundryId =
          await ref.read(laundryRepositoryProvider).createLaundry(laundry);

      // Upload photos
      if (_photos.isNotEmpty) {
        final urls = <String>[];
        for (int i = 0; i < _photos.length; i++) {
          final bytes = await _photos[i].readAsBytes();
          final ref2 = FirebaseStorage.instance
              .ref()
              .child('laundries/$laundryId/photos/photo_$i.jpg');
          await ref2.putData(
              bytes, SettableMetadata(contentType: 'image/jpeg'));
          urls.add(await ref2.getDownloadURL());
        }
        await ref
            .read(laundryRepositoryProvider)
            .updateLaundry(laundryId, {'photoUrls': urls});
      }

      if (mounted) {
        setState(() => _isLoading = false);
        _snack('Votre laverie a été créée avec succès !');
        context.pushReplacement('/laundry/$laundryId/machine/add',
            extra: laundryId);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _snack('Erreur : $e');
      }
    }
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

  // ── Photos ────────────────────────────────────────────────
  Future<void> _pickPhotos() async {
    final remaining = 5 - _photos.length;
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

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    // Affiche un écran de chargement pendant la vérification du guard
    if (!_guardChecked) {
      return const Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text('Créer ma laverie', style: tt.titleLarge),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: Column(
        children: [
          // ── Indicateur de progression ────────────────────────
          _StepIndicator(current: _step, total: _totalSteps),

          // ── Contenu de l'étape ───────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: ListView(
                key: ValueKey(_step),
                padding: AppSpacing.pagePadding,
                children: [
                  if (_step == 0) _buildStep1(),
                  if (_step == 1) _buildStep2(),
                  if (_step == 2) _buildStep3(),
                  if (_step == 3) _buildStep4(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Navigation entre étapes ──────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          child: Row(
            children: [
              if (_step > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _step--),
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      side: const BorderSide(color: AppColors.border),
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd)),
                    ),
                    child: const Text('Précédent'),
                  ),
                ),
              if (_step > 0) const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (!_validateCurrentStep()) return;
                          if (_step < _totalSteps - 1) {
                            setState(() => _step++);
                          } else {
                            _submit();
                          }
                        },
                  style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: AppColors.surface, strokeWidth: 2),
                        )
                      : Text(_step < _totalSteps - 1
                          ? 'Suivant'
                          : 'Créer ma laverie'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Étape 1 : Infos générales ──────────────────────────────
  Widget _buildStep1() {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Informations générales', style: tt.titleMedium),
        AppSpacing.gapXl,
        _FieldLabel('Nom de la laverie *'),
        AppSpacing.gapSm,
        _StyledField(
          controller: _nameCtrl,
          hint: 'Ex: Laverie du Marché',
        ),
        AppSpacing.gapLg,
        _FieldLabel('Description (optionnel)'),
        AppSpacing.gapSm,
        _StyledField(
          controller: _descCtrl,
          hint: 'Décrivez votre laverie, l\'accès, les équipements…',
          maxLines: 3,
        ),
        AppSpacing.gapLg,
        _FieldLabel('Adresse complète *'),
        AppSpacing.gapSm,
        Row(
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: _addressVerified
                      ? Border.all(color: AppColors.success, width: 1.5)
                      : null,
                ),
                child: TextField(
                  controller: _addressCtrl,
                  onChanged: (_) {
                    if (_addressVerified) {
                      setState(() {
                        _addressVerified = false;
                        _latitude = null;
                        _longitude = null;
                        _resolvedAddress = null;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    hintText: '12 rue de la Paix, 75001 Paris',
                    hintStyle:
                        TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    prefixIcon: PhosphorIcon(
                      _addressVerified
                          ? PhosphorIconsRegular.checkCircle
                          : PhosphorIconsRegular.mapPin,
                      size: 18,
                      color: _addressVerified
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: _isGeocoding ? null : _geocodeAddress,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                alignment: Alignment.center,
                child: _isGeocoding
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: AppColors.surface, strokeWidth: 2),
                      )
                    : const PhosphorIcon(PhosphorIconsRegular.magnifyingGlass,
                        size: 18, color: AppColors.surface),
              ),
            ),
          ],
        ),
        if (_addressVerified && _resolvedAddress != null) ...[
          AppSpacing.gapSm,
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.confirmedBg,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(children: [
              const PhosphorIcon(PhosphorIconsRegular.check,
                  size: 14, color: AppColors.confirmedText),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  _resolvedAddress!,
                  style: TextStyle(
                      color: AppColors.confirmedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ),
        ] else if (_addressCtrl.text.isNotEmpty && !_addressVerified) ...[
          AppSpacing.gapSm,
          Text(
            'Cliquez sur la loupe pour vérifier l\'adresse.',
            style: TextStyle(fontSize: 11, color: AppColors.warning),
          ),
        ],
      ],
    );
  }

  // ── Étape 2 : Horaires ────────────────────────────────────
  Widget _buildStep2() {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Horaires d\'ouverture', style: tt.titleMedium),
        AppSpacing.gapSm,
        Text(
          'Définissez vos jours et plages horaires d\'ouverture.',
          style: tt.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        AppSpacing.gapXl,
        ..._dayKeys.asMap().entries.map((e) {
          final idx = e.key;
          final day = e.value;
          final enabled = _dayEnabled[day] ?? false;
          return _DayRow(
            label: _dayLabels[idx],
            fullLabel: day,
            enabled: enabled,
            openTime: _openTimes[day]!,
            closeTime: _closeTimes[day]!,
            onToggle: (v) => setState(() => _dayEnabled[day] = v),
            onOpenTap: () async {
              final t = await showTimePicker(
                  context: context, initialTime: _openTimes[day]!);
              if (t != null) setState(() => _openTimes[day] = t);
            },
            onCloseTap: () async {
              final t = await showTimePicker(
                  context: context, initialTime: _closeTimes[day]!);
              if (t != null) setState(() => _closeTimes[day] = t);
            },
          );
        }),
      ],
    );
  }

  // ── Étape 3 : Services ────────────────────────────────────
  Widget _buildStep3() {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Services proposés', style: tt.titleMedium),
        AppSpacing.gapSm,
        Text(
          'Ces options seront visibles par vos clients.',
          style: tt.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        AppSpacing.gapXl,
        _ServiceSwitch(
          title: 'Je propose le pliage',
          subtitle: 'Vous pliez le linge de vos clients',
          value: _offersFolding,
          onChanged: (v) => setState(() => _offersFolding = v),
        ),
        AppSpacing.gapMd,
        _ServiceSwitch(
          title: 'Je viens chercher le linge',
          subtitle: 'Collecte à domicile proposée',
          value: _offersPickup,
          onChanged: (v) => setState(() => _offersPickup = v),
        ),
        AppSpacing.gapMd,
        _ServiceSwitch(
          title: 'Je livre le linge propre',
          subtitle: 'Livraison à domicile proposée',
          value: _offersDelivery,
          onChanged: (v) => setState(() => _offersDelivery = v),
        ),
        if (_offersDelivery) ...[
          AppSpacing.gapLg,
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel('Frais de livraison (€)'),
                AppSpacing.gapSm,
                _StyledField(
                  controller: _deliveryFeeCtrl,
                  hint: 'Ex: 5.00',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                AppSpacing.gapLg,
                _FieldLabel('Rayon de livraison (km)'),
                AppSpacing.gapSm,
                _StyledField(
                  controller: _deliveryZoneCtrl,
                  hint: 'Ex: 10',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Étape 4 : Photos ──────────────────────────────────────
  Widget _buildStep4() {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Photos de votre laverie', style: tt.titleMedium),
        AppSpacing.gapSm,
        Text(
          'Ajoutez jusqu\'à 5 photos pour attirer vos clients.',
          style: tt.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        AppSpacing.gapXl,

        // Grille 2 colonnes
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.2,
          ),
          itemCount: _photos.length + (_photos.length < 5 ? 1 : 0),
          itemBuilder: (context, i) {
            if (i == _photos.length) {
              return GestureDetector(
                onTap: _pickPhotos,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(
                        color: AppColors.border,
                        style: BorderStyle.solid),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PhosphorIcon(PhosphorIconsRegular.plus,
                          size: 28, color: AppColors.primary),
                      SizedBox(height: AppSpacing.sm),
                      Text('Ajouter',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              );
            }
            return Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusLg),
                  child: Image.file(
                    File(_photos[i].path),
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                if (i == 0)
                  Positioned(
                    bottom: AppSpacing.sm,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusFull),
                        ),
                        child: const Text('Principale',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: GestureDetector(
                    onTap: () => setState(() => _photos.removeAt(i)),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const PhosphorIcon(PhosphorIconsRegular.x,
                          size: 13, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets utilitaires
// ─────────────────────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Étape ${current + 1} sur $total',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: (current + 1) / total,
              backgroundColor: AppColors.border,
              color: AppColors.primary,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final String label;
  final String fullLabel;
  final bool enabled;
  final TimeOfDay openTime;
  final TimeOfDay closeTime;
  final ValueChanged<bool> onToggle;
  final VoidCallback onOpenTap;
  final VoidCallback onCloseTap;

  const _DayRow({
    required this.label,
    required this.fullLabel,
    required this.enabled,
    required this.openTime,
    required this.closeTime,
    required this.onToggle,
    required this.onOpenTap,
    required this.onCloseTap,
  });

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}h${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
            color: enabled ? AppColors.primary : AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              label,
              style: tt.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color:
                    enabled ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
          Switch(
            value: enabled,
            onChanged: onToggle,
            activeThumbColor: AppColors.surface,
            activeTrackColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          if (enabled) ...[
            const Spacer(),
            GestureDetector(
              onTap: onOpenTap,
              child: _TimeChip(time: _fmtTime(openTime), label: 'Ouverture'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text('→',
                  style: tt.bodySmall
                      ?.copyWith(color: AppColors.textSecondary)),
            ),
            GestureDetector(
              onTap: onCloseTap,
              child:
                  _TimeChip(time: _fmtTime(closeTime), label: 'Fermeture'),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String time;
  final String label;
  const _TimeChip({required this.time, required this.label});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.completedBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Text(
        time,
        style: tt.labelLarge
            ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ServiceSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ServiceSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
            color: value ? AppColors.primary : AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: tt.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: tt.bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.surface,
            activeTrackColor: AppColors.primary,
          ),
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
              fontWeight: FontWeight.w700,
              color: AppColors.textBody,
              fontSize: 12,
            ),
      );
}

class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _StyledField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
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
        maxLines: maxLines,
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
