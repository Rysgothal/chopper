import '/features/auth/domain/repositories/auth_repository.dart';
import '/features/auth/domain/entities/user.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetCurrentUserUseCase {
  final AuthRepository _repository;
  GetCurrentUserUseCase(this._repository);

  Future<Option<User>> call() => _repository.getCurrentUser();
}