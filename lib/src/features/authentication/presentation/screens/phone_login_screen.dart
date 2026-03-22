import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:washfamily/src/features/authentication/data/services/auth_service.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isButtonEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      setState(() {
        _isButtonEnabled = _phoneController.text.length >= 9;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface, size: 20),
              onPressed: () => context.pop(),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 40.0, bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Quel est votre\nnuméro?",
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Nous vous enverrons un code par SMS pour vérifier votre identité.",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF475569),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 48),

              // --- CHAMP TÉLÉPHONE PREMIUM ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Text(
                      "🇫🇷  +33",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        autofocus: true,
                        keyboardType: TextInputType.phone,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: "6 12 34 56 78",
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Info block
              Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: theme.primaryColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "DONNÉES SÉCURISÉES ET CRYPTÉES",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 0.5),
                  )
                ],
              ),

              const Spacer(),

              // --- BOUTON D'ACTION ---
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (_isButtonEnabled && !_isLoading)
                      ? () {
                          setState(() => _isLoading = true);
                          final number = "+33${_phoneController.text.trim()}";

                          AuthService().verifyPhoneNumber(
                            phoneNumber: number,
                            onCodeSent: () {
                              setState(() => _isLoading = false);
                              context.push('/otp', extra: number); 
                            },
                            onError: (error) {
                              setState(() => _isLoading = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error), backgroundColor: Colors.red),
                              );
                            },
                          );
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: _isButtonEnabled ? theme.primaryColor : const Color(0xFFE2E8F0),
                    foregroundColor: _isButtonEnabled ? Colors.white : Colors.grey[500],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Envoyer le code", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          SizedBox(width: 8),
                          Icon(Icons.chevron_right, size: 20),
                        ],
                      ),
                ),
              ),

              const SizedBox(height: 16),
              
              // Footer
              Center(
                child: Text(
                  "En continuant, vous acceptez de recevoir un SMS. Des frais de\nmessage et de données peuvent s'appliquer.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ),
              const SizedBox(height: 24),
              // Links
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("WashFamily", style: TextStyle(fontWeight: FontWeight.w800, color: theme.primaryColor)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Privacy Policy", style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                    const SizedBox(width: 16),
                    Text("Terms of Service", style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                    const SizedBox(width: 16),
                    Text("Legal", style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
