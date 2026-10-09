import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../bloc/auth_bloc.dart';

class OnboardingPermissionsPage extends StatelessWidget {
  const OnboardingPermissionsPage({super.key});

  static const routePath = '/onboarding-permissions';

  @override
  Widget build(BuildContext context) => BlocProvider<AuthBloc>.value(
      value: context.read<AuthBloc>(),
      child: const _OnboardingPermissionsView(),
    );
}

class _OnboardingPermissionsView extends StatefulWidget {
  const _OnboardingPermissionsView();

  @override
  State<_OnboardingPermissionsView> createState() => _OnboardingPermissionsViewState();
}

class _OnboardingPermissionsViewState extends State<_OnboardingPermissionsView> {
  final List<_PermissionItem> _permissions = const [
    _PermissionItem._(
      permission: Permission.notification,
      icon: Icons.notifications_active_rounded,
      title: 'Notificações',
      description: 'Receba alertas no horário exato do seu remédio, mesmo com o app fechado.',
      rationale: 'Sem esta permissão, você não receberá lembretes de medicamento.',
    ),
    _PermissionItem._(
      permission: Permission.scheduleExactAlarm,
      icon: Icons.alarm_rounded,
      title: 'Alarmes Exatos',
      description: 'Garante que o alarme toque precisamente no horário programado (Android 12+).',
      rationale: 'Sem isto, notificações podem atrasar ou não disparar no modo Doze.',
    ),
    _PermissionItem._(
      permission: Permission.ignoreBatteryOptimizations,
      icon: Icons.battery_charging_full_rounded,
      title: 'Ignorar Otimização de Bateria',
      description: 'Permite que o app agende notificações e sincronize em segundo plano.',
      rationale: 'O Android pode restringir alarmes e sync se o app estiver otimizado.',
    ),
  ];

  bool _allGranted = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final statuses = await Future.wait(
      _permissions.map((p) => p.permission.status),
    );
    setState(() {
      _allGranted = statuses.every((s) => s.isGranted);
      _isChecking = false;
    });
  }

  Future<void> _requestPermission(_PermissionItem item) async {
    final status = await item.permission.request();
    if (status.isGranted) {
      await _checkPermissions();
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        _showOpenSettingsDialog(item);
      }
    }
  }

  void _showOpenSettingsDialog(_PermissionItem item) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permissão necessária: ${item.title}'),
        content: Text(
          '${item.rationale}\n\nVamos abrir as configurações para você habilitar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Abrir Configurações'),
          ),
        ],
      ),
    );
  }

  void _continue() {
    if (_allGranted) {
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Algumas permissões são obrigatórias para o app funcionar corretamente.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isChecking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Icon(
                Icons.health_and_safety_rounded,
                size: 64,
                color: colorScheme.primary,
                semanticLabel: 'Chopper - Permissões necessárias',
              ),
              const SizedBox(height: 24),
              Text(
                'Permissões Necessárias',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                semanticsLabel: 'Permissões necessárias para o funcionamento do app',
              ),
              const SizedBox(height: 8),
              Text(
                'Para que o Chopper funcione corretamente e envie lembretes no horário certo, precisamos das seguintes permissões:',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Lista de permissões
              Expanded(
                child: ListView.separated(
                  itemCount: _permissions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = _permissions[index];
                    return _PermissionCard(
                      item: item,
                      onRequest: () => _requestPermission(item),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Botão continuar
              FilledButton(
                onPressed: _continue,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _allGranted ? 'Continuar para o App' : 'Concedi as Permissões',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),

              // Skip (apenas se já concedeu todas)
              if (_allGranted)
                TextButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Pular e ir para o App'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionItem {
  final Permission permission;
  final IconData icon;
  final String title;
  final String description;
  final String rationale;

  const _PermissionItem({
    required this.permission,
    required this.icon,
    required this.title,
    required this.description,
    required this.rationale,
  });

  // Para permitir const constructors nos itens da lista
  const _PermissionItem._({
    required this.permission,
    required this.icon,
    required this.title,
    required this.description,
    required this.rationale,
  });
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.item,
    required this.onRequest,
  });

  final _PermissionItem item;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FutureBuilder<PermissionStatus>(
      future: item.permission.status,
      builder: (context, snapshot) {
        final status = snapshot.data ?? PermissionStatus.denied;
        final isGranted = status.isGranted;
        final isPermanentlyDenied = status.isPermanentlyDenied;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isGranted
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: isGranted ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isGranted
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    item.icon,
                    size: 28,
                    color: isGranted
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isGranted
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (isGranted)
                            Icon(
                              Icons.check_circle_rounded,
                              color: colorScheme.primary,
                              size: 24,
                            )
                          else if (isPermanentlyDenied)
                            Icon(
                              Icons.block_rounded,
                              color: colorScheme.error,
                              size: 24,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Action button
                if (!isGranted)
                  FilledButton.tonal(
                    onPressed: onRequest,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(100, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(isPermanentlyDenied ? 'Configurações' : 'Permitir'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}