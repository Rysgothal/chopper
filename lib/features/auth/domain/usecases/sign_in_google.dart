import '/features/auth/domain/repositories/auth_repository.dart';
import '/features/auth/domain/failures/auth_failure.dart';
import '/features/auth/domain/entities/user.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

@injectable
class SignInGoogleUseCase {
  final AuthRepository _repository;
  SignInGoogleUseCase(this._repository);

  Future<Either<AuthFailure, User>> call() => _repository.signInGoogle();
}
