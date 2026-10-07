import 'package:equatable/equatable.dart';

abstract class AuthFailure extends Equatable {
  final String message;
  const AuthFailure(this.message);
  
  @override 
  List<Object?> get props => [message];
}

class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure() : super('Credenciais inválidas.');
}

class UserNotFoundFailure extends AuthFailure {
  const UserNotFoundFailure() : super('Usuário não encontrado.');
}

class EmailAlreadyInUseFailure extends AuthFailure {
  const EmailAlreadyInUseFailure() : super('O e-mail já está em uso.');
}

class WeakPasswordFailure extends AuthFailure {
  const WeakPasswordFailure() : super('A senha é muito fraca (mínimo 6 caracteres).');
}

class NetworkFailure extends AuthFailure {
  const NetworkFailure() : super('Falha de rede. Verifique sua conexão.');
}

class UnknownAuthFailure extends AuthFailure {
  const UnknownAuthFailure(String? message)
      : super(message == null
            ? 'Ocorreu um erro desconhecido.'
            : 'Ocorreu um erro desconhecido. Motivo: $message');
}

