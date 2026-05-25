import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geocoding/geocoding.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../data/providers/laundry_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class EditLaundryScreen extends ConsumerStatefulWidget {
  final String laundryId;
  const EditLaundryScreen({super.key, required this.laundryId});

  @override
  ConsumerState<EditLaundryScreen> createState() => _EditLaundryScreenState();
}

class _EditLaundryScreenState extends ConsumerState<EditLaundryScreen> {
  bool _loadingLaundry = true;
  bool _isSaving = false;
  int _step = 0;

  // Étape 0 — Infos
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  double? _latitude;
  double? _longitude;
  String? _resolvedAddress;
  bool _addressVerified = false;
  bool _isGeocoding = false;

  // Étape 1 — Horaires
  static const _dayKeys = ['lundi','mardi','mercredi','jeudi','vendredi','samedi','dimanche'];
  static const _dayLabels = ['Lun','Mar','Mer','Jeu','Ven','Sam','Dim'];
  final Map<String, bool> _dayEnabled = {for (final d in _dayKeys) d: false};
  final Map<String, TimeOfDay> _openTimes = {for (final d in _dayKeys) d: const TimeOfDay(hour: 8, minute: 0)};
  final Map<String, TimeOfDay> _closeTimes = {for (final d in _dayKeys) d: const TimeOfDay(hour: 20, minute: 0)};

  // Étape 2 — Services
  bool _offersFolding = false;
  bool _offersPickup = false;
  bool _offersDelivery = false;
  final _deliveryFeeCtrl = TextEditingController();
  final _deliveryZoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLaundry();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _deliveryFeeCtrl.dispose();
    _deliveryZoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLaundry() async {
    final laundry = await ref.read(laundryRepositoryProvider).getLaundryById(widget.laundryId);
    if (mounted && laundry != null) {
      _nameCtrl.text = laundry.name;
      _descCtrl.text = laundry.description ?? '';
      _addressCtrl.text = laundry.address;
      _latitude = laundry.latitude;
      _longitude = laundry.longitude;
      _resolvedAddress = laundry.address;
      _addressVerified = true;
      _offersFolding = laundry.offersFolding;
      _offersPickup = laundry.offersPickup;
      _offersDelivery = laundry.offersDelivery;
      _deliveryFeeCtrl.text = laundry.deliveryFee?.toStringAsFixed(2) ?? '';
      _deliveryZoneCtrl.text = laundry.deliveryZoneKm?.toString() ?? '';

      // Horaires
      for (final d in _dayKeys) {
        if (laundry.openingHours.containsKey(d)) {
          _dayEnabled[d] = true;
          final raw = laundry.openingHours[d]!;
          final parts = raw.split('-');
          if (parts.length == 2) {
            _openTimes[d] = _parseTime(parts[0]);
            _closeTimes[d] = _parseTime(parts[1]);
          }
        }
      }

      setState(() { _loadingLaundry = false; });
    } else if (mounted) {
      setState(() => _loadingLaundry = false);
    }
  }

  TimeOfDay _parseTime(String s) {
    final parts = s.replaceAll('h', ':').split(':');
    if (parts.length >= 2) {
      return TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 8,
        minute: int.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
      );
    }
    return const TimeOfDay(hour: 8, minute: 0);
  }

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
        final pm = await placemarkFromCoordinates(loc.latitude, loc.longitude);
        if (pm.isNotEmpty) {
          final p = pm.first;
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
      setState(() { _isGeocoding = false; });
      _snack('Adresse introuvable. Vérifiez le format.');
    }
  }

  bool _validateStep() {
    if (_step == 0) {
      if (_nameCtrl.text.trim().isEmpty) { _snack('Le nom est obligatoire.'); return false; }
      if (!_addressVerified) { _snack('Veuillez vérifier l\'adresse.'); return false; }
    }
    return true;
  }

  Future<void> _save() async {
    if (!_validateStep()) return;
    setState(() => _isSaving = true);
    try {
      final openingHours = <String, String>{};
      for (final d in _dayKeys) {
        if (_dayEnabled[d] == true) {
          final o = _openTimes[d]!;
          final c = _closeTimes[d]!;
          openingHours[d] = '${o.hour}h${o.minute.toString().padLeft(2,'0')}-${c.hour}h${c.minute.toString().padLeft(2,'0')}';
        }
      }

      final fields = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'address': _resolvedAddress ?? _addressCtrl.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
        'openingHours': openingHours,
        'service': {
          'offersFolding': _offersFolding,
          'offersPickup': _offersPickup,
          'offersDelivery': _offersDelivery,
          'deliveryFee': _offersDelivery ? double.tryParse(_deliveryFeeCtrl.text.replaceAll(',', '.')) : null,
          'deliveryZoneKm': _offersDelivery ? int.tryParse(_deliveryZoneCtrl.text) : null,
        },
      };

      await ref.read(laundryRepositoryProvider).updateLaundry(widget.laundryId, fields);

      if (mounted) {
        _snack('Laverie mise à jour avec succès !');
        context.pop();
      }
    } catch (e) {
      if (mounted) { setState(() => _isSaving = false); _snack('Erreur : $e'); }
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    if (_loadingLaundry) {
      return const Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final stepLabels = ['Infos', 'Horaires', 'Services'];

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text('Modifier la laverie', style: tt.titleLarge),
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
          // Indicateur
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Étape ${_step + 1} sur 3 · ${stepLabels[_step]}',
                  style: tt.labelSmall?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                child: LinearProgressIndicator(
                  value: (_step + 1) / 3,
                  backgroundColor: AppColors.border,
                  color: AppColors.primary,
                  minHeight: 4,
                ),
              ),
            ]),
          ),

          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: ListView(
                key: ValueKey(_step),
                padding: AppSpacing.pagePadding,
                children: [
                  if (_step == 0) _buildStep0(tt),
                  if (_step == 1) _buildStep1(tt),
                  if (_step == 2) _buildStep2(tt),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          child: Row(children: [
            if (_step > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _step--),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    side: const BorderSide(color: AppColors.border),
                    foregroundColor: AppColors.textPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                  ),
                  child: const Text('Précédent'),
                ),
              ),
            if (_step > 0) const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _isSaving ? null : () {
                  if (!_validateStep()) return;
                  if (_step < 2) { setState(() => _step++); }
                  else { _save(); }
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: AppColors.surface, strokeWidth: 2))
                    : Text(_step < 2 ? 'Suivant' : 'Enregistrer'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildStep0(TextTheme tt) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Informations générales', style: tt.titleMedium),
          AppSpacing.gapXl,
          _Label('Nom de la laverie *'),
          AppSpacing.gapSm,
          _TF(controller: _nameCtrl, hint: 'Ex: Laverie du Marché'),
          AppSpacing.gapLg,
          _Label('Description (optionnel)'),
          AppSpacing.gapSm,
          _TF(controller: _descCtrl, hint: 'Décrivez votre laverie…', maxLines: 3),
          AppSpacing.gapLg,
          _Label('Adresse *'),
          AppSpacing.gapSm,
          Row(children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: _addressVerified ? Border.all(color: AppColors.success, width: 1.5) : null,
                ),
                child: TextField(
                  controller: _addressCtrl,
                  onChanged: (_) { if (_addressVerified) setState(() { _addressVerified = false; _latitude = null; _longitude = null; _resolvedAddress = null; }); },
                  decoration: InputDecoration(
                    hintText: '12 rue de la Paix, 75001 Paris',
                    hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    prefixIcon: PhosphorIcon(
                      _addressVerified ? PhosphorIconsRegular.checkCircle : PhosphorIconsRegular.mapPin,
                      size: 18, color: _addressVerified ? AppColors.success : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: _isGeocoding ? null : _geocodeAddress,
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                alignment: Alignment.center,
                child: _isGeocoding
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: AppColors.surface, strokeWidth: 2))
                    : const PhosphorIcon(PhosphorIconsRegular.magnifyingGlass, size: 18, color: AppColors.surface),
              ),
            ),
          ]),
          if (_addressVerified && _resolvedAddress != null) ...[
            AppSpacing.gapSm,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(color: AppColors.confirmedBg, borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
              child: Row(children: [
                const PhosphorIcon(PhosphorIconsRegular.check, size: 14, color: AppColors.confirmedText),
                AppSpacing.hGapSm,
                Expanded(child: Text(_resolvedAddress!, style: const TextStyle(color: AppColors.confirmedText, fontSize: 12, fontWeight: FontWeight.w600))),
              ]),
            ),
          ],
        ],
      );

  Widget _buildStep1(TextTheme tt) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Horaires d\'ouverture', style: tt.titleMedium),
          AppSpacing.gapSm,
          Text('Activez les jours ouverts et définissez les plages horaires.',
              style: tt.bodySmall?.copyWith(color: AppColors.textSecondary)),
          AppSpacing.gapXl,
          ..._dayKeys.asMap().entries.map((e) {
            final d = e.value;
            final enabled = _dayEnabled[d] ?? false;
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: enabled ? AppColors.primary : AppColors.border),
              ),
              child: Row(children: [
                SizedBox(width: 36,
                  child: Text(_dayLabels[e.key],
                      style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600,
                          color: enabled ? AppColors.textPrimary : AppColors.textSecondary))),
                Switch(value: enabled, onChanged: (v) => setState(() => _dayEnabled[d] = v),
                    activeThumbColor: AppColors.surface, activeTrackColor: AppColors.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
                if (enabled) ...[
                  const Spacer(),
                  GestureDetector(
                    onTap: () async {
                      final t = await showTimePicker(context: context, initialTime: _openTimes[d]!);
                      if (t != null) setState(() => _openTimes[d] = t);
                    },
                    child: _TimeTag(time: _openTimes[d]!),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: Text('→', style: tt.bodySmall?.copyWith(color: AppColors.textSecondary)),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final t = await showTimePicker(context: context, initialTime: _closeTimes[d]!);
                      if (t != null) setState(() => _closeTimes[d] = t);
                    },
                    child: _TimeTag(time: _closeTimes[d]!),
                  ),
                ],
              ]),
            );
          }),
        ],
      );

  Widget _buildStep2(TextTheme tt) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Services proposés', style: tt.titleMedium),
          AppSpacing.gapXl,
          _ServiceTile(
            title: 'Je propose le pliage',
            subtitle: 'Vous pliez le linge de vos clients',
            value: _offersFolding,
            onChanged: (v) => setState(() => _offersFolding = v),
          ),
          AppSpacing.gapMd,
          _ServiceTile(
            title: 'Je viens chercher le linge',
            subtitle: 'Collecte à domicile proposée',
            value: _offersPickup,
            onChanged: (v) => setState(() => _offersPickup = v),
          ),
          AppSpacing.gapMd,
          _ServiceTile(
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
                  border: Border.all(color: AppColors.border)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _Label('Frais de livraison (€)'),
                AppSpacing.gapSm,
                _TF(controller: _deliveryFeeCtrl, hint: 'Ex: 5.00',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                AppSpacing.gapLg,
                _Label('Rayon de livraison (km)'),
                AppSpacing.gapSm,
                _TF(controller: _deliveryZoneCtrl, hint: 'Ex: 10',
                    keyboardType: TextInputType.number,
                    formatters: [FilteringTextInputFormatter.digitsOnly]),
              ]),
            ),
          ],
        ],
      );
}

// ── Widgets utilitaires ───────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: Theme.of(context).textTheme.labelSmall
          ?.copyWith(fontWeight: FontWeight.w700, color: AppColors.textBody, fontSize: 12));
}

class _TF extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? formatters;
  const _TF({required this.controller, required this.hint,
      this.maxLines = 1, this.keyboardType, this.formatters});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
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

class _TimeTag extends StatelessWidget {
  final TimeOfDay time;
  const _TimeTag({required this.time});
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final label = '${time.hour.toString().padLeft(2,'0')}h${time.minute.toString().padLeft(2,'0')}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: AppColors.completedBg, borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      child: Text(label, style: tt.labelLarge?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ServiceTile({required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: value ? AppColors.primary : AppColors.border)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          Text(subtitle, style: tt.bodySmall?.copyWith(color: AppColors.textSecondary)),
        ])),
        Switch(value: value, onChanged: onChanged,
            activeThumbColor: AppColors.surface, activeTrackColor: AppColors.primary),
      ]),
    );
  }
}
