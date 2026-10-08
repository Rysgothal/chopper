import '/features/auth/domain/repositories/auth_repository.dart';
import '/features/auth/domain/entities/user.dart';
import '/features/auth/domain/failures/auth_failure.dart';
import '../datasources/firebase_auth_data_source.dart';
import '../models/user_model.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:injectable/injectable.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource _dataSource;

  AuthRepositoryImpl(this._dataSource);

  @override
  Future<Either<AuthFailure, User>> signInEmail({
    required String email,
    required String password,
  }) async {
    try {
      final fb.UserCredential credential = await _dataSource
          .signInWithEmailAndPassword(email: email, password: password);
      final fb.User? firebaseUser = credential.user;
      if (firebaseUser == null) {
        return const Left(UnknownAuthFailure('Usuário não retornado pelo Firebase'));
      }
      return Right(UserModel.fromFirebase(firebaseUser).toEntity());
    } on fb.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(UnknownAuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, User>> signInGoogle() async {
    try {
      final fb.UserCredential credential = await _dataSource.signInWithGoogle();
      final fb.User? firebaseUser = credential.user;
      if (firebaseUser == null) {
        return const Left(UnknownAuthFailure('Usuário não retornado pelo Google'));
      }
      return Right(UserModel.fromFirebase(firebaseUser).toEntity());
    } on fb.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(UnknownAuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, void>> signOut() async {
    try {
      await _dataSource.signOut();
      return const Right(null);
    } on fb.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(UnknownAuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, void>> deleteAccount() async {
    try {
      await _dataSource.deleteAccount();
      return const Right(null);
    } on fb.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(UnknownAuthFailure(e.toString()));
    }
  }

  @override
  Future<Option<User>> getCurrentUser() async {
    try {
      final fb.User? firebaseUser = _dataSource.currentUser;
      if (firebaseUser == null) {
        return const None();
      }
      return Some(UserModel.fromFirebase(firebaseUser).toEntity());
    } catch (_) {
      return const None();
    }
  }

  AuthFailure _mapFirebaseAuthException(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
        return const InvalidCredentialsFailure();
      case 'wrong-password':
        return const WrongPasswordFailure();
      case 'invalid-email':
        return const InvalidEmailFailure();
      case 'user-disabled':
        return const UserDisabledFailure();
      case 'user-not-found':
        return const UserNotFoundFailure();
      case 'email-already-in-use':
        return const EmailAlreadyInUseFailure();
      case 'weak-password':
        return const WeakPasswordFailure();
      case 'network-request-failed':
        return const NetworkFailure();
      case 'timeout':
        return const NetworkFailure();
      default:
        return UnknownAuthFailure(e.message);
    }
  }
}