import '/features/auth/domain/failures/auth_failure.dart';
import '/features/auth/domain/entities/user.dart';
import 'package:dartz/dartz.dart';

abstract class AuthRepository {
  Future<Either<AuthFailure, User>> signInEmail({
    required String email,
    required String password,
  });

  Future<Either<AuthFailure, User>> signInGoogle();
  Future<Either<AuthFailure, void>> signOut();
  Future<Either<AuthFailure, void>> deleteAccount();
  Future<Option<User>> getCurrentUser();
}