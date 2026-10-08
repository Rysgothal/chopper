import '/features/auth/domain/repositories/auth_repository.dart';
import '/features/auth/domain/failures/auth_failure.dart';
import 'package:dartz/dartz.dart';

class SignOutUseCase {
  final AuthRepository _repository;
  SignOutUseCase(this._repository);

  Future<Either<AuthFailure, void>> call() => _repository.signOut();
}
