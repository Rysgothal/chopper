import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:injectable/injectable.dart';

@LazySingleton()
class FirebaseAuthDataSource {
  final fb.FirebaseAuth _firebaseAuth;

  FirebaseAuthDataSource(this._firebaseAuth);

  Stream<fb.User?> get authStateChanges => _firebaseAuth.authStateChanges();

  fb.User? get currentUser => _firebaseAuth.currentUser;

  Future<fb.UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) =>
      _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

  Future<fb.UserCredential> signInWithGoogle() async {
    final fb.GoogleAuthProvider provider = fb.GoogleAuthProvider();
    return _firebaseAuth.signInWithProvider(provider);
  }

  Future<void> signOut() => _firebaseAuth.signOut();

  Future<void> deleteAccount() async {
    final fb.User? user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.delete();
    }
  }
}