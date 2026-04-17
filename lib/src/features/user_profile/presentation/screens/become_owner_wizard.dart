import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../features/authentication/data/repositories/user_repository.dart';
import '../../../../features/machines_map/domain/models/machine_model.dart';
import '../../../../features/machines_map/data/repositories/firestore_machine_repository.dart';

// ═══════════════════════════════════════════════════════
// Wizard principal
// ═══════════════════════════════════════════════════════

class BecomeOwnerWizard extends StatefulWidget {
  const BecomeOwnerWizard({super.key});

  @override
  State<BecomeOwnerWizard> createState() => _BecomeOwnerWizardState();
}

class _BecomeOwnerWizardState extends State<BecomeOwnerWizard> {
  final _pageController = PageController();
  int _currentStep = 0;

  // Step 2 – conditions
  final List<bool> _conditionsAccepted = [false, false, false, false];

  // Step 3 – machine form state
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  String _brand = '';
  int _capacity = 7;
  double _price = 4.0;
  String _description = '';
  String _machineType = 'Lave-linge';
  bool _detergentIncluded = false;
  final Set<int> _availableDays = {1, 2, 3, 4, 5, 6, 7};
  int _startHour = 8;
  int _endHour = 21;
  double? _latitude;
  double? _longitude;
  String? _resolvedAddress;
  bool _addressVerified = false;
  bool _isGeocoding = false;
  final List<XFile> _selectedImages = [];

  bool _isSubmitting = false;

  static const _bg = Color(0xFFF8FAFC);

  bool get _allConditionsAccepted => _conditionsAccepted.every((c) => c);

  @override
  void dispose() {
    _pageController.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_addressVerified || _latitude == null || _longitude == null) {
      _showSnack('Veuillez vérifier votre adresse.', Colors.orange);
      return;
    }
    if (_availableDays.isEmpty) {
      _showSnack('Sélectionnez au moins un jour de disponibilité.', Colors.orange);
      return;
    }
    if (_startHour >= _endHour) {
      _showSnack("L'heure de fin doit être après l'heure de début.", Colors.orange);
      return;
    }

    _formKey.currentState!.save();
    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // 1. Upload photos
      List<String> photoUrls = [];
      if (_selectedImages.isNotEmpty) {
        final folder = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}';
        for (int i = 0; i < _selectedImages.length; i++) {
          final bytes = await _selectedImages[i].readAsBytes();
          final ref = FirebaseStorage.instance.ref().child('machines/$folder/photo_$i.jpg');
          await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
          photoUrls.add(await ref.getDownloadURL());
        }
      }

      // 2. Ajouter le rôle OWNER
      await UserRepository().addRole(user.uid, 'OWNER');

      // 3. Créer la machine
      final machine = MachineModel(
        id: '',
        ownerId: user.uid,
        latitude: _latitude!,
        longitude: _longitude!,
        address: _resolvedAddress,
        capacityKg: _capacity,
        brand: _brand,
        description: '[$_machineType] $_description${_detergentIncluded ? ' — Lessive fournie.' : ''}',
        pricePerWash: _price,
        currency: 'EUR',
        photoUrls: photoUrls,
        status: 'AVAILABLE',
        rating: 0.0,
        reviewCount: 0,
        availableDays: _availableDays.toList()..sort(),
        startTimeHour: _startHour,
        endTimeHour: _endHour,
      );
      await FirestoreMachineRepository().addMachine(machine);

      if (mounted) {
        Navigator.of(context).pop(true); // Retourne true pour rafraîchir le profil
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSnack('Erreur : $e', Colors.red);
      }
    }
  }

  Future<void> _geocodeAddress() async {
    final raw = _addressCtrl.text.trim();
    if (raw.isEmpty) { _showSnack('Saisissez une adresse.', Colors.orange); return; }
    setState(() { _isGeocoding = true; _addressVerified = false; });
    try {
      final locs = await locationFromAddress(raw);
      if (locs.isNotEmpty) {
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
          _latitude = loc.latitude; _longitude = loc.longitude;
          _resolvedAddress = resolved; _addressVerified = true; _isGeocoding = false;
        });
      } else {
        throw Exception();
      }
    } catch (_) {
      setState(() { _isGeocoding = false; _addressVerified = false; });
      _showSnack('Adresse introuvable. Essayez un format plus précis.', Colors.red);
    }
  }

  Future<void> _pickImages() async {
    final remaining = 5 - _selectedImages.length;
    if (remaining <= 0) return;
    final images = await ImagePicker().pickMultiImage(maxWidth: 1920, maxHeight: 1920, imageQuality: 85, limit: remaining);
    if (images.isNotEmpty && mounted) setState(() => _selectedImages.addAll(images.take(remaining)));
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter()),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF0F172A),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: _StepIndicator(currentStep: _currentStep, totalSteps: 3),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _Step1Benefits(onNext: () => _goToStep(1)),
          _Step2Conditions(
            accepted: _conditionsAccepted,
            onChanged: (i, v) => setState(() => _conditionsAccepted[i] = v),
            onNext: _allConditionsAccepted ? () => _goToStep(2) : null,
          ),
          _Step3Machine(
            formKey: _formKey,
            addressCtrl: _addressCtrl,
            brand: _brand,
            capacity: _capacity,
            price: _price,
            machineType: _machineType,
            detergentIncluded: _detergentIncluded,
            availableDays: _availableDays,
            startHour: _startHour,
            endHour: _endHour,
            addressVerified: _addressVerified,
            resolvedAddress: _resolvedAddress,
            isGeocoding: _isGeocoding,
            selectedImages: _selectedImages,
            isSubmitting: _isSubmitting,
            onBrandSaved: (v) => _brand = v!.trim(),
            onCapacitySaved: (v) => _capacity = int.parse(v!),
            onPriceSaved: (v) => _price = double.parse(v!.replaceAll(',', '.')),
            onDescriptionSaved: (v) => _description = v!.trim(),
            onMachineTypeChanged: (v) => setState(() => _machineType = v),
            onDetergentChanged: (v) => setState(() => _detergentIncluded = v),
            onDayToggled: (day) => setState(() {
              _availableDays.contains(day) ? _availableDays.remove(day) : _availableDays.add(day);
            }),
            onStartHourChanged: (v) => setState(() => _startHour = v),
            onEndHourChanged: (v) => setState(() => _endHour = v),
            onAddressChanged: () => setState(() { _addressVerified = false; _latitude = null; _longitude = null; _resolvedAddress = null; }),
            onGeocode: _geocodeAddress,
            onPickImages: _pickImages,
            onRemoveImage: (i) => setState(() => _selectedImages.removeAt(i)),
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Indicateur d'étapes
// ═══════════════════════════════════════════════════════

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  const _StepIndicator({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalSteps, (i) {
        final isActive = i == currentStep;
        final isDone = i < currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isDone
                ? const Color(0xFF16A34A)
                : isActive
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Étape 1 — Avantages
// ═══════════════════════════════════════════════════════

class _Step1Benefits extends StatelessWidget {
  final VoidCallback onNext;
  const _Step1Benefits({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero visuel
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.vpn_key_rounded, color: Colors.white, size: 48),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Devenez Propriétaire',
                        style: GoogleFonts.outfit(
                          fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Rentabilisez votre machine à laver en la mettant à disposition de vos voisins.',
                        style: GoogleFonts.inter(
                          fontSize: 14, color: Colors.white.withValues(alpha: 0.85), height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  'Pourquoi devenir propriétaire ?',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 16),

                ...[
                  _BenefitItem(
                    icon: Icons.euro_rounded,
                    color: const Color(0xFF16A34A),
                    bg: const Color(0xFFDCFCE7),
                    title: 'Revenus passifs',
                    subtitle: 'Gagnez de l\'argent sur chaque lavage, même quand vous dormez.',
                  ),
                  _BenefitItem(
                    icon: Icons.tune_rounded,
                    color: const Color(0xFF2563EB),
                    bg: const Color(0xFFDBEAFE),
                    title: 'Vous restez maître',
                    subtitle: 'Définissez vos horaires, votre prix et vos jours disponibles.',
                  ),
                  _BenefitItem(
                    icon: Icons.shield_rounded,
                    color: const Color(0xFF7C3AED),
                    bg: const Color(0xFFEDE9FE),
                    title: 'Réservations sécurisées',
                    subtitle: 'Vous confirmez chaque demande avant qu\'elle soit validée.',
                  ),
                  _BenefitItem(
                    icon: Icons.people_rounded,
                    color: const Color(0xFFD97706),
                    bg: const Color(0xFFFEF3C7),
                    title: 'Communauté de confiance',
                    subtitle: 'Tous les utilisateurs sont vérifiés et notés par la communauté.',
                  ),
                ],

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),

        // Bouton bas de page
        _WizardBottomBar(
          label: 'Commencer',
          icon: Icons.arrow_forward_rounded,
          onPressed: onNext,
        ),
      ],
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final String title;
  final String subtitle;

  const _BenefitItem({
    required this.icon, required this.color, required this.bg,
    required this.title, required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF0F172A))),
                const SizedBox(height: 3),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B), height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Étape 2 — Conditions
// ═══════════════════════════════════════════════════════

class _Step2Conditions extends StatelessWidget {
  final List<bool> accepted;
  final void Function(int, bool) onChanged;
  final VoidCallback? onNext;

  const _Step2Conditions({required this.accepted, required this.onChanged, required this.onNext});

  static const _conditions = [
    (
      title: 'Je m\'engage à maintenir ma machine en bon état de fonctionnement',
      detail: 'La machine doit être propre et opérationnelle lors de chaque réservation.',
    ),
    (
      title: 'J\'accepte les conditions générales d\'utilisation de WashFamily',
      detail: 'En cas de litige, WashFamily agit comme intermédiaire entre les parties.',
    ),
    (
      title: 'Je m\'engage à respecter les créneaux confirmés',
      detail: 'Annuler une réservation confirmée sans motif valable peut entraîner une suspension.',
    ),
    (
      title: 'Je comprends que WashFamily prélève une commission de 15%',
      detail: 'Cette commission couvre la gestion de la plateforme, le support et les assurances.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final allDone = accepted.every((c) => c);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conditions propriétaire',
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Lisez et acceptez chaque engagement avant de continuer.',
                  style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B), height: 1.5),
                ),
                const SizedBox(height: 24),

                ..._conditions.asMap().entries.map((entry) {
                  final i = entry.key;
                  final c = entry.value;
                  return _ConditionTile(
                    title: c.title,
                    detail: c.detail,
                    isAccepted: accepted[i],
                    onChanged: (v) => onChanged(i, v),
                  );
                }),

                const SizedBox(height: 8),

                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: allDone ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: allDone ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        allDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: allDone ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          allDone
                              ? 'Tous les engagements acceptés — vous pouvez continuer.'
                              : 'Acceptez tous les engagements pour continuer.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: allDone ? const Color(0xFF15803D) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        _WizardBottomBar(
          label: 'Continuer',
          icon: Icons.arrow_forward_rounded,
          onPressed: onNext,
        ),
      ],
    );
  }
}

class _ConditionTile extends StatelessWidget {
  final String title;
  final String detail;
  final bool isAccepted;
  final ValueChanged<bool> onChanged;

  const _ConditionTile({
    required this.title, required this.detail,
    required this.isAccepted, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isAccepted),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isAccepted ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAccepted ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
            width: isAccepted ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: isAccepted ? const Color(0xFF16A34A) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isAccepted ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
                  width: 2,
                ),
              ),
              child: isAccepted
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A), height: 1.4)),
                  const SizedBox(height: 4),
                  Text(detail, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Étape 3 — Première machine
// ═══════════════════════════════════════════════════════

class _Step3Machine extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController addressCtrl;
  final String brand;
  final int capacity;
  final double price;
  final String machineType;
  final bool detergentIncluded;
  final Set<int> availableDays;
  final int startHour;
  final int endHour;
  final bool addressVerified;
  final String? resolvedAddress;
  final bool isGeocoding;
  final List<XFile> selectedImages;
  final bool isSubmitting;

  final void Function(String?) onBrandSaved;
  final void Function(String?) onCapacitySaved;
  final void Function(String?) onPriceSaved;
  final void Function(String?) onDescriptionSaved;
  final ValueChanged<String> onMachineTypeChanged;
  final ValueChanged<bool> onDetergentChanged;
  final ValueChanged<int> onDayToggled;
  final ValueChanged<int> onStartHourChanged;
  final ValueChanged<int> onEndHourChanged;
  final VoidCallback onAddressChanged;
  final VoidCallback onGeocode;
  final VoidCallback onPickImages;
  final ValueChanged<int> onRemoveImage;
  final VoidCallback onSubmit;

  static const _primary = Color(0xFF2563EB);
  static const _slate = Color(0xFF64748B);
  static const _dayLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  static const _dayFullLabels = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];

  const _Step3Machine({
    required this.formKey, required this.addressCtrl,
    required this.brand, required this.capacity, required this.price,
    required this.machineType, required this.detergentIncluded,
    required this.availableDays, required this.startHour, required this.endHour,
    required this.addressVerified, required this.resolvedAddress,
    required this.isGeocoding, required this.selectedImages, required this.isSubmitting,
    required this.onBrandSaved, required this.onCapacitySaved, required this.onPriceSaved,
    required this.onDescriptionSaved, required this.onMachineTypeChanged,
    required this.onDetergentChanged, required this.onDayToggled,
    required this.onStartHourChanged, required this.onEndHourChanged,
    required this.onAddressChanged, required this.onGeocode, required this.onPickImages,
    required this.onRemoveImage, required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Votre première machine', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                      const SizedBox(height: 6),
                      Text('Décrivez votre machine pour attirer vos premiers locataires.', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B), height: 1.4)),
                    ],
                  ),
                ),

                // Photos
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        _FieldLabel('Photos'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: selectedImages.length >= 5 ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('${selectedImages.length} / 5', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: selectedImages.length >= 5 ? _primary : _slate)),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 108,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            if (selectedImages.length < 5)
                              GestureDetector(
                                onTap: onPickImages,
                                child: Container(
                                  width: 92, margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5)),
                                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    const Icon(Icons.add_photo_alternate_outlined, color: _primary, size: 28),
                                    const SizedBox(height: 5),
                                    Text('Ajouter', style: GoogleFonts.inter(color: _primary, fontSize: 11, fontWeight: FontWeight.w600)),
                                  ]),
                                ),
                              ),
                            ...selectedImages.asMap().entries.map((e) => Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Stack(children: [
                                ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(e.value.path), width: 92, height: 108, fit: BoxFit.cover)),
                                Positioned(top: 5, right: 5, child: GestureDetector(
                                  onTap: () => onRemoveImage(e.key),
                                  child: Container(width: 24, height: 24, decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 13)),
                                )),
                              ]),
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Identité
                _SectionCard(
                  title: 'IDENTITÉ',
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _FieldLabel('Type'),
                    const SizedBox(height: 8),
                    _SegmentedSelector(options: const ['Lave-linge', 'Sèche-linge', 'Combiné'], selected: machineType, onChanged: onMachineTypeChanged),
                    const SizedBox(height: 16),
                    _FieldLabel('Marque'),
                    const SizedBox(height: 8),
                    _StyledTextFormField(hintText: 'Ex: Bosch, LG...', validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null, onSaved: onBrandSaved),
                  ]),
                ),
                const SizedBox(height: 16),

                // Tarif
                _SectionCard(
                  title: 'TARIF & CAPACITÉ',
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _FieldLabel('Capacité (kg)'),
                        const SizedBox(height: 8),
                        _StyledTextFormField(hintText: '7', initialValue: '7', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (v) { if (v == null || v.isEmpty) return 'Requis'; final n = int.tryParse(v); if (n == null || n < 1 || n > 30) return '1–30'; return null; },
                          onSaved: onCapacitySaved),
                      ])),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _FieldLabel('Prix (€/h)'),
                        const SizedBox(height: 8),
                        _StyledTextFormField(hintText: '4.00', initialValue: '4.0', keyboardType: const TextInputType.numberWithOptions(decimal: true), suffixText: '€/h',
                          validator: (v) { if (v == null || v.isEmpty) return 'Requis'; final n = double.tryParse(v.replaceAll(',', '.')); if (n == null || n <= 0) return 'Invalide'; return null; },
                          onSaved: onPriceSaved),
                      ])),
                    ]),
                    const SizedBox(height: 16),
                    _SwitchTile(title: 'Lessive fournie', subtitle: "Le locataire n'a pas besoin d'apporter sa lessive", value: detergentIncluded, onChanged: onDetergentChanged),
                  ]),
                ),
                const SizedBox(height: 16),

                // Disponibilités
                _SectionCard(
                  title: 'DISPONIBILITÉS',
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _FieldLabel('Jours disponibles'),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(7, (index) {
                        final day = index + 1;
                        final isSelected = availableDays.contains(day);
                        return Expanded(child: GestureDetector(
                          onTap: () => onDayToggled(day),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? _primary : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isSelected ? _primary : const Color(0xFFE2E8F0)),
                            ),
                            alignment: Alignment.center,
                            child: Text(_dayLabels[index], style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: isSelected ? Colors.white : const Color(0xFF94A3B8))),
                          ),
                        ));
                      }),
                    ),
                    if (availableDays.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text((availableDays.toList()..sort()).map((d) => _dayFullLabels[d - 1]).join(', '), style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                    ],
                    const SizedBox(height: 20),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 20),
                    _FieldLabel('Plage horaire'),
                    const SizedBox(height: 16),
                    _TimeRangeSelector(startHour: startHour, endHour: endHour, onStartChanged: onStartHourChanged, onEndChanged: onEndHourChanged),
                  ]),
                ),
                const SizedBox(height: 16),

                // Localisation
                _SectionCard(
                  title: 'LOCALISATION',
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    _FieldLabel('Adresse de la machine'),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: Container(
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12), border: addressVerified ? Border.all(color: const Color(0xFF16A34A), width: 1.5) : null),
                        child: TextFormField(
                          controller: addressCtrl,
                          onChanged: (_) => onAddressChanged(),
                          decoration: InputDecoration(
                            hintText: 'Ex: 12 rue de la Paix, 75001 Paris',
                            hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            prefixIcon: Icon(addressVerified ? Icons.check_circle : Icons.location_on_outlined, color: addressVerified ? const Color(0xFF16A34A) : _slate, size: 20),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Adresse requise';
                            if (!addressVerified) return "Vérifiez l'adresse d'abord";
                            return null;
                          },
                        ),
                      )),
                      const SizedBox(width: 8),
                      Material(
                        color: _primary, borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: isGeocoding ? null : onGeocode,
                          child: Container(width: 52, height: 52, alignment: Alignment.center,
                            child: isGeocoding
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.search_rounded, color: Colors.white, size: 22),
                          ),
                        ),
                      ),
                    ]),
                    if (addressVerified && resolvedAddress != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFBBF7D0))),
                        child: Row(children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                          const SizedBox(width: 10),
                          Expanded(child: Text(resolvedAddress!, style: GoogleFonts.inter(color: const Color(0xFF15803D), fontSize: 12, fontWeight: FontWeight.w600))),
                        ]),
                      ),
                    ],
                  ]),
                ),
                const SizedBox(height: 16),

                // Description
                _SectionCard(
                  title: 'DESCRIPTION',
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _FieldLabel('Présentez votre machine'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                      child: TextFormField(
                        maxLines: 4, maxLength: 400,
                        decoration: InputDecoration(
                          hintText: "Décrivez l'état de la machine, l'accès, les conditions...",
                          hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
                          border: InputBorder.none, contentPadding: const EdgeInsets.all(16),
                        ),
                        style: GoogleFonts.inter(fontSize: 14),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Champ requis' : null,
                        onSaved: onDescriptionSaved,
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),

        _WizardBottomBar(
          label: 'Finaliser et devenir propriétaire',
          icon: Icons.check_rounded,
          isLoading: isSubmitting,
          onPressed: isSubmitting ? null : onSubmit,
          color: const Color(0xFF16A34A),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// Barre bouton bas de page
// ═══════════════════════════════════════════════════════

class _WizardBottomBar extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color color;

  const _WizardBottomBar({
    required this.label, required this.icon,
    this.onPressed, this.isLoading = false,
    this.color = const Color(0xFF2563EB),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: onPressed == null ? const Color(0xFFCBD5E1) : color,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          minimumSize: const Size(double.infinity, 56),
        ),
        child: isLoading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(width: 8),
                Icon(icon, size: 18),
              ]),
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════
// Composants UI partagés (locaux au wizard)
// ═══════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;
  const _SectionCard({this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8), letterSpacing: 1.5)),
            const SizedBox(height: 16),
          ],
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
  Widget build(BuildContext context) {
    return Text(text, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF374151)));
  }
}

class _StyledTextFormField extends StatelessWidget {
  final String hintText;
  final String? initialValue;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;
  final String? suffixText;

  const _StyledTextFormField({
    required this.hintText, this.initialValue, this.keyboardType,
    this.inputFormatters, this.validator, this.onSaved, this.suffixText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
      child: TextFormField(
        initialValue: initialValue,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        onSaved: onSaved,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
          border: InputBorder.none,
          suffixText: suffixText,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _SegmentedSelector extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  const _SegmentedSelector({required this.options, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((option) {
        final isSelected = option == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
              ),
              alignment: Alignment.center,
              child: Text(option, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : const Color(0xFF64748B))),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
        ])),
        Switch(value: value, activeThumbColor: Colors.white, activeTrackColor: const Color(0xFF2563EB), inactiveThumbColor: Colors.white, inactiveTrackColor: const Color(0xFFCBD5E1), onChanged: onChanged),
      ],
    );
  }
}

class _TimeRangeSelector extends StatelessWidget {
  final int startHour;
  final int endHour;
  final ValueChanged<int> onStartChanged;
  final ValueChanged<int> onEndChanged;

  const _TimeRangeSelector({required this.startHour, required this.endHour, required this.onStartChanged, required this.onEndChanged});

  static String _fmt(int h) => '${h.toString().padLeft(2, '0')}h00';

  @override
  Widget build(BuildContext context) {
    final duration = endHour - startHour;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _TimeChip(time: _fmt(startHour), label: 'Ouverture'),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 3, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF93C5FD)]), borderRadius: BorderRadius.circular(4)))),
          const SizedBox(width: 10),
          _TimeChip(time: _fmt(endHour), label: 'Fermeture'),
        ]),
        const SizedBox(height: 18),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: const Color(0xFF2563EB),
            inactiveTrackColor: const Color(0xFFE2E8F0),
            thumbColor: const Color(0xFF2563EB),
            overlayColor: const Color(0xFF2563EB).withValues(alpha: 0.12),
            trackHeight: 5,
            rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 10, elevation: 3),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
            rangeValueIndicatorShape: const PaddleRangeSliderValueIndicatorShape(),
            valueIndicatorColor: const Color(0xFF0F172A),
            valueIndicatorTextStyle: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            showValueIndicator: ShowValueIndicator.onDrag,
          ),
          child: RangeSlider(
            values: RangeValues(startHour.toDouble(), endHour.toDouble()),
            min: 0, max: 24, divisions: 24,
            labels: RangeLabels(_fmt(startHour), _fmt(endHour)),
            onChanged: (values) {
              final s = values.start.round();
              final e = values.end.round();
              if (s < e) { onStartChanged(s); onEndChanged(e); }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['0h', '6h', '12h', '18h', '24h'].map((t) => Text(t, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)))).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFBFDBFE))),
          child: Row(children: [
            const Icon(Icons.schedule_rounded, size: 16, color: Color(0xFF2563EB)),
            const SizedBox(width: 8),
            Text('De ${_fmt(startHour)} à ${_fmt(endHour)} · ${duration}h de disponibilité', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1D4ED8), fontWeight: FontWeight.w600)),
          ]),
        ),
      ],
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String time;
  final String label;
  const _TimeChip({required this.time, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text(label, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
      const SizedBox(height: 5),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(20)),
        child: Text(time, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    ]);
  }
}
