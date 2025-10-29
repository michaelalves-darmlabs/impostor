import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Repositório para lidar com todas as operações de autenticação.
class AuthRepository {
  final FirebaseAuth _firebaseAuth;

  AuthRepository({required FirebaseAuth firebaseAuth})
    : _firebaseAuth = firebaseAuth;

  /// Stream para o estado de autenticação do Firebase.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Usuário atual do Firebase.
  User? get currentUser => _firebaseAuth.currentUser;

  /// Realiza o login com Google.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // --- FLUXO WEB ---
        final googleProvider = GoogleAuthProvider();
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        return await _firebaseAuth.signInWithPopup(googleProvider);
      } else {
        // --- FLUXO MOBILE ---
        final GoogleSignInAccount? googleUser = await GoogleSignIn.instance
            .authenticate();
        if (googleUser == null) {
          return null; // cancelado
        }
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        return await _firebaseAuth.signInWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      // Garante que o usuário seja desconectado do Google se o login do Firebase falhar.
      if (!kIsWeb) {
        await GoogleSignIn.instance.signOut();
      }
      // Log simples
      // ignore: avoid_print
      print('FirebaseAuthException: ${e.message} // Code: ${e.code}');
      return null;
    } catch (e) {
      if (!kIsWeb) {
        await GoogleSignIn.instance.signOut();
      }
      // ignore: avoid_print
      print('Um erro inesperado ocorreu durante o login com o Google: $e');
      return null;
    }
  }

  /// Realiza o logout.
  Future<void> signOut() async {
    try {
      if (kIsWeb) {
        await _firebaseAuth.signOut();
      } else {
        await GoogleSignIn.instance.signOut();
        await _firebaseAuth.signOut();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao fazer logout: $e');
    }
  }
}
