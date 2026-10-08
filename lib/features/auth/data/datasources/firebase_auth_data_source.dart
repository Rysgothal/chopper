import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:injectable/injectable.dart';

@LazySingleton()
class FirebaseAuthDataSource {
  final fb.FirebaseAuth _firebaseAuth;

  FirebaseAuthDataSource(this._firebaseAuth);

  /// Stream de mudanças de estado de autenticação
  Stream<fb.User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Usuário atual (síncrono)
  fb.User? get currentUser => _firebaseAuth.currentUser;

  /// Login com e-mail e senha
  Future<fb.UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) =>
      _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

  /// Login com Google
  Future<fb.UserCredential> signInWithGoogle() async {
    final fb.GoogleAuthProvider provider = fb.GoogleAuthProvider();
    return _firebaseAuth.signInWithProvider(provider);
  }

  /// Logout
  Future<void> signOut() => _firebaseAuth.signOut();

  /// Excluir conta
  Future<void> deleteAccount() async {
    final fb.User? user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.delete();
    }
  }
}