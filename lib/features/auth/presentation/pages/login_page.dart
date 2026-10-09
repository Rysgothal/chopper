import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/auth_bloc.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  static const routePath = '/login';

  @override
  Widget build(BuildContext context) => BlocProvider<AuthBloc>.value(
      value: context.read<AuthBloc>(),
      child: const _LoginView(),
    );
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        state.maybeWhen(
          authenticated: (user) => context.go('/home'),
          failure: (failure) => _showErrorSnackBar(context, failure.message),
          orElse: () {},
        );
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo / Título
                      Icon(
                        Icons.medication_rounded,
                        size: 64,
                        color: colorScheme.primary,
                        semanticLabel: 'Chopper - Gestão de Medicamentos',
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Bem-vindo ao Chopper',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        semanticsLabel: 'Bem-vindo ao Chopper, gerenciador de medicamentos',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Faça login para acessar seus medicamentos',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          hintText: 'seu@email.com',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                          filled: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe seu e-mail';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'E-mail inválido';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                            tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
                          ),
                          border: const OutlineInputBorder(),
                          filled: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Informe sua senha';
                          }
                          if (value.length < 6) {
                            return 'Senha deve ter pelo menos 6 caracteres';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _handleSignIn(),
                      ),
                      const SizedBox(height: 8),

                      // Forgot password (placeholder)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Recuperação de senha em breve'),
                              ),
                            );
                          },
                          child: const Text('Esqueci a senha'),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sign In Button
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final isLoading = state.maybeWhen(
                            loading: () => true,
                            orElse: () => false,
                          );
                          return FilledButton(
                            onPressed: isLoading ? null : _handleSignIn,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Entrar',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Divider
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OU',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Google Sign In Button
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final isLoading = state.maybeWhen(
                            loading: () => true,
                            orElse: () => false,
                          );
                          return OutlinedButton.icon(
                            onPressed: isLoading
                                ? null
                                : () => context.read<AuthBloc>().add(
                                      const AuthEvent.signInGoogleRequested(),
                                    ),
                            icon: Image.asset(
                              'assets/icons/google_logo.png',
                              height: 20,
                              width: 20,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.g_mobiledata, size: 20),
                            ),
                            label: const Text(
                              'Continuar com Google',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: colorScheme.outline),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // Sign up link (placeholder)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Não tem conta? ',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Cadastro em breve')),
                              );
                            },
                            child: const Text('Criar conta'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleSignIn() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            AuthEvent.signInEmailRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }
}