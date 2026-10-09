import '/features/auth/domain/repositories/auth_repository.dart';
import '/features/auth/domain/failures/auth_failure.dart';
import '/features/auth/domain/entities/user.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

@injectable
class SignInEmailUseCase {
  final AuthRepository _repository;
  SignInEmailUseCase(this._repository);

  Future<Either<AuthFailure, User>> call({
    required String email,
    required String password,
  }) {
    // Validação básica de domínio
    if (email.trim().isEmpty || !email.contains('@')) {
      return Future.value(const Left(InvalidCredentialsFailure()));
    }

    if (password.length < 6) {
      return Future.value(const Left(WeakPasswordFailure()));
    }

    return _repository.signInEmail(email: email.trim(), password: password);
  }
}