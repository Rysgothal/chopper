# ADR 007: Notificações Locais + Exact Alarms + Workmanager

**Status:** Accepted  
**Data:** 2026-10-07  
**Autor:** Lucas Souza Frade

---

## Contexto

Core value do app: **alerta no horário exato** mesmo em background/doze/reboot.
- Android 14+ exige permissão `SCHEDULE_EXACT_ALARM` (user-granted)
- iOS usa `UNNotificationRequest` + `BGTaskScheduler` para background
- Workmanager para: sync periódico (15min), boot strap, fallback se exact alarm negado
- iFood valoriza: "gargalos de desempenho, alta disponibilidade, tolerância a falhas"

---

## Decisão

### Stack
| Package | Versão | Papel |
|---------|--------|-------|
| `flutter_local_notifications` | ^17.2+ | Notificações cross-platform (Android/iOS) |
| `timezone` | ^0.9+ | IANA tz database (horários corretos em DST) |
| `workmanager` | ^0.5+ | Background tasks (periodic sync, boot strap) |
| `permission_handler` | ^11.3+ | Request runtime permissions (notifications, exact alarms, battery) |

### Arquitetura

```
features/notification/
├── data/
│   ├── datasources/
│   │   ├── local_notification_data_source.dart  # flutter_local_notifications wrapper
│   │   └── workmanager_data_source.dart         # workmanager wrapper
│   └── repositories/
│       └── notification_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── notification_schedule.dart
│   │   └── notification_action.dart
│   ├── repositories/
│   │   └── notification_repository.dart
│   └── usecases/
│       ├── schedule_medication_notifications.dart
│       ├── cancel_medication_notifications.dart
│       ├── reschedule_all_notifications.dart
│       └── handle_notification_action.dart
└── presentation/
    ├── blocs/
    │   └── notification_bloc.dart
    └── pages/
        └── onboarding_permissions_page.dart
```

### Android: Exact Alarms + Full Screen Intent
```dart
// data/datasources/local_notification_data_source.dart
class LocalNotificationDataSourceImpl implements LocalNotificationDataSource {
  final FlutterLocalNotificationsPlugin _plugin;
  final AndroidNotificationDetails _androidDetails = AndroidNotificationDetails(
    'medication_channel',
    'Medicamentos',
    channelDescription: 'Alertas de horário de remédios',
    importance: Importance.max,
    priority: Priority.high,
    fullScreenIntent: true,           // Acorda tela bloqueada
    playSound: true,
    sound: RawResourceAndroidNotificationSound('notification_sound'),
    vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
    enableVibration: true,
    category: AndroidNotificationCategory.alarm,
    visibility: NotificationVisibility.public,
    exactAllowWhileIdle: true,        // Android 12+ exact alarm
  );

  final DarwinNotificationDetails _iosDetails = DarwinNotificationDetails(
    interruptionLevel: InterruptionLevel.critical, // iOS 15+ critical alert
    presentAlert: true,
    presentSound: true,
    presentBadge: true,
    sound: 'notification_sound.caf',
  );

  @override
  Future<void> scheduleMedicationNotifications(Medication med) async {
    final tzLocation = tz.getLocation('America/Sao_Paulo'); // IANA tz
    for (final schedule in med.schedules) {
      final notificationId = _generateNotificationId(med.id, schedule.index);
      await _plugin.zonedSchedule(
        notificationId,
        'Hora do remédio',
        '${med.name} ${med.dosage} - ${schedule.doseInstruction}',
        _nextOccurrence(schedule, tzLocation),
        NotificationDetails(android: _androidDetails, iOS: _iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: jsonEncode({'medicationId': med.id, 'scheduleIndex': schedule.index, 'action': 'take'}),
      );
    }
  }

  @override
  Future<void> cancelMedicationNotifications(int medicationId) async {
    for (int i = 0; i < maxSchedulesPerMed; i++) {
      await _plugin.cancel(_generateNotificationId(medicationId, i));
    }
  }

  @override
  Future<void> rescheduleAfterReboot() async {
    // Workmanager boot strap chama este método
    // Re-lê Drift → re-agenda todas notificações ativas
  }
}
```

### iOS: Critical Alerts + Background Tasks
```dart
// iOS: Info.plist
<key>UIBackgroundModes</key>
<array>
  <string>remote-notification</string> <!-- Para BGTaskScheduler -->
</array>
<key>UNNotificationExtensionCategory</key>
<string>medication</string>

// Para critical alerts (precisa entitlement da Apple)
// Se não tiver: usar timeSensitive + provisional
```

### Workmanager: Sync Periódico + Boot Strap
```dart
// data/datasources/workmanager_data_source.dart
class WorkmanagerDataSourceImpl implements WorkmanagerDataSource {
  @override
  Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);
    
    // Periodic sync a cada 15min (mínimo Android 15min)
    await Workmanager().registerPeriodicTask(
      'periodic_sync',
      'syncTask',
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );

    // Boot strap (reagendar notificações após reboot)
    await Workmanager().registerOneOffTask(
      'boot_strap',
      'bootstrapTask',
      initialDelay: const Duration(seconds: 30),
      constraints: Constraints(networkType: NetworkType.not_required),
    );
  }

  // Callback estático (top-level ou @pragma('vm:entry-point'))
  @pragma('vm:entry-point')
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      switch (task) {
        case 'syncTask':
          await _syncMedications(); // Chama SyncUseCase
          return Future.value(true);
        case 'bootstrapTask':
          await _rescheduleNotifications(); // Chama NotificationUseCase
          return Future.value(true);
      }
      return Future.value(false);
    });
  }
}
```

### Onboarding de Permissões (Rationale Obrigatório)
```dart
// presentation/pages/onboarding_permissions_page.dart
class OnboardingPermissionsPage extends StatelessWidget {
  const OnboardingPermissionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 1. Explicação visual + texto
          _PermissionCard(
            icon: Icons.notifications_active,
            title: 'Alertas no horário exato',
            description: 'Precisamos agendar alarmes precisos para seus remédios. '
                         'O Android 14+ exige permissão especial "Alarmes exatos".',
            onRequest: () => _requestExactAlarmPermission(context),
          ),
          // 2. Notificações
          _PermissionCard(
            icon: Icons.notifications,
            title: 'Notificações',
            description: 'Receba alertas com ações (Tomar, Pular, Adiar 15min).',
            onRequest: () => _requestNotificationPermission(context),
          ),
          // 3. Battery optimization (não matar app)
          _PermissionCard(
            icon: Icons.battery_charging_full,
            title: 'Funcionamento em background',
            description: 'Evite que o sistema pause o app. Selecione "Não otimizar".',
            onRequest: () => _requestIgnoreBatteryOptimization(context),
          ),
        ],
      ),
    );
  }
}
```

### Actions da Notificação
```dart
// domain/usecases/handle_notification_action.dart
class HandleNotificationActionUseCase implements UseCase<void, NotificationActionParams> {
  final MedicationRepository _medicationRepository;
  final DoseRepository _doseRepository;
  final AnalyticsService _analytics;

  @override
  Future<Either<Failure, void>> call(NotificationActionParams params) async {
    switch (params.action) {
      case NotificationAction.take:
        await _doseRepository.recordDose(Dose(
          medicationId: params.medicationId,
          scheduledAt: params.scheduledAt,
          takenAt: DateTime.now(),
          status: DoseStatus.taken,
        ));
        _analytics.logMedicationTaken(params.medicationId, params.scheduledAt, DateTime.now());
        break;
      case NotificationAction.skip:
        await _doseRepository.recordDose(Dose(
          medicationId: params.medicationId,
          scheduledAt: params.scheduledAt,
          takenAt: DateTime.now(),
          status: DoseStatus.skipped,
        ));
        break;
      case NotificationAction.snooze:
        await _rescheduleSnooze(params.medicationId, params.scheduleIndex, 15.minutes);
        break;
    }
    return const Right(null);
  }
}
```

---

## Consequências

### Positivas
- ✅ Entrega confiável no horário exato (critério iFood: alta disponibilidade)
- ✅ Funciona 100% offline (não depende de FCM/push server)
- ✅ Actions ricas (Tomar/Pular/Adiar) → engajamento real
- ✅ Workmanager fallback: sync + reagendamento pós-reboot/doze

### Negativas/Riscos
- ⚠️ Permissão `SCHEDULE_EXACT_ALARM` pode ser negada → rationale claro + fallback workmanager
- ⚠️ OEM restrictions (Samsung, Xiaomi, Huawei) matam workmanager → testar em devices físicos
- ⚠️ iOS critical alerts precisam entitlement da Apple (App Store review) → usar `timeSensitive` + `provisional` se não tiver

### Mitigações
- Onboarding com rationale visual + texto explicando *por que* cada permissão
- Fallback: `setAlarmClock` (Android) + workmanager periodic para reagendar
- Documentar no README: "Testado em Pixel, Samsung, Xiaomi; exact alarms + workmanager funcionando"

---

## Alternativas Consideradas

| Alternativa | Prós | Contras | Por que não |
|-------------|------|---------|-------------|
| **FCM Push Notifications** | Funciona em background; server-driven | Requer backend; não funciona offline; latência variável; custo | Core value = offline-first; FCM = complementar, não primário |
| **AlarmManager nativo (Platform Channel)** | Controle total Android | Código duplicado Android/iOS; manutenção complexa | `flutter_local_notifications` abstrai bem + workmanager cross-platform |

---

## Referências
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
- [workmanager](https://pub.dev/packages/workmanager)
- [Android Exact Alarms](https://developer.android.com/training/scheduling/alarms#exact)
- [iOS Background Tasks](https://developer.apple.com/documentation/backgroundtasks)