import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService {

// --- LE SINGLETON (Garantit une instance unique) ---
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();
  // ---------------------------------------------------

  // Instance globale de FirebaseAuth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // On stocke l'ID de vérification renvoyé par Firebase
  // Il est indispensable pour faire correspondre le SMS au téléphone
  String? _verificationId;

  /// 1. Demande à Firebase d'envoyer un SMS
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function() onCodeSent, // Callback quand le SMS est parti
    required Function(String error) onError, // Callback si erreur (mauvais numéro, etc.)
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      
      // Cas 1 : Sur certains Android, le code est lu automatiquement par le système
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        // Ici, l'utilisateur est connecté automatiquement !
      },
      
      // Cas 2 : Erreur (trop de requêtes, format de numéro invalide)
      verificationFailed: (FirebaseAuthException e) {
        onError(e.message ?? "Erreur de vérification");
      },
      
      // Cas 3 : Le SMS est bien parti. On récupère le fameux "verificationId"
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        onCodeSent(); // On prévient l'UI de passer à l'écran OTP
      },
      
      // Cas 4 : Timeout (si l'utilisateur met trop de temps)
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  /// 2. Valide le code tapé par l'utilisateur
  Future<bool> verifyOTP(String smsCode) async {
    if (_verificationId == null) return false;

    try {
      // On crée un jeton d'authentification avec l'ID de session et le code SMS
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      
      // On tente la connexion
      await _auth.signInWithCredential(credential);
      return true; // Connexion réussie
      
    } catch (e) {
      debugPrint("Erreur OTP : $e");
      return false; // Code incorrect
    }
  }
}