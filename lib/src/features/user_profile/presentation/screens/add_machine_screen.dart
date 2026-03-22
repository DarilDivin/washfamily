import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geocoding/geocoding.dart';
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

  // ── Données test pré-remplies pour accélérer les tests dev ────
  String _brand = 'Bosch';
  String _model = 'WAN28040';
  int _capacity = 7;
  double _price = 4.5;
  String _description = 'Machine en très bon état, acquérie il y a 2 ans. Accessible 7j/7 de 8h à 22h. Parking disponible.';
  String _machineType = 'Lave-linge';
  bool _detergentIncluded = true;
  bool _isLoading = false;

  // Géolocalisation (pré-remplie avec Tour Eiffel pour les tests)
  double? _latitude = 48.8566;
  double? _longitude = 2.3522;
  String _resolvedAddress = '5 Avenue Anatole France, 75007 Paris';

  static const _primaryColor = Color(0xFF2563EB);
  static const _bgColor = Color(0xFFF8FAFC);
  static const _cardColor = Colors.white;
  static const _slateGray = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    // Pré-remplissage de l'adresse texte
    _addressCtrl.text = '5 Avenue Anatole France, 75007 Paris';
  }

  Future<void> _geocodeAddress() async {
    final rawAddress = _addressCtrl.text.trim();
    if (rawAddress.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final locations = await locationFromAddress(rawAddress);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final placemarks = await placemarkFromCoordinates(loc.latitude, loc.longitude);
        final place = placemarks.isNotEmpty ? placemarks.first : null;

        setState(() {
          _latitude = loc.latitude;
          _longitude = loc.longitude;
          _resolvedAddress = place != null
              ? '${place.street}, ${place.postalCode} ${place.locality}'
              : rawAddress;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('📍 Adresse localisée : $_resolvedAddress'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Adresse introuvable. Veuillez la reformuler.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('⚠️ Veuillez valider l\'adresse pour localiser la machine.'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Utilisateur non connecté");

      final newMachine = MachineModel(
        id: '', // sera remplacé par l'ID Firebase
        ownerId: user.uid,
        latitude: _latitude!,
        longitude: _longitude!,
        address: _resolvedAddress,
        capacityKg: _capacity,
        brand: _brand,
        description: '[$_machineType] $_description${_detergentIncluded ? ' — Lessive fournie.' : ''}',
        pricePerWash: _price,
        currency: 'EUR',
        photoUrls: const [],
        status: 'AVAILABLE',
        rating: 0.0,
        reviewCount: 0,
      );

      await FirestoreMachineRepository().addMachine(newMachine);

      if (mounted) {
        setState(() => _isLoading = false);
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Machine mise en location avec succès !'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: Text(
          'Ma nouvelle machine',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: _cardColor,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
        surfaceTintColor: Colors.transparent,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Section Photo ───────────────────────────────────────
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFBFDBFE), style: BorderStyle.solid),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_a_photo_outlined, size: 40, color: _primaryColor),
                        const SizedBox(height: 8),
                        Text(
                          "Ajouter des photos",
                          style: GoogleFonts.inter(color: _primaryColor, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          "JPG, PNG — Max 5 photos",
                          style: GoogleFonts.inter(color: _slateGray, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Section Identité de la machine ──────────────────────
            _SectionCard(
              title: "IDENTITÉ DE LA MACHINE",
              child: Column(
                children: [
                  // Type de machine
                  _FieldLabel("Type de machine"),
                  const SizedBox(height: 8),
                  _SegmentedSelector(
                    options: const ['Lave-linge', 'Sèche-linge', 'Combiné'],
                    selected: _machineType,
                    onChanged: (v) => setState(() => _machineType = v),
                  ),
                  const SizedBox(height: 20),

                  // Marque + Modèle
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _FieldLabel("Marque"),
                      const SizedBox(height: 8),
                      _StyledTextFormField(
                        hintText: "Ex: Bosch, LG...",
                        initialValue: _brand,
                        validator: (v) => v == null || v.isEmpty ? "Requis" : null,
                        onSaved: (v) => _brand = v!,
                      ),
                    ])),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _FieldLabel("Modèle (optionnel)"),
                      const SizedBox(height: 8),
                      _StyledTextFormField(
                        hintText: "Ex: WAN28040",
                        initialValue: _model,
                        onSaved: (v) => _model = v ?? '',
                      ),
                    ])),
                  ]),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Section Tarif & Capacité ────────────────────────────
            _SectionCard(
              title: "TARIF & CAPACITÉ",
              child: Column(
                children: [
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _FieldLabel("Capacité (kg)"),
                      const SizedBox(height: 8),
                      _StyledTextFormField(
                        hintText: "7",
                        initialValue: "7",
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Requis";
                          final n = int.tryParse(v);
                          if (n == null || n < 1 || n > 30) return "1–30 kg";
                          return null;
                        },
                        onSaved: (v) => _capacity = int.parse(v!),
                      ),
                    ])),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _FieldLabel("Prix par lavage (€)"),
                      const SizedBox(height: 8),
                      _StyledTextFormField(
                        hintText: "4.00",
                        initialValue: "4.0",
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Requis";
                          final n = double.tryParse(v.replaceAll(',', '.'));
                          if (n == null || n <= 0) return "Invalide";
                          return null;
                        },
                        onSaved: (v) => _price = double.parse(v!.replaceAll(',', '.')),
                        suffixText: "€",
                      ),
                    ])),
                  ]),
                  const SizedBox(height: 16),
                  // Lessive incluse
                  _SwitchTile(
                    title: "Lessive fournie",
                    subtitle: "Le locataire n'a pas besoin d'apporter sa lessive",
                    value: _detergentIncluded,
                    onChanged: (v) => setState(() => _detergentIncluded = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Section Localisation ────────────────────────────────
            _SectionCard(
              title: "LOCALISATION",
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
                        ),
                        child: TextFormField(
                          controller: _addressCtrl,
                          decoration: InputDecoration(
                            hintText: "Ex: 12 rue de la Paix, 75001 Paris",
                            hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            prefixIcon: const Icon(Icons.location_on_outlined, color: _slateGray, size: 20),
                          ),
                          validator: (v) => v == null || v.isEmpty ? "Adresse requise" : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: _primaryColor,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _geocodeAddress,
                        child: Container(
                          width: 52,
                          height: 52,
                          alignment: Alignment.center,
                          child: const Icon(Icons.search_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ]),
                  if (_latitude != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _resolvedAddress,
                            style: GoogleFonts.inter(color: const Color(0xFF16A34A), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Section Description ─────────────────────────────────
            _SectionCard(
              title: "DESCRIPTION",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel("Présentez votre machine aux locataires"),
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
                        hintText: "Décrivez l'état de la machine, l'accès, les horaires disponibles...",
                        hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: GoogleFonts.inter(fontSize: 14),
                      validator: (v) => v == null || v.isEmpty ? "Champ requis" : null,
                      onSaved: (v) => _description = v!,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 80), // Espace pour le bouton bas
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text("Mettre en location",
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Composants réutilisables du formulaire
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
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
    return Text(
      text,
      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF374151)),
    );
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
    required this.hintText,
    this.initialValue,
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
              ),
              alignment: Alignment.center,
              child: Text(
                option,
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

  const _SwitchTile({required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
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
