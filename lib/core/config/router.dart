import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/onboarding_permissions_page.dart';

class AppRouter {
  AppRouter(this._authBloc);

  final AuthBloc _authBloc;

  late final GoRouter router = GoRouter(
    initialLocation: LoginPage.routePath,
    debugLogDiagnostics: true,
    redirect: _redirect,
    routes: [
      GoRoute(
        path: LoginPage.routePath,
        name: 'login',
        builder: (context, state) => BlocProvider.value(
          value: _authBloc,
          child: const LoginPage(),
        ),
      ),
      GoRoute(
        path: OnboardingPermissionsPage.routePath,
        name: 'onboarding-permissions',
        builder: (context, state) => BlocProvider.value(
          value: _authBloc,
          child: const OnboardingPermissionsPage(),
        ),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => BlocProvider.value(
          value: _authBloc,
          child: const _HomePlaceholder(),
        ),
      ),
    ],
  );

  String? _redirect(BuildContext context, GoRouterState state) {
    final isAuthenticated = _authBloc.state.maybeWhen(
      authenticated: (_) => true,
      orElse: () => false,
    );
    final isLoggingIn = state.matchedLocation == LoginPage.routePath;
    final isOnboarding = state.matchedLocation == OnboardingPermissionsPage.routePath;

    if (!isAuthenticated && !isLoggingIn && !isOnboarding) {
      return LoginPage.routePath;
    }
    if (isAuthenticated && (isLoggingIn || isOnboarding)) {
      return '/home';
    }
    return null;
  }
}

/// Placeholder para Home - será substituído pela tela real depois
class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Chopper - Home'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => context.read<AuthBloc>().add(const AuthEvent.signOutRequested()),
              tooltip: 'Sair',
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.medication_rounded, size: 64, color: Colors.blue),
              const SizedBox(height: 16),
              const Text(
                'Home - Placeholder',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Usuário autenticado',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
}