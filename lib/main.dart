import 'package:flutter/material.dart';

import 'core/config/environment.dart';
import 'core/config/router.dart';
import 'core/di/modules.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar ambiente
  Environment.name = 'dev';

  // Inicializar dependências (Firebase, GetIt, Injectable)
  await configureDependencies();

  // Obter AuthBloc do DI
  final authBloc = getIt<AuthBloc>();

  // Criar router com AuthBloc
  final appRouter = AppRouter(authBloc);

  runApp(Chopper(appRouter: appRouter));
}

class Chopper extends StatelessWidget {
  const Chopper({required this.appRouter, super.key});

  final AppRouter appRouter;

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'Chopper',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        routerConfig: appRouter.router,
      );
}