import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  const Failure({this.message = ''});

  final String message;

  @override
  List<Object?> get props => [message];
}
  
class ServerFailure extends Failure {
  const ServerFailure({super.message = 'Erro no servidor. Tente novamente.'});
}

class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Erro ao acessar dados locais.'});
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'Sem conexão com a internet.'});
}

class UnknownFailure extends Failure {
  const UnknownFailure({super.message = 'Erro inesperado. Tente novamente.'});
}
