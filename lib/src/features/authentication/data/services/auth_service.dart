import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

class AuthService {

// --- LE SINGLETON (Garantit une instance unique) ---
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();
  // ---------------------------------------------------

  // Instance globale de FirebaseAuth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isGoogleInit = false;

  Future<void> _initGoogle() async {
    if (!_isGoogleInit) {
      await GoogleSignIn.instance.initialize();
      _isGoogleInit = true;
    }
  }

  // On stocke l'ID de vérification renvoyé par Firebase
  String? _verificationId;

  // ==========================================
  // 1. GOOGLE SIGN IN
  // ==========================================
  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _initGoogle();
      
      // Déclenche le flux d'authentification Google
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();

      // Obtient les détails d'authentification de la requête (Tokens)
      final googleAuth = googleUser.authentication;
      
      // Essaie de récupérer un accessToken si possible (optionnel pour Firebase mais utile)
      final googleAuthz = await googleUser.authorizationClient.authorizationForScopes([]);

      // Crée un nouvel identifiant Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuthz?.accessToken,
        idToken: googleAuth.idToken,
      );

      // Connecte l'utilisateur avec Firebase
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint("Erreur Google Auth: $e");
      throw Exception("Erreur de connexion Google : $e");
    }
  }

  // ==========================================
  // 2. EMAIL & MOT DE PASSE
  // ==========================================
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception("Email ou mot de passe incorrect.");
      }
      throw Exception("Erreur de connexion : ${e.message}");
    }
  }

  Future<UserCredential> registerWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception("Le mot de passe est trop faible (6 caractères min).");
      } else if (e.code == 'email-already-in-use') {
        throw Exception("Un compte existe déjà avec cet email.");
      }
      throw Exception("Erreur d'inscription : ${e.message}");
    }
  }

  // ==========================================
  // 3. TÉLÉPHONE (OTP)
  // ==========================================
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function() onCodeSent, // Callback quand le SMS est parti
    required Function(String error) onError, // Callback si erreur
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await _auth.signInWithCredential(credential);
        } catch (e) {
          debugPrint("Erreur auto-login: $e");
        }
      },
      
      verificationFailed: (FirebaseAuthException e) {
        String msg = "Erreur de vérification.";
        if (e.code == 'invalid-phone-number') {
          msg = "Numéro invalide. Format: +33612345678";
        } else if (e.code == 'too-many-requests') {
          msg = "Trop de requêtes ou test expiré. Réessayez plus tard.";
        }
        debugPrint("VerifyFailed: ${e.code} - ${e.message}");
        onError(msg);
      },
      
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        onCodeSent();
      },
      
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<bool> verifyOTP(String smsCode) async {
    if (_verificationId == null) return false;

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      
      await _auth.signInWithCredential(credential);
      return true; // Connexion réussie
      
    } catch (e) {
      debugPrint("Erreur OTP : $e");
      return false; // Code incorrect
    }
  }

  // ==========================================
  // DECONNEXION
  // ==========================================
  Future<void> signOut() async {
    try {
      await _initGoogle();
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}