# ADR 010: Observabilidade — Firebase Crashlytics + Analytics + Performance

**Status:** Accepted  
**Data:** 2026-10-07  
**Autor:** Lucas Souza Frade

---

## Contexto

Vaga pede: "Crashlytics, New Relic, Amplitude, Logz". Firebase cobre **Crashlytics + Analytics + Performance** nativamente, grátis, integração Flutter oficial (`firebase_core`, `firebase_crashlytics`, `firebase_analytics`, `firebase_performance`). Demonstra maturidade de produção sem custo.

---

## Decisão

### Stack
| Package | Versão | Papel |
|---------|--------|-------|
| `firebase_core` | ^2.27+ | Inicialização multi-flavor |
| `firebase_crashlytics` | ^3.5+ | Crash reporting + logs customizados |
| `firebase_analytics` | ^10.8+ | Eventos estruturados + user properties |
| `firebase_performance` | ^0.9+ | Traces custom (latência API, DB, notificações) |

### Inicialização por Flavor
```dart
// core/config/firebase_options.dart (gerado por `flutterfire configure`)
// lib/main_dev.dart, main_staging.dart, main_prod.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // flavor-specific
  );
  // Crashlytics: coletar erros Dart + nativo
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  // Custom keys para filtrar no dashboard
  await FirebaseCrashlytics.instance.setCustomKey('flavor', Environment.name);
  await FirebaseCrashlytics.instance.setCustomKey('app_version', packageInfo.version);
  await FirebaseCrashlytics.instance.setUserIdentifier(userId); // após login
  
  configureDependencies(environment: Environment.name);
  runApp(const ChopperApp());
}
```

### Crashlytics: Custom Logs + Keys
```dart
// core/observability/crashlytics_service.dart
@injectable
class CrashlyticsService {
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  Future<void> recordError(dynamic error, StackTrace stack, {bool fatal = false, Map<String, dynamic>? context}) async {
    await _crashlytics.recordError(error, stack, fatal: fatal, information: context);
  }

  Future<void> log(String message) async {
    await _crashlytics.log(message);
  }

  Future<void> setUserId(String userId) async {
    await _crashlytics.setUserIdentifier(userId);
  }

  Future<void> setCustomKey(String key, dynamic value) async {
    await _crashlytics.setCustomKey(key, value);
  }
}
```

### Analytics: Eventos Estruturados (Tabela US-63)
```dart
// core/observability/analytics_service.dart
@injectable
class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logLoginSuccess({required String method, required String userId}) async {
    await _analytics.logLogin(loginMethod: method);
    await _analytics.setUserId(id: userId);
  }

  Future<void> logMedicationCreated({
    required String medicationId,
    required bool hasPhoto,
    required String frequencyType,
  }) async {
    await _analytics.logEvent(name: 'medication_created', parameters: {
      'medication_id': medicationId,
      'has_photo': hasPhoto,
      'frequency_type': frequencyType,
    });
  }

  Future<void> logMedicationTaken({
    required String medicationId,
    required int scheduledTs,
    required int takenTs,
    required int delaySeconds,
  }) async {
    await _analytics.logEvent(name: 'medication_taken', parameters: {
      'medication_id': medicationId,
      'scheduled_ts': scheduledTs,
      'taken_ts': takenTs,
      'delay_seconds': delaySeconds,
    });
  }

  Future<void> logNotificationFired({
    required String medicationId,
    required String action, // received, dismissed
  }) async {
    await _analytics.logEvent(name: 'notification_fired', parameters: {
      'medication_id': medicationId,
      'action': action,
    });
  }

  Future<void> logNotificationActionTaken({
    required String medicationId,
    required String action, // take, skip, snooze
  }) async {
    await _analytics.logEvent(name: 'notification_action_taken', parameters: {
      'medication_id': medicationId,
      'action': action,
    });
  }

  Future<void> logSyncCompleted({
    required int created,
    required int updated,
    required int deleted,
    required int conflicts,
    required int durationMs,
  }) async {
    await _analytics.logEvent(name: 'sync_completed', parameters: {
      'created': created,
      'updated': updated,
      'deleted': deleted,
      'conflicts': conflicts,
      'duration_ms': durationMs,
    });
  }

  Future<void> logReportShared({
    required String format, // pdf
    required String channel, // whatsapp, email, drive
  }) async {
    await _analytics.logEvent(name: 'report_shared', parameters: {
      'format': format,
      'channel': channel,
    });
  }
}
```

### Performance: Traces Custom
```dart
// core/observability/performance_service.dart
@injectable
class PerformanceService {
  final FirebasePerformance _performance = FirebasePerformance.instance;

  // Trace de latência API (usado no Dio Interceptor)
  Future<Trace> startApiTrace(String endpoint, String method) async {
    final trace = _performance.newTrace('api_latency')
      ..putAttribute('endpoint', endpoint)
      ..putAttribute('method', method)
      ..putAttribute('flavor', Environment.name);
    await trace.start();
    return trace;
  }

  // Trace de query DB (usado em DAOs críticos)
  Future<Trace> startDbTrace(String operation, String table) async {
    final trace = _performance.newTrace('db_query_time')
      ..putAttribute('operation', operation) // select, insert, update, delete
      ..putAttribute('table', table)
      ..putAttribute('flavor', Environment.name);
    await trace.start();
    return trace;
  }

  // Trace de agendamento notificações (usado no Workmanager)
  Future<Trace> startNotificationScheduleTrace(int count) async {
    final trace = _performance.newTrace('notification_schedule_time')
      ..putAttribute('count', count.toString())
      ..putAttribute('flavor', Environment.name);
    await trace.start();
    return trace;
  }
}
```

### Uso no Dio Interceptor (API Latency)
```dart
// core/network/interceptors/logging_interceptor.dart (trecho)
@override
void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
  final trace = _performanceService.startApiTrace(options.path, options.method);
  options.extra['performance_trace'] = trace;
  handler.next(options);
}

@override
void onResponse(Response response, ResponseInterceptorHandler handler) {
  final trace = response.requestOptions.extra['performance_trace'] as Trace?;
  trace?.putAttribute('status_code', response.statusCode.toString()).stop();
  handler.next(response);
}

@override
void onError(DioException err, ErrorInterceptorHandler handler) {
  final trace = err.requestOptions.extra['performance_trace'] as Trace?;
  trace?.putAttribute('error', err.type.name).putAttribute('status_code', err.response?.statusCode.toString() ?? 'none').stop();
  handler.next(err);
}
```

### Uso em DAO (DB Query Time)
```dart
// data/datasources/local/medication_local_data_source.dart
Future<List<Medication>> getAllMedications(int userId) async {
  final trace = await _performanceService.startDbTrace('select', 'medications');
  try {
    return await _medicationDao.watchActiveMedications(userId).first;
  } finally {
    trace.stop();
  }
}
```

### DebugView (Validação Local)
```bash
# Habilita DebugView para ver eventos em tempo real no console Firebase
flutter run --dart-define=FIREBASE_ANALYTICS_DEBUG=1
# Ou no Android:
adb shell setprop debug.firebase.analytics.app com.yourcompany.chopper.dev
```

---

## Consequências

### Positivas
- ✅ Observabilidade real de produção (não mock) — gratuito, ilimitado
- ✅ Dashboard único: Crashlytics + Analytics + Performance
- ✅ Eventos estruturados = métricas acionáveis (ex: "taxa de snooze 15%")
- ✅ Traces custom correlacionam: API latency → DB time → Notificação schedule
- ✅ Crashlytics: source maps (R8/ProGuard) + custom keys (user_id, flavor, version)

### Negativas/Riscos
- ⚠️ Requer projeto Firebase real (criar no console, `flutterfire configure`)
- ⚠️ Analytics tem latência (~1h para aparecer no dashboard); DebugView para validação imediata
- ⚠️ Performance traces só funcionam em build profile/release (não debug)

### Mitigações
- `flutterfire configure` gera `firebase_options.dart` por flavor
- Documentar no README: "Firebase project: `chopper-dev`, `chopper-staging`, `chopper-prod`"
- Testes de integração validam eventos enviados (mock `FirebaseAnalytics`)

---

## Alternativas Consideradas

| Alternativa | Prós | Contras | Por que não |
|-------------|------|---------|-------------|
| **Sentry + Amplitude + DataDog** | Enterprise features; alertas avançados | Pagos; múltiplas SDKs; overkill para portfólio | Firebase = gratuito, nativo Flutter, suficiente |
| **Mock local (prints)** | Zero dependência | Não demonstra integração real; não impressiona entrevistador | Critério iFood = "observabilidade produção" |

---

## Referências
- [Firebase Flutter Setup](https://firebase.flutter.dev/docs/overview/)
- [Crashlytics Flutter](https://firebase.flutter.dev/docs/crashlytics/overview/)
- [Analytics Flutter](https://firebase.flutter.dev/docs/analytics/overview/)
- [Performance Flutter](https://firebase.flutter.dev/docs/perf-mon/overview/)
- [Custom Traces](https://firebase.google.com/docs/perf-mon/custom-traces)