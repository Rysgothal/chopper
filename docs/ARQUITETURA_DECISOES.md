# Decisões de Arquitetura (ADRs Leves) — Chopper

> **Formato:** Título | Status | Contexto | Decisão | Consequências | Alternativas Consideradas  
> **Localização canônica:** `docs/adr/NNN-title.md` (um arquivo por ADR). Este arquivo é índice consolidado.

---

## Índice de ADRs

| # | Título | Status | Data |
|---|--------|--------|------|
| 001 | Clean Architecture Feature-First com Camadas Domain/Data/Presentation | Accepted | 2026-10-07 |
| 002 | Gerenciamento de Estado: BLoC + Freezed + Equatable | Accepted | 2026-10-07 |
| 003 | Injeção de Dependência: GetIt + Injectable (Codegen) | Accepted | 2026-10-07 |
| 004 | Persistência Local: Drift (SQLite) Offline-First | Accepted | 2026-10-07 |
| 005 | Cliente HTTP: Dio com Interceptors (Auth, Retry, Logging, Cache) | Accepted | 2026-10-07 |
| 006 | Navegação: GoRouter com Auth Guards + Deep Linking | Accepted | 2026-10-07 |
| 007 | Notificações Locais + Exact Alarms + Workmanager | Accepted | 2026-10-07 |
| 008 | GraphQL em Feature Isolada (Busca Medicamentos) | Accepted | 2026-10-07 |
| 009 | CI/CD: GitHub Actions + Fastlane (Match iOS) | Accepted | 2026-10-07 |
| 010 | Observabilidade: Firebase Crashlytics + Analytics + Performance | Accepted | 2026-10-07 |
| 011 | Acessibilidade: WCAG 2.1 AA Obrigatória | Accepted | 2026-10-07 |
| 012 | Design System: Tokens + ThemeExtension + Componentes Reutilizáveis | Accepted | 2026-10-07 |
| 013 | Testes: Pirâmide (Unit > Widget > Integration) + Cobertura Mínima | Accepted | 2026-10-07 |
| 014 | Commits Semânticos + Conventional Commits + Commitlint | Accepted | 2026-10-07 |
| 015 | Flavors: flutter_flavorizr (dev, staging, prod) | Accepted | 2026-10-07 |

---

## ADR 001: Clean Architecture Feature-First

**Status:** Accepted  
**Contexto:** Precisamos isolar regras de negócio de frameworks (Flutter, Firebase, Drift) para testabilidade, trocabilidade de implementação e clareza de domínio
**Decisão:** Adotar **Clean Architecture feature-first** (pasta `features/<feature>/data|domain|presentation`) com `core/` para compartilhados (config, errors, utils, widgets/design-system). Camadas:  
- **Domain:** Entities, Repository Contracts (interfaces), Use Cases, Failures/Exceptions — **zero dependências Flutter/Dart packages externos**.  
- **Data:** Repository Implementations, Data Sources (Remote: Dio/GraphQL, Local: Drift), Mappers/DTOs, Models (Freezed/JsonSerializable).  
- **Presentation:** Blocs/Cubits (Freezed states/events), Pages, Widgets — depende apenas de Domain + core.  
**Consequências:**  
- ✅ Testabilidade: Domain puro = unit tests rápidos, sem `flutter_test`.  
- ✅ Troca REST↔GraphQL, Drift↔Hive sem tocar UI.  
- ✅ Onboarding: estrutura previsível para novos devs.  
- ⚠️ Boilerplate inicial (mitigado por codegen: freezed, injectable, drift, graphql).  
**Alternativas:**  
- *MVVM com Riverpod/Provider:* Menos boilerplate, mas acoplamento maior; difícil trocar data sources.  
- *Clean Architecture layer-first (data/domain/presentation no nível raiz):* Menos coesão por feature; escalabilidade menor.

---

## ADR 002: BLoC + Freezed + Equatable

**Status:** Accepted  
**Contexto:** Estado previsível, imutável, testável. Freezed elimina boilerplate de sealed classes, copyWith, toString, equality.  
**Decisão:**  
- **Bloc/Cubit** para todo estado de UI (forms, listas, fluxos assíncronos).  
- **Freezed** para Events/States (sealed classes) + Models/DTOs (data layer).  
- **Equatable** para Entities (domain) e Models (data) — `props` para value equality.  
- **Exhaustiveness checking** obrigatório (`when`/`map` em todos states).  
**Consequências:**  
- ✅ Estados imutáveis → sem bugs de mutação acidental.  
- ✅ Mocks fáceis: `when(() => bloc.state).thenReturn(AuthState.authenticated(uid))`.  
- ✅ Codegen: `flutter pub run build_runner build`.  
- ⚠️ Curva de aprendizado Freezed (mitigado: documentação interna + exemplos no repo).  
**Alternativas:**  
- *Riverpod + Freezed:* Mais conciso, mas menos padrão no mercado enterprise.  
- *Cubit simples + classes manuais:* Mais controle, mas boilerplate alto e propenso a erros.

---

## ADR 003: GetIt + Injectable (Codegen)

**Status:** Accepted  
**Contexto:** DI manual com GetIt funciona, mas `registerSingleton`/`registerFactory` espalhados viram spaghetti. Injectable gera `configureDependencies()` em compile-time.  
**Decisão:**  
- `@injectable` em classes (DataSources, Repositories, UseCases, Blocs).  
- `@module` para third-party (Dio, Drift, Firebase, GraphQL client).  
- `get_it: ^7.6+`, `injectable: ^2.3+`, `injectable_generator: ^2.4+`.  
- Setup único em `injection.dart` (gerado) chamado no `main.dart` antes de `runApp`.  
- Testes: `configureDependencies(environment: Environment.test)` com mocks via `getIt.registerSingleton<MockRepo>(mock)`.  
**Consequências:**  
- ✅ Zero reflection → tree-shaking ok, startup rápido.  
- ✅ Setup idêntico prod/teste.  
- ✅ Fácil substituir implementação (ex: `MockMedicationRepository` no teste).  
- ⚠️ Build runner necessário a cada mudança de anotacao.  
**Alternativas:**  
- *Riverpod/Provider:* DI built-in, mas acopla Presentation ao container.  
- *GetIt manual:* Funciona, mas manutenção manual propensa a erros.

---

## ADR 004: Drift (SQLite) Offline-First

**Status:** Accepted  
**Contexto:** Offline-first é requisito não-negociável. Precisamos: type-safety, migrações versionadas, streams reativas (query → Stream<List<T>>), suporte a transações, upsert, foreign keys.  
**Decisão:**  
- **Drift 2.x** (was Moor) com `sqlite3_flutter_libs` (bundled SQLite).  
- Schema v1 definido em `database/tables/*.dart` (users, medications, doses, sync_queue).  
- DAOs expõem `Stream<List<Entity>>` para UI reativa.  
- **Outbox pattern:** Tabela `sync_queue` (id, operation, entity_type, entity_id, payload_json, status, retry_count, created_at, updated_at).  
- Migrações via `Migrator` versionado (v1→v2 testada local).  
- **Não usar** SharedPreferences, Hive, ObjectBox para dados de domínio.  
**Consequências:**  
- ✅ Type-safe SQL → erros em compile-time.  
- ✅ Streams reativas → UI atualiza automaticamente.  
- ✅ Offline-first nativo: escrita local imediata, sync assíncrona.  
- ⚠️ Schema changes exigem migração cuidadosa.  
**Alternativas:**  
- *Floor (Room-like):* Boa, mas menos maduro que Drift no ecossistema Flutter.  
- *Isar:* Rápido, mas NoSQL; não relacional; migrações menos previsíveis.  
- *SharedPreferences + JSON:* Inadequado para queries, relacionamentos, concorrência.

---

## ADR 005: Dio com Interceptors Obrigatórios

**Status:** Accepted  
**Contexto:** Comunicação HTTP robusta é critério. Precisamos: auth token refresh automático, retry exponencial com jitter, logging estruturado, cache condicional (ETag).  
**Decisão:** `Dio 5.x` com interceptors encadeados (ordem importa):  
1. **AuthInterceptor:** Adiciona `Authorization: Bearer <token>`; em 401 → chama `RefreshTokenUseCase` → retry original request **uma vez**.  
2. **RetryInterceptor:** `Retries(3, exponentialBackoff: true, jitter: true)` para 5xx, timeout, network error.  
3. **LoggingInterceptor:** `pretty: true` em dev; `logPrint` custom para Firebase Performance traces (`api_latency`).  
4. **CacheInterceptor (opcional):** `If-None-Match` + `ETag` para GET idempotentes; armazena em memória (curto TTL).  
- BaseUrl por flavor via `EnvironmentConfig`.  
- Timeouts: `connectTimeout: 10s`, `receiveTimeout: 30s`.  
**Consequências:**  
- ✅ Resiliência padrão enterprise.  
- ✅ Observabilidade: traces + logs correlacionados.  
- ⚠️ Complexidade de refresh token race condition (mitigado: `Lock`/`Completer` singleton no interceptor).  
**Alternativas:**  
- *http package:* Baixo nível; interceptors manuais; sem retry nativo.  
- *GraphQL-only:* Overkill para CRUD simples; REST + GraphQL híbrido é realista.

---

## ADR 006: GoRouter com Auth Guards

**Status:** Accepted  
**Contexto:** Navegação declarativa, deep linking, guards de autenticação, redirecionamento baseado em estado. 
**Decisão:**  
- `GoRouter` com `routes` definidos em `core/config/app_router.dart`.  
- `redirect` guard: se `!authenticated` && `route != login` → `/login`; se `authenticated` && `route == login` → `/home`.  
- `refreshListenable: GoRouterRefreshStream(authBloc.stream)` para reavaliar guard na mudança de estado.  
- Deep links: `chopper://medication/123` → `MedicationDetailPage` (futuro).  
- Navegação programática via `context.go()`, `context.push()` — **nunca** `Navigator.push` direto.  
**Consequências:**  
- ✅ Testável: `GoRouter` pode ser mockado/overridden em widget tests.  
- ✅ Deep linking pronto.  
- ✅ Guards centralizados.  
**Alternativas:**  
- *AutoRoute:* Codegen heavy; bom, mas GoRouter é padrão Google/Flutter team.  
- *Navigator 2.0 manual:* Verboso, propenso a erros de stack.

---

## ADR 007: Notificações Locais + Exact Alarms + Workmanager

**Status:** Accepted  
**Contexto:** Core value do app: alerta no horário exato mesmo em background/doze/reboot. Android 14+ exige `SCHEDULE_EXACT_ALARM`; iOS usa `UNNotificationRequest` + `BGTaskScheduler`.  
**Decisão:**  
- **flutter_local_notifications 17+** com `AndroidNotificationDetails` (fullScreenIntent, priority: high, exactAllowWhileIdle) + `DarwinNotificationDetails` (interruptionLevel: .critical).  
- **timezone** package para IANA tz database (horários corretos em DST).  
- **workmanager 0.5+** para: (a) periodic sync 15min (`PeriodicWorkRequest`); (b) boot strap (`ExistingPeriodicWorkPolicy.KEEP`); (c) fallback reagendamento se exact alarm negado.  
- **Actions:** `Tomar` (abre app + registra taken), `Pular` (registra skipped), `Adiar 15min` (reagenda + analytics).  
- **Cancelamento/reagendamento** via `flutterLocalNotificationsPlugin.cancel(id)` + `zonedSchedule` novo.  
**Consequências:**  
- ✅ Entrega confiável no horário.  
- ✅ Funciona offline (não depende de FCM/push).  
- ⚠️ Permissão `SCHEDULE_EXACT_ALARM` pode ser negada → rationale + fallback workmanager.  
**Alternativas:**  
- *FCM Push:* Requer backend, não funciona offline, latência variável.  
- *AlarmManager nativo (platform channel):* Mais controle, mas código duplicado Android/iOS.

---

## ADR 008: GraphQL em Feature Isolada

**Status:** Accepted  
**Contexto:** Não justifica GraphQL em todo app (overhead). Isolar em 1 feature demonstra: codegen, cache normalizado, fallback offline, comparação REST vs GraphQL.  
**Decisão:**  
- **graphql_flutter 5+** + `graphql_codegen` (build_runner).  
- Schema versionado: `docs/graphql_schema.json` (introspecção de endpoint mock ou Firebase Functions).  
- Feature `medication_search` com `SearchMedicationsQuery` + `SearchMedicationsRepository` (implementa mesmo contract do REST).  
- Cache: `GraphQLCache` normalizado (type policies: `Medication` keyFields `id`).  
- Fallback offline: se `networkError` → busca local no Drift (FTS5 ou LIKE).  
- **Não** usar Apollo Client (não existe Dart oficial); `graphql_flutter` é padrão.  
**Consequências:**  
- ✅ Demonstra GraphQL sem contaminar arquitetura.  
- ✅ Código compartilhado (Domain contract) — swap transparente.  
- ⚠️ Codegen adiciona step no CI (`dart run build_runner`).  
**Alternativas:**  
- *REST-only:* Perde diferencial.  
- *GraphQL full app:* Complexidade desnecessária para portfólio.

---

## ADR 009: CI/CD GitHub Actions + Fastlane

**Status:** Accepted  
**Contexto:** Precisamos: analyze → test → build signed artifacts (Android .aab / iOS .ipa) → upload artifacts. Fastlane gerencia certificados (match), versionamento, build.  
**Decisão:**  
- **GitHub Actions** com 3 jobs:  
  1. `analyze-test` (ubuntu-latest): `flutter analyze` + `flutter test --coverage` + `codecov` upload.  
  2. `build-android` (ubuntu-latest, needs: analyze-test): `flutter build appbundle --release` + `fastlane android build` (match readonly, version bump) → upload `.aab` artifact.  
  3. `build-ios` (macos-latest, needs: analyze-test): `flutter build ipa --release --export-options-plist=ExportOptions.plist` + `fastlane ios build` (match readonly) → upload `.ipa` artifact.  
- **Fastlane** `Fastfile`: lanes `android` / `ios`; `match(type: "appstore", readonly: true)`; `increment_version_code` / `increment_build_number` via `github_run_number`.  
- **Secrets:** `FIREBASE_TOKEN`, `MATCH_PASSWORD`, `MATCH_GIT_URL`, `APP_STORE_CONNECT_API_KEY` (opcional).  
- **Triggers:** `push` to `main` + `pull_request`; `workflow_dispatch` para release manual.  
**Consequências:**  
- ✅ Pipeline reproduzível, artifacts baixáveis.  
- ✅ Fastlane = padrão iOS/Android enterprise.  
- ⚠️ iOS build só em `macos-latest` (custo GitHub Actions minutes).  
**Alternativas:**  
- *Codemagic/Bitrise:* Mais simples mobile, mas GitHub Actions é grátis e padrão open source.  
- *Fastlane only (local):* Não prova CI no GitHub.

---

## ADR 010: Observabilidade Firebase (Crashlytics + Analytics + Performance)

**Status:** Accepted  
**Contexto:** Firebase cobre Crashlytics + Analytics + Performance nativamente, grátis, integração Flutter oficial.  
**Decisão:**  
- **Crashlytics:** `FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true)`; `recordError` + `recordFlutterFatalError` em `FlutterError.onError` + `PlatformDispatcher.instance.onError`; custom keys `{user_id, flavor, version}`.  
- **Analytics:** `FirebaseAnalytics.instance.logEvent(name, parameters)` para eventos da tabela US-63 (login_success, medication_taken, sync_completed, etc.). `setUserId(uid)`. `setAnalyticsCollectionEnabled(true)`.  
- **Performance:** `FirebasePerformance.instance.newTrace('api_latency').start()/stop()` no Dio interceptor; `db_query_time` em DAOs críticos; `notification_schedule_time` no Workmanager. `trace.putAttribute('flavor', flavor)`.  
- **DebugView** habilitado para validação local (`flutter run --dart-define=FIREBASE_ANALYTICS_DEBUG=1`).  
**Consequências:**  
- ✅ Observabilidade real de produção (não mock).  
- ✅ Gratuito, ilimitado, dashboard único.  
- ⚠️ Requer projeto Firebase real (criar no console).  
**Alternativas:**  
- *Sentry + Amplitude + DataDog:* Pagos, múltiplas SDKs, overkill para portfólio.  
- *Mock local:* Não demonstra integração real.

---

## ADR 011: Acessibilidade WCAG 2.1 AA

**Status:** Accepted  
**Contexto:** WCAG 2.1 AA é baseline legal (Brasil: LBI 13.146/2015).  
**Decisão:**  
- **Semântica:** 100% botões/inputs com `Semantics(label: "...", hint: "...")`; `Semantics(liveRegion: true)` para toasts/snackbars; `excludeSemantics` em decorativos.  
- **Contraste:** Tokens de cor validados (4.5:1 texto normal, 3:1 large text). `ThemeData.colorScheme` com `surface`, `onSurface`, `primary`, `onPrimary` conformes.  
- **Escalonamento:** `MediaQuery.textScaler` respeitado; `MediaQuery.of(context).textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 1.5)` opcional.  
- **Touch targets:** `ConstrainedBox(minWidth: 48, minHeight: 48)` em todos `InkWell`/`IconButton`/`ListTile`.  
- **TalkBack/VoiceOver:** Teste manual obrigatório em device físico (Android + iOS) antes do merge.  
- **Lint custom:** `prefer_semantics_labels`, `prefer_contrast_ratio`, `prefer_touch_target_size` no `analysis_options.yaml`.  
**Consequências:**  
- ✅ Inclusão real; 
- ✅ Melhora UX para todos (ex: contraste alto ajuda em sol forte).  
- ⚠️ Revisão manual necessária (ferramentas não pegam tudo).  
**Alternativas:**  
- *Ignorar a11y:* Risco de veto em empresa séria; acessibilidade é qualidade.

---

## ADR 012: Design System Tokens + ThemeExtension

**Status:** Accepted  
**Contexto:** Consistência visual, velocidade, manutenibilidade.
**Decisão:**  
- **Tokens** em `core/design/tokens.dart`: `AppColors` (light/dark), `AppSpacing` (4,8,12,16,24,32), `AppTypography` (TextStyles nomeadas), `AppRadius` (4,8,12,16,24), `AppShadows` (elevation 1-4).  
- **ThemeExtension** `AppThemeExtension` registrada no `ThemeData.extensions` para acesso via `Theme.of(context).extension<AppThemeExtension>()`.  
- **Componentes base** em `core/design/widgets/`: `AppButton` (primary/secondary/outline/ghost, loading, disabled), `AppInput` (label, error, helper, prefix/suffix, semantics), `AppCard` (elevation, onTap), `AppChip` (filter, choice, input), `AppSnackBar` (success/error/info, action), `AppDialog` (alert, confirmation, bottom sheet).  
- **Zero hardcoded colors/spacings** em features — usar tokens via extension.  
- **Storybook/Widgetbook** (opcional) para catálogo visual.  
**Consequências:**  
- ✅ Mudança de tema/global = 1 arquivo.  
- ✅ Onboarding visual: novos devs veem componentes prontos.  
- ⚠️ Investimento inicial (mitigado: copiar de projeto anterior ou template).  
**Alternativas:**  
- *Hardcoded em cada widget:* Dívida técnica imediata; inconsistência visual.  
- *Package externo (Material 3 apenas):* Limita customização; não demonstra habilidade.

---

## ADR 013: Pirâmide de Testes + Cobertura Mínima

**Status:** Accepted  
**Contexto:** Pirâmide clássica: muitos unit (rápidos, isolados), alguns widget (UI logic), poucos integration (E2E, lentos). Cobertura mínima objetiva.  
**Decisão:**  
- **Unit (Domain/Data):** `flutter_test` + `mocktail`; testar UseCases, Repositories, Blocs, Mappers, Services. Target: **>85% linhas, >80% branches**.  
- **Widget (Presentation):** `flutter_test` + `pumpWidget`; testar render, interações, estados (loading/error/success), **semântica (find.bySemanticsLabel)**. Telas críticas: Login, List, Form, Detail, Dashboard, Onboarding.  
- **Integration (E2E):** `integration_test` + `patrol` (opcional); fluxo crítico: login → criar med → notificação → action → sync → relatório → logout. Rodar em device real/emulator no CI (opcional, pode ser local only).  
- **Static:** `flutter analyze` (regras estritas) + `dart format --set-exit-if-changed` no CI.  
- **Mutation testing** (opcional): `dart_mutation_testing` para validar qualidade dos asserts.  
**Consequências:**  
- ✅ Confiança para refatorar; regressões pegas no CI.  
- ⚠️ Tempo de execução CI aumenta (mitigado: cache `pub`, sharding unit tests).  
**Alternativas:**  
- *Só unit tests:* Não pega bugs de UI/integração.  
- *Só integration tests:* Lento, flaky, difícil debugar.

---

## ADR 014: Commits Semânticos + Commitlint

**Status:** Accepted  
**Contexto:** Histórico legível, CHANGELOG automático, revisão de PR facilitada. Padrão enterprise (Angular, Conventional Commits).  
**Decisão:**  
- **Tipos:** `feat`, `fix`, `test`, `ci`, `refactor`, `docs`, `chore`, `perf`, `style`, `build`.  
- **Formato:** `<type>(<scope>): <subject>` (ex: `feat(medication): add search with GraphQL`).  
- **Commitlint** no CI (`@commitlint/cli` + `@commitlint/config-conventional` via `npx` ou `dart` wrapper).  
- **Husky** (local) `commit-msg` hook para falhar rápido.  
- **Breaking changes:** `BREAKING CHANGE:` no body + `!` no type (`feat!: ...`).  
**Consequências:**  
- ✅ Histórico navegável; `git log --oneline --grep="feat"` funciona.  
- ✅ `standard-version`/`semantic-release` futuro para versionamento automático.  
- ⚠️ Disciplina inicial (mitigado: hook local + CI gate).  
**Alternativas:**  
- *Commits livres:* Histórico ilegível; PR review difícil.

---

## ADR 015: Flavors com flutter_flavorizr

**Status:** Accepted  
**Contexto:** 3 ambientes (dev, staging, prod) com configs isoladas: Firebase project, API base URL, bundle ID, app name, ícone. `flutter_flavorizr` gera tudo (Android flavors, iOS schemes, `main_*.dart`, `flutter_flavors.yaml`).  
**Decisão:**  
- `flutter_flavorizr` config em `flutter_flavors.yaml` (root).  
- `flutter pub run flutter_flavorizr` gera: `android/app/src/<flavor>`, `ios/Flutter/Flutter-<flavor>.xcconfig`, `lib/main_<flavor>.dart`.  
- `EnvironmentConfig` (Dart) lê `--dart-define=FLAVOR=dev` ou `const String flavor = String.fromEnvironment('FLAVOR')`.  
- **Não** usar `--dart-define` manual para tudo (frágil, não type-safe).  
**Consequências:**  
- ✅ Build `flutter build appbundle --flavor prod --target lib/main_prod.dart` funciona out-of-the-box.  
- ✅ CI/CD usa flavors nativos.  
- ⚠️ Setup inicial chato (uma vez só).  
**Alternativas:**  
- *`--dart-define` manual:* Funciona, mas propenso a typos; não separa bundle ID/ícone.  
- *Fastlane only:* Não gera código Dart/Android/iOS automaticamente.