import '/features/auth/domain/repositories/auth_repository.dart';
import '/features/auth/domain/entities/user.dart';
import 'package:dartz/dartz.dart';

class GetCurrentUserUseCase {
  final AuthRepository _repository;
  GetCurrentUserUseCase(this._repository);

  Future<Option<User>> call() => _repository.getCurrentUser();
}