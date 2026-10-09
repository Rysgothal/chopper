import 'package:equatable/equatable.dart';

sealed class AppException extends Equatable implements Exception {
  const AppException({this.message = ''});

  final String message;

  @override
  List<Object?> get props => [message];
}

class ServerException extends AppException {
  const ServerException({
    super.message = 'Erro no servidor',
    this.statusCode,
    this.responseData,
  });

  final int? statusCode;
  final dynamic responseData;

  @override
  List<Object?> get props => [message, statusCode, responseData];
}

class CacheException extends AppException {
  const CacheException({super.message = 'Erro no armazenamento local'});
}

class NetworkException extends AppException {
  const NetworkException({super.message = 'Erro de conexão'});
}

class AuthException extends AppException {
  const AuthException({
    required this.code,
    super.message,
  });

  final String code;

  @override
  List<Object?> get props => [message, code];
}

class PermissionException extends AppException {
  const PermissionException({super.message = 'Permissão negada'});
}