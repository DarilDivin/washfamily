import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../features/machines_map/domain/models/machine_model.dart';
import '../../../../features/machines_map/data/repositories/firestore_machine_repository.dart';

class AddMachineScreen extends StatefulWidget {
  const AddMachineScreen({super.key});

  @override
  State<AddMachineScreen> createState() => _AddMachineScreenState();
}

class _AddMachineScreenState extends State<AddMachineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();

  // ── Champs du formulaire ──────────────────────────────────
  String _brand = '';
  int _capacity = 7;
  double _price = 4.0;
  String _description = '';
  String _machineType = 'Lave-linge';
  bool _detergentIncluded = false;
  bool _isLoading = false;
  bool _isGeocoding = false;

  // ── Photos ────────────────────────────────────────────────
  final List<XFile> _selectedImages = [];

  // ── Disponibilités ────────────────────────────────────────
  // 1=Lun, 2=Mar, 3=Mer, 4=Jeu, 5=Ven, 6=Sam, 7=Dim
  final Set<int> _availableDays = {1, 2, 3, 4, 5, 6, 7};
  int _startHour = 8;
  int _endHour = 21;

  // ── Géolocalisation ───────────────────────────────────────
  double? _latitude;
  double? _longitude;
  String? _resolvedAddress;
  bool _addressVerified = false;

  static const _primaryColor = Color(0xFF2563EB);
  static const _bgColor = Color(0xFFF8FAFC);
  static const _slateGray = Color(0xFF64748B);

  static const _dayLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  static const _dayFullLabels = [
    'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
  ];

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  // ── Sélection des photos ──────────────────────────────────
  Future<void> _pickImages() async {
    final remaining = 5 - _selectedImages.length;
    if (remaining <= 0) return;

    final picker = ImagePicker();
    final images = await picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
      limit: remaining,
    );

    if (images.isNotEmpty && mounted) {
      setState(() => _selectedImages.addAll(images.take(remaining)));
    }
  }

  // ── Upload vers Firebase Storage ─────────────────────────
  Future<List<String>> _uploadImages(String folder) async {
    final urls = <String>[];
    for (int i = 0; i < _selectedImages.length; i++) {
      final bytes = await _selectedImages[i].readAsBytes();
      final ref = FirebaseStorage.instance
          .ref()
          .child('machines/$folder/photo_$i.jpg');
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  // ── Géocodage ─────────────────────────────────────────────
  Future<void> _geocodeAddress() async {
    final rawAddress = _addressCtrl.text.trim();
    if (rawAddress.isEmpty) {
      _showSnack('Veuillez saisir une adresse.', Colors.orange);
      return;
    }

    setState(() {
      _isGeocoding = true;
      _addressVerified = false;
      _latitude = null;
      _longitude = null;
      _resolvedAddress = null;
    });

    try {
      final locations = await locationFromAddress(rawAddress);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        String resolved = rawAddress;
        try {
          final placemarks =
              await placemarkFromCoordinates(loc.latitude, loc.longitude);
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            final parts = [
              if (p.street != null && p.street!.isNotEmpty) p.street,
              if (p.postalCode != null && p.postalCode!.isNotEmpty) p.postalCode,
              if (p.locality != null && p.locality!.isNotEmpty) p.locality,
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
        _showSnack('Adresse localisée : $resolved', const Color(0xFF16A34A));
      } else {
        throw Exception('Aucun résultat');
      }
    } catch (e) {
      setState(() {
        _isGeocoding = false;
        _addressVerified = false;
      });
      _showSnack(
        'Adresse introuvable. Essayez un format plus précis (rue, code postal, ville).',
        Colors.red,
      );
    }
  }

  // ── Snackbar helper ───────────────────────────────────────
  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter()),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Soumission du formulaire ──────────────────────────────
  Future<void> _submitForm() async {
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
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Upload des photos si présentes
      List<String> photoUrls = [];
      if (_selectedImages.isNotEmpty) {
        final folder = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}';
        photoUrls = await _uploadImages(folder);
      }

      final newMachine = MachineModel(
        id: '',
        ownerId: user.uid,
        latitude: _latitude!,
        longitude: _longitude!,
        address: _resolvedAddress,
        capacityKg: _capacity,
        brand: _brand,
        description:
            '[$_machineType] $_description${_detergentIncluded ? ' — Lessive fournie.' : ''}',
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

      await FirestoreMachineRepository().addMachine(newMachine);

      if (mounted) {
        setState(() => _isLoading = false);
        context.pop();
        _showSnack('Machine mise en location avec succès !', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack('Erreur : $e', Colors.red);
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: Text(
          'Ma nouvelle machine',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Photos ─────────────────────────────────────────
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _FieldLabel('Photos de la machine'),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _selectedImages.length >= 5
                              ? const Color(0xFFEFF6FF)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_selectedImages.length} / 5',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _selectedImages.length >= 5
                                ? _primaryColor
                                : _slateGray,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 108,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // Bouton ajout
                        if (_selectedImages.length < 5)
                          GestureDetector(
                            onTap: _pickImages,
                            child: Container(
                              width: 92,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: const Color(0xFFBFDBFE), width: 1.5),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.add_photo_alternate_outlined,
                                    color: _primaryColor,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Ajouter',
                                    style: GoogleFonts.inter(
                                      color: _primaryColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // Miniatures
                        ..._selectedImages.asMap().entries.map((entry) {
                          final index = entry.key;
                          final xFile = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.file(
                                    File(xFile.path),
                                    width: 92,
                                    height: 108,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                // Badge "Principale" sur la 1re photo
                                if (index == 0)
                                  Positioned(
                                    bottom: 6,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color:
                                              Colors.black.withValues(alpha: 0.55),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'Principale',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                // Bouton supprimer
                                Positioned(
                                  top: 5,
                                  right: 5,
                                  child: GestureDetector(
                                    onTap: () => setState(
                                        () => _selectedImages.removeAt(index)),
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Colors.black
                                            .withValues(alpha: 0.55),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close,
                                          color: Colors.white, size: 13),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  if (_selectedImages.isEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Ajoutez des photos pour attirer plus de locataires',
                      style:
                          GoogleFonts.inter(fontSize: 11, color: _slateGray),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Identité de la machine ─────────────────────────
            _SectionCard(
              title: 'IDENTITÉ DE LA MACHINE',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('Type de machine'),
                  const SizedBox(height: 8),
                  _SegmentedSelector(
                    options: const ['Lave-linge', 'Sèche-linge', 'Combiné'],
                    selected: _machineType,
                    onChanged: (v) => setState(() => _machineType = v),
                  ),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel('Marque'),
                          const SizedBox(height: 8),
                          _StyledTextFormField(
                            hintText: 'Ex: Bosch, LG...',
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Requis' : null,
                            onSaved: (v) => _brand = v!.trim(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel('Modèle (optionnel)'),
                          const SizedBox(height: 8),
                          _StyledTextFormField(
                            hintText: 'Ex: WAN28040',
                            onSaved: (_) {},
                          ),
                        ],
                      ),
                    ),
                  ]),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Tarif & Capacité ───────────────────────────────
            _SectionCard(
              title: 'TARIF & CAPACITÉ',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel('Capacité (kg)'),
                          const SizedBox(height: 8),
                          _StyledTextFormField(
                            hintText: '7',
                            initialValue: '7',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Requis';
                              final n = int.tryParse(v);
                              if (n == null || n < 1 || n > 30) {
                                return '1–30 kg';
                              }
                              return null;
                            },
                            onSaved: (v) => _capacity = int.parse(v!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel('Prix horaire (€)'),
                          const SizedBox(height: 8),
                          _StyledTextFormField(
                            hintText: '4.00',
                            initialValue: '4.0',
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Requis';
                              final n =
                                  double.tryParse(v.replaceAll(',', '.'));
                              if (n == null || n <= 0) return 'Invalide';
                              return null;
                            },
                            onSaved: (v) => _price =
                                double.parse(v!.replaceAll(',', '.')),
                            suffixText: '€/h',
                          ),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _SwitchTile(
                    title: 'Lessive fournie',
                    subtitle:
                        "Le locataire n'a pas besoin d'apporter sa lessive",
                    value: _detergentIncluded,
                    onChanged: (v) => setState(() => _detergentIncluded = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Disponibilités ─────────────────────────────────
            _SectionCard(
              title: 'DISPONIBILITÉS',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('Jours disponibles'),
                  const SizedBox(height: 12),

                  // Sélecteur de jours
                  Row(
                    children: List.generate(7, (index) {
                      final day = index + 1;
                      final isSelected = _availableDays.contains(day);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            if (isSelected) {
                              _availableDays.remove(day);
                            } else {
                              _availableDays.add(day);
                            }
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            padding:
                                const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _primaryColor
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? _primaryColor
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _dayLabels[index],
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  if (_availableDays.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      (_availableDays.toList()..sort())
                          .map((d) => _dayFullLabels[d - 1])
                          .join(', '),
                      style: GoogleFonts.inter(
                          fontSize: 11, color: const Color(0xFF64748B)),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Text(
                      'Sélectionnez au moins un jour',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: const Color(0xFFDC2626)),
                    ),
                  ],

                  const SizedBox(height: 20),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 20),

                  _FieldLabel('Plage horaire'),
                  const SizedBox(height: 16),

                  _TimeRangeSelector(
                    startHour: _startHour,
                    endHour: _endHour,
                    onStartChanged: (v) => setState(() => _startHour = v),
                    onEndChanged: (v) => setState(() => _endHour = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Localisation ───────────────────────────────────
            _SectionCard(
              title: 'LOCALISATION',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FieldLabel("Adresse de la machine"),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: _addressVerified
                              ? Border.all(
                                  color: const Color(0xFF16A34A), width: 1.5)
                              : null,
                        ),
                        child: TextFormField(
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
                            hintText: 'Ex: 12 rue de la Paix, 75001 Paris',
                            hintStyle: GoogleFonts.inter(
                                color: const Color(0xFF94A3B8)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            prefixIcon: Icon(
                              _addressVerified
                                  ? Icons.check_circle
                                  : Icons.location_on_outlined,
                              color: _addressVerified
                                  ? const Color(0xFF16A34A)
                                  : _slateGray,
                              size: 20,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Adresse requise';
                            }
                            if (!_addressVerified) {
                              return "Cliquez sur l'icône pour vérifier l'adresse";
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: _primaryColor,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _isGeocoding ? null : _geocodeAddress,
                        child: Container(
                          width: 52,
                          height: 52,
                          alignment: Alignment.center,
                          child: _isGeocoding
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.search_rounded,
                                  color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  if (_addressVerified && _resolvedAddress != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF16A34A), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _resolvedAddress!,
                            style: GoogleFonts.inter(
                                color: const Color(0xFF15803D),
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ]),
                    ),
                  ] else if (!_addressVerified &&
                      _addressCtrl.text.isNotEmpty) ...[
                    Text(
                      "Cliquez sur l'icône de recherche pour vérifier l'adresse.",
                      style: GoogleFonts.inter(
                          fontSize: 11, color: const Color(0xFFD97706)),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Description ────────────────────────────────────
            _SectionCard(
              title: 'DESCRIPTION',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('Présentez votre machine aux locataires'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextFormField(
                      maxLines: 4,
                      maxLength: 400,
                      decoration: InputDecoration(
                        hintText:
                            "Décrivez l'état de la machine, l'accès, les conditions...",
                        hintStyle: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8), fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: GoogleFonts.inter(fontSize: 14),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Champ requis' : null,
                      onSaved: (v) => _description = v!.trim(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton(
            onPressed: _isLoading ? null : _submitForm,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: _primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Mettre en location',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Sélecteur de plage horaire
// ─────────────────────────────────────────────

class _TimeRangeSelector extends StatelessWidget {
  final int startHour;
  final int endHour;
  final ValueChanged<int> onStartChanged;
  final ValueChanged<int> onEndChanged;

  const _TimeRangeSelector({
    required this.startHour,
    required this.endHour,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  static String _fmt(int h) => '${h.toString().padLeft(2, '0')}h00';

  @override
  Widget build(BuildContext context) {
    final duration = endHour - startHour;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chips Ouverture / Fermeture
        Row(
          children: [
            _TimeChip(time: _fmt(startHour), label: 'Ouverture'),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF93C5FD)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _TimeChip(time: _fmt(endHour), label: 'Fermeture'),
          ],
        ),

        const SizedBox(height: 18),

        // RangeSlider
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: const Color(0xFF2563EB),
            inactiveTrackColor: const Color(0xFFE2E8F0),
            thumbColor: const Color(0xFF2563EB),
            overlayColor: const Color(0xFF2563EB).withValues(alpha: 0.12),
            trackHeight: 5,
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 10,
              elevation: 3,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
            rangeValueIndicatorShape:
                const PaddleRangeSliderValueIndicatorShape(),
            valueIndicatorColor: const Color(0xFF0F172A),
            valueIndicatorTextStyle: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            showValueIndicator: ShowValueIndicator.onDrag,
          ),
          child: RangeSlider(
            values: RangeValues(startHour.toDouble(), endHour.toDouble()),
            min: 0,
            max: 24,
            divisions: 24,
            labels: RangeLabels(_fmt(startHour), _fmt(endHour)),
            onChanged: (values) {
              final s = values.start.round();
              final e = values.end.round();
              if (s < e) {
                onStartChanged(s);
                onEndChanged(e);
              }
            },
          ),
        ),

        // Repères horaires
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['0h', '6h', '12h', '18h', '24h']
                .map((t) => Text(
                      t,
                      style: GoogleFonts.inter(
                          fontSize: 10, color: const Color(0xFF94A3B8)),
                    ))
                .toList(),
          ),
        ),

        const SizedBox(height: 12),

        // Résumé de la plage
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            children: [
              const Icon(Icons.schedule_rounded,
                  size: 16, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Text(
                'De ${_fmt(startHour)} à ${_fmt(endHour)} · ${duration}h de disponibilité',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF1D4ED8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: const Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            time,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Composants réutilisables
// ─────────────────────────────────────────────

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
            Text(
              title!,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF94A3B8),
                letterSpacing: 1.5,
              ),
            ),
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
    return Text(
      text,
      style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF374151)),
    );
  }
}

class _StyledTextFormField extends StatelessWidget {
  final String hintText;
  final String? initialValue;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;
  final String? suffixText;

  const _StyledTextFormField({
    required this.hintText,
    this.initialValue,
    this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.onSaved,
    this.suffixText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        initialValue: controller == null ? initialValue : null,
        controller: controller,
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _SegmentedSelector extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  final List<String>? labels;

  const _SegmentedSelector({
    required this.options,
    required this.selected,
    required this.onChanged,
    this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final displayLabel = labels != null ? labels![index] : option;
        final isSelected = option == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                displayLabel,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
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

  const _SwitchTile(
      {required this.title,
      required this.subtitle,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, fontSize: 14)),
              Text(subtitle,
                  style: GoogleFonts.inter(
                      fontSize: 11, color: const Color(0xFF64748B))),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: Colors.white,
          activeTrackColor: const Color(0xFF2563EB),
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: const Color(0xFFCBD5E1),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════
// Écran de modification de machine
// ═════════════════════════════════════════════

class EditMachineScreen extends StatefulWidget {
  final MachineModel machine;
  const EditMachineScreen({super.key, required this.machine});

  @override
  State<EditMachineScreen> createState() => _EditMachineScreenState();
}

class _EditMachineScreenState extends State<EditMachineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  late final TextEditingController _brandCtrl;
  late final TextEditingController _descCtrl;

  // ── Champs ────────────────────────────────────────────────
  int _capacity = 7;
  double _price = 4.0;
  String _machineType = 'Lave-linge';
  bool _detergentIncluded = false;
  bool _isLoading = false;
  bool _isGeocoding = false;
  String _machineStatus = 'AVAILABLE';

  // ── Photos ────────────────────────────────────────────────
  late List<String> _existingPhotoUrls;
  final List<XFile> _newImages = [];

  // ── Disponibilités ────────────────────────────────────────
  late Set<int> _availableDays;
  late int _startHour;
  late int _endHour;

  // ── Géolocalisation ───────────────────────────────────────
  double? _latitude;
  double? _longitude;
  String? _resolvedAddress;
  bool _addressVerified = false;

  static const _primaryColor = Color(0xFF2563EB);
  static const _bgColor = Color(0xFFF8FAFC);
  static const _slateGray = Color(0xFF64748B);
  static const _dayLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  static const _dayFullLabels = [
    'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
  ];

  @override
  void initState() {
    super.initState();
    final m = widget.machine;
    _brandCtrl = TextEditingController(text: m.brand);
    _descCtrl = TextEditingController(text: _parseDesc(m.description));
    _capacity = m.capacityKg;
    _price = m.pricePerWash;
    _machineType = _parseType(m.description);
    _detergentIncluded = _parseDetergent(m.description);
    _availableDays = m.availableDays.toSet();
    _startHour = m.startTimeHour;
    _endHour = m.endTimeHour;
    _existingPhotoUrls = List.from(m.photoUrls);
    _machineStatus = m.status;
    _addressCtrl.text = m.address ?? '';
    _latitude = m.latitude != 0.0 ? m.latitude : null;
    _longitude = m.longitude != 0.0 ? m.longitude : null;
    _resolvedAddress = m.address;
    _addressVerified = m.latitude != 0.0 && m.longitude != 0.0;
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _brandCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── Parsers description ───────────────────────────────────
  static String _parseType(String desc) {
    final match = RegExp(r'^\[([^\]]+)\]').firstMatch(desc);
    return match?.group(1) ?? 'Lave-linge';
  }

  static String _parseDesc(String desc) {
    return desc
        .replaceFirst(RegExp(r'^\[[^\]]+\]\s*'), '')
        .replaceAll(' — Lessive fournie.', '')
        .trim();
  }

  static bool _parseDetergent(String desc) =>
      desc.contains('— Lessive fournie.');

  int get _totalPhotos => _existingPhotoUrls.length + _newImages.length;

  // ── Sélection de nouvelles photos ────────────────────────
  Future<void> _pickImages() async {
    final remaining = 5 - _totalPhotos;
    if (remaining <= 0) return;
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
      limit: remaining,
    );
    if (images.isNotEmpty && mounted) {
      setState(() => _newImages.addAll(images.take(remaining)));
    }
  }

  // ── Upload des nouvelles photos ───────────────────────────
  Future<List<String>> _uploadNewImages(String folder) async {
    final urls = <String>[];
    for (int i = 0; i < _newImages.length; i++) {
      final bytes = await _newImages[i].readAsBytes();
      final ref = FirebaseStorage.instance
          .ref()
          .child('machines/$folder/photo_${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  // ── Géocodage ─────────────────────────────────────────────
  Future<void> _geocodeAddress() async {
    final rawAddress = _addressCtrl.text.trim();
    if (rawAddress.isEmpty) {
      _showSnack('Veuillez saisir une adresse.', Colors.orange);
      return;
    }
    setState(() {
      _isGeocoding = true;
      _addressVerified = false;
      _latitude = null;
      _longitude = null;
      _resolvedAddress = null;
    });
    try {
      final locations = await locationFromAddress(rawAddress);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        String resolved = rawAddress;
        try {
          final placemarks =
              await placemarkFromCoordinates(loc.latitude, loc.longitude);
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            final parts = [
              if (p.street != null && p.street!.isNotEmpty) p.street,
              if (p.postalCode != null && p.postalCode!.isNotEmpty) p.postalCode,
              if (p.locality != null && p.locality!.isNotEmpty) p.locality,
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
        _showSnack('Adresse localisée : $resolved', const Color(0xFF16A34A));
      } else {
        throw Exception('Aucun résultat');
      }
    } catch (e) {
      setState(() {
        _isGeocoding = false;
        _addressVerified = false;
      });
      _showSnack(
          'Adresse introuvable. Essayez un format plus précis.', Colors.red);
    }
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

  // ── Soumission ────────────────────────────────────────────
  Future<void> _submitForm() async {
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
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Upload des nouvelles photos si présentes
      List<String> newUrls = [];
      if (_newImages.isNotEmpty) {
        final folder = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}';
        newUrls = await _uploadNewImages(folder);
      }

      final description =
          '[$_machineType] ${_descCtrl.text.trim()}${_detergentIncluded ? ' — Lessive fournie.' : ''}';

      final updates = {
        'characteristics': {
          'capacityKg': _capacity,
          'brand': _brandCtrl.text.trim(),
          'description': description,
        },
        'pricing': {'pricePerWash': _price, 'currency': 'EUR'},
        'media': {'photoUrls': [..._existingPhotoUrls, ...newUrls]},
        'status': _machineStatus,
        'availability': {
          'availableDays': _availableDays.toList()..sort(),
          'startTimeHour': _startHour,
          'endTimeHour': _endHour,
        },
        'location': {
          'lat': _latitude,
          'lng': _longitude,
          'address': _resolvedAddress ?? _addressCtrl.text.trim(),
        },
      };

      await FirestoreMachineRepository()
          .updateMachine(widget.machine.id, updates);

      if (mounted) {
        setState(() => _isLoading = false);
        context.pop();
        _showSnack('Machine mise à jour avec succès !', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack('Erreur : $e', Colors.red);
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: Text(
          'Modifier la machine',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Photos ─────────────────────────────────────
            _buildPhotosSection(),
            const SizedBox(height: 16),

            // ── Statut ──────────────────────────────────────
            _SectionCard(
              title: 'STATUT',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('Disponibilité de la machine'),
                  const SizedBox(height: 8),
                  _SegmentedSelector(
                    options: const ['AVAILABLE', 'MAINTENANCE'],
                    labels: const ['Disponible', 'Maintenance'],
                    selected: _machineStatus,
                    onChanged: (v) => setState(() => _machineStatus = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Identité ────────────────────────────────────
            _SectionCard(
              title: 'IDENTITÉ DE LA MACHINE',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('Type de machine'),
                  const SizedBox(height: 8),
                  _SegmentedSelector(
                    options: const ['Lave-linge', 'Sèche-linge', 'Combiné'],
                    selected: _machineType,
                    onChanged: (v) => setState(() => _machineType = v),
                  ),
                  const SizedBox(height: 20),
                  _FieldLabel('Marque'),
                  const SizedBox(height: 8),
                  _StyledTextFormField(
                    hintText: 'Ex: Bosch, LG...',
                    controller: _brandCtrl,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Requis' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Tarif & Capacité ────────────────────────────
            _SectionCard(
              title: 'TARIF & CAPACITÉ',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel('Capacité (kg)'),
                          const SizedBox(height: 8),
                          _StyledTextFormField(
                            hintText: '7',
                            initialValue: _capacity.toString(),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Requis';
                              final n = int.tryParse(v);
                              if (n == null || n < 1 || n > 30) return '1–30 kg';
                              return null;
                            },
                            onSaved: (v) => _capacity = int.parse(v!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel('Prix horaire (€)'),
                          const SizedBox(height: 8),
                          _StyledTextFormField(
                            hintText: '4.00',
                            initialValue: _price.toStringAsFixed(2),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Requis';
                              final n =
                                  double.tryParse(v.replaceAll(',', '.'));
                              if (n == null || n <= 0) return 'Invalide';
                              return null;
                            },
                            onSaved: (v) =>
                                _price = double.parse(v!.replaceAll(',', '.')),
                            suffixText: '€/h',
                          ),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _SwitchTile(
                    title: 'Lessive fournie',
                    subtitle:
                        "Le locataire n'a pas besoin d'apporter sa lessive",
                    value: _detergentIncluded,
                    onChanged: (v) => setState(() => _detergentIncluded = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Disponibilités ──────────────────────────────
            _SectionCard(
              title: 'DISPONIBILITÉS',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('Jours disponibles'),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(7, (index) {
                      final day = index + 1;
                      final isSelected = _availableDays.contains(day);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            isSelected
                                ? _availableDays.remove(day)
                                : _availableDays.add(day);
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            padding:
                                const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _primaryColor
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? _primaryColor
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _dayLabels[index],
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  if (_availableDays.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      (_availableDays.toList()..sort())
                          .map((d) => _dayFullLabels[d - 1])
                          .join(', '),
                      style: GoogleFonts.inter(
                          fontSize: 11, color: const Color(0xFF64748B)),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Text('Sélectionnez au moins un jour',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: const Color(0xFFDC2626))),
                  ],
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 20),
                  _FieldLabel('Plage horaire'),
                  const SizedBox(height: 16),
                  _TimeRangeSelector(
                    startHour: _startHour,
                    endHour: _endHour,
                    onStartChanged: (v) => setState(() => _startHour = v),
                    onEndChanged: (v) => setState(() => _endHour = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Localisation ────────────────────────────────
            _buildLocationSection(),
            const SizedBox(height: 16),

            // ── Description ─────────────────────────────────
            _SectionCard(
              title: 'DESCRIPTION',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('Présentez votre machine aux locataires'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextFormField(
                      controller: _descCtrl,
                      maxLines: 4,
                      maxLength: 400,
                      decoration: InputDecoration(
                        hintText:
                            "Décrivez l'état de la machine, l'accès, les conditions...",
                        hintStyle: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8), fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: GoogleFonts.inter(fontSize: 14),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Champ requis'
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton(
            onPressed: _isLoading ? null : _submitForm,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: _primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Enregistrer les modifications',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ── Section photos ────────────────────────────────────────
  Widget _buildPhotosSection() {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _FieldLabel('Photos de la machine'),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _totalPhotos >= 5
                      ? const Color(0xFFEFF6FF)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_totalPhotos / 5',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _totalPhotos >= 5 ? _primaryColor : _slateGray,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 108,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Bouton ajout
                if (_totalPhotos < 5)
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 92,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFFBFDBFE), width: 1.5),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_photo_alternate_outlined,
                              color: _primaryColor, size: 28),
                          const SizedBox(height: 5),
                          Text('Ajouter',
                              style: GoogleFonts.inter(
                                  color: _primaryColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                // Photos existantes (réseau)
                ..._existingPhotoUrls.asMap().entries.map((entry) {
                  final index = entry.key;
                  final url = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            url,
                            width: 92,
                            height: 108,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) => Container(
                              width: 92,
                              height: 108,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.broken_image_outlined,
                                  color: Color(0xFF94A3B8)),
                            ),
                          ),
                        ),
                        if (index == 0)
                          Positioned(
                            bottom: 6,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('Principale',
                                    style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ),
                        Positioned(
                          top: 5,
                          right: 5,
                          child: GestureDetector(
                            onTap: () => setState(
                                () => _existingPhotoUrls.removeAt(index)),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                // Nouvelles photos (locale)
                ..._newImages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final xFile = entry.value;
                  final isFirstOverall =
                      _existingPhotoUrls.isEmpty && index == 0;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            File(xFile.path),
                            width: 92,
                            height: 108,
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (isFirstOverall)
                          Positioned(
                            bottom: 6,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('Principale',
                                    style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ),
                        Positioned(
                          top: 5,
                          right: 5,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _newImages.removeAt(index)),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          if (_totalPhotos == 0) ...[
            const SizedBox(height: 8),
            Text('Ajoutez des photos pour attirer plus de locataires',
                style: GoogleFonts.inter(fontSize: 11, color: _slateGray)),
          ],
        ],
      ),
    );
  }

  // ── Section localisation ──────────────────────────────────
  Widget _buildLocationSection() {
    return _SectionCard(
      title: 'LOCALISATION',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FieldLabel('Adresse de la machine'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: _addressVerified
                      ? Border.all(
                          color: const Color(0xFF16A34A), width: 1.5)
                      : null,
                ),
                child: TextFormField(
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
                    hintText: 'Ex: 12 rue de la Paix, 75001 Paris',
                    hintStyle:
                        GoogleFonts.inter(color: const Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    prefixIcon: Icon(
                      _addressVerified
                          ? Icons.check_circle
                          : Icons.location_on_outlined,
                      color: _addressVerified
                          ? const Color(0xFF16A34A)
                          : _slateGray,
                      size: 20,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Adresse requise';
                    if (!_addressVerified) {
                      return "Cliquez sur l'icône pour vérifier l'adresse";
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: _primaryColor,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _isGeocoding ? null : _geocodeAddress,
                child: Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  child: _isGeocoding
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.search_rounded,
                          color: Colors.white, size: 22),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          if (_addressVerified && _resolvedAddress != null) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF16A34A), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _resolvedAddress!,
                    style: GoogleFonts.inter(
                        color: const Color(0xFF15803D),
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ]),
            ),
          ] else if (!_addressVerified &&
              _addressCtrl.text.isNotEmpty) ...[
            Text(
              "Cliquez sur l'icône de recherche pour vérifier l'adresse.",
              style: GoogleFonts.inter(
                  fontSize: 11, color: const Color(0xFFD97706)),
            ),
          ],
        ],
      ),
    );
  }
}
