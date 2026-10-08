# Chopper — Gestão de Remédios (Flutter Full-Cycle)

[![Flutter](https://img.shields.io/badge/Flutter-3.24+-blue)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.5+-blue)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **Projeto pessoal** de gestão de medicamentos (offline-first, multi-dispositivo) para demonstrar competências em Flutter: Clean Architecture, BLoC, testes automatizados, CI/CD mobile, observabilidade, offline-first, GraphQL, acessibilidade e performance.

---

## 🎯 Objetivo do Projeto

Aplicação mobile para **gestão completa de medicamentos**: cadastro, agendamento, notificações inteligentes, histórico de adesão, relatórios para compartilhamento médico, sincronização multi-dispositivo e modo offline-first.

**Estado atual:** Em desenvolvimento ativo — fundação pronta, features em implementação.

---

## 🏗️ Arquitetura

```mermaid
graph TD
    A[Presentation Layer] --> B[Domain Layer]
    B --> C[Data Layer]
    C --> D[External Services]

    subgraph Presentation
        A1[Pages / Widgets]
        A2[Blocs / Cubits]
        A3[Theme / Design System]
    end

    subgraph Domain
        B1[Entities]
        B2[Repositories (Contracts)]
        B3[Use Cases]
        B4[Failures / Exceptions]
    end

    subgraph Data
        C1[Repository Implementations]
        C2[Data Sources: Remote (Dio/GraphQL)]
        C3[Data Sources: Local (Drift/SQLite)]
        C4[Mappers / DTOs]
    end

    subgraph External
        D1[Firebase Auth / Crashlytics / Analytics]
        D2[REST API / GraphQL]
        D3[Local Notifications / Workmanager]
    end
```

**Decisões-chave (ADRs em `docs/adr/`):**
- **Clean Architecture (feature-first):** isolamento de domínio, testabilidade, troca de implementação (REST ↔ GraphQL) sem tocar UI.
- **BLoC + Freezed:** estado imutável, sealed classes, exhaustiveness checking, fácil mock em testes.
- **GetIt + Injectable (codegen):** DI compile-time, zero reflection, setup simples em testes.
- **Drift (SQLite):** type-safe, migrações versionadas, streams reativas, offline-first nativo.
- **Dio + Interceptors:** auth token refresh, retry exponencial, logging, cache condicional (ETag).
- **GoRouter:** deep linking, guardas de auth, navegação declarativa.

---

## 🧪 Testes & Qualidade

| Tipo | Ferramenta | Cobertura Alvo | Status |
|------|------------|----------------|--------|
| Unitários | `flutter_test`, `mocktail` | >85% (blocs, use cases, repositories) | 🚧 Em andamento |
| Widget | `flutter_test` | Telas críticas (login, home, cadastro, detalhes) | ⏳ Planejado |
| Integração | `integration_test` + `patrol` (opcional) | Fluxos E2E: login → sync → notificação → relatório | ⏳ Planejado |
| Estático | `flutter analyze` (regras estritas), `dart format` | Zero warnings/errors | ✅ **Passando** |
| Convencional | Commits semânticos (`feat:`, `fix:`, `test:`, `ci:`, `refactor:`) | 100% | ✅ **Aplicado** |

**Executar localmente:**
```bash
# Unit + Widget (quando existirem)
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Integração (device/emulator)
flutter test integration_test/app_test.dart
```

---

## ⚙️ CI/CD Mobile (GitHub Actions + Fastlane) — **Planejado**

```yaml
# .github/workflows/ci.yml (planejado)
jobs:
  analyze-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v4

  build-android:
    needs: analyze-test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build appbundle --release
      - uses: actions/upload-artifact@v4
        with:
          name: app-release.aab
          path: build/app/outputs/bundle/release/app-release.aab

  build-ios:
    needs: analyze-test
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build ipa --release --export-options-plist=ExportOptions.plist
      - uses: actions/upload-artifact@v4
        with:
          name: app-release.ipa
          path: build/ios/ipa/app-release.ipa
```

**Fastlane (`fastlane/Fastfile`) — *a implementar*:**
- `match` para certificados/provisioning (iOS)
- `increment_version_code` / `increment_build_number`
- `build_android_app` / `build_ios_app`
- `upload_to_play_store` / `upload_to_app_store` (internal testing)

---

## 📊 Observabilidade — *Planejado*

| Ferramenta | Uso Previsto no Projeto |
|------------|-------------------------|
| **Firebase Crashlytics** | Captura de crashes não-tratados + logs customizados; custom keys (`user_id`, `flavor`, `version`) |
| **Firebase Analytics** | Eventos: `login_success`, `medication_created`, `medication_taken`, `notification_fired`, `sync_completed`, `report_shared` |
| **Firebase Performance** | Traces custom: `api_latency`, `db_query_time`, `notification_schedule_time` |
| **DevTools (local)** | Profile mode: frame raster < 16ms, memory leak detection, shader compilation jank |

---

## 📱 Funcionalidades — **Status Real**

| Feature | Status | Detalhes |
|---------|--------|----------|
| **Fundação (Config, Lints, Flavors, DI, Environment)** | ✅ **Concluído** | `pubspec.yaml`, `analysis_options.yaml`, `flutter_flavors.yaml`, GetIt/Injectable, Environment config |
| **Clean Architecture Structure** | ✅ **Concluído** | `core/` + `features/` skeleton, pastas `domain/data/presentation` |
| **Auth Domain** | ✅ **Concluído** | `User` entity, `AuthFailure` hierarchy, `AuthRepository` contract, 4 UseCases (SignInEmail, SignInGoogle, SignOut, GetCurrentUser) |
| **Auth Data (Firebase)** | 🚧 **Em andamento** | `FirebaseAuthDataSource`, `AuthRepositoryImpl`, mappers, DI registration |
| **Auth Presentation (BLoC, Pages)** | ⏳ Planejado | `AuthBloc`, `LoginPage`, `OnboardingPermissionsPage` |
| **GoRouter + Auth Guards** | ⏳ Planejado | Rotas, guards, deep linking placeholder |
| **Firebase Config (Auth, Crashlytics, Analytics, Performance)** | ⏳ Planejado | Projetos por flavor, `google-services.json`, `GoogleService-Info.plist` |
| **Design System (Tokens, ThemeExtension, Componentes)** | ⏳ Planejado | Cores, espaçamento, tipografia, `ThemeExtension`, `AppButton`, `AppInput`, `AppCard` |
| **Drift Database v1 (Schema, DAOs, Migrations)** | ⏳ Planejado | Users, Medications, Doses, SyncQueue (outbox), DAOs com streams |
| **Medication Domain (Entity, Repository, UseCases)** | ⏳ Planejado | CRUD + Search (GraphQL placeholder) |
| **Medication Data (Drift + Outbox)** | ⏳ Planejado | LocalDataSource, RepositoryImpl, outbox queue |
| **Medication Presentation (BLoC, Pages)** | ⏳ Planejado | List, Form, Detail com a11y |
| **Notificações Locais + Exact Alarms** | ⏳ Planejado | `flutter_local_notifications`, `timezone`, actions (Tomar/Pular/Adiar) |
| **Workmanager (Sync + Boot Strap)** | ⏳ Planejado | Sync periódico 15min, boot strap, fallback exact alarm |
| **Sync Engine (Outbox Processor)** | ⏳ Planejado | FIFO, retry exponencial, conflict resolution |
| **GraphQL Feature (Busca Medicamentos)** | ⏳ Planejado | `graphql_flutter` + codegen + cache normalizado + fallback offline |
| **Adesão Dashboard** | ⏳ Planejado | Métricas, gráficos `fl_chart`, estado vazio |
| **Relatórios PDF** | ⏳ Planejado | `pdf` + `printing` + `share_plus` |
| **Observabilidade (Crashlytics, Analytics, Performance)** | ⏳ Planejado | Instrumentação completa |
| **Acessibilidade WCAG 2.1 AA** | ⏳ Planejado | Semântica, contraste 4.5:1, touch targets 48dp, TalkBack/VoiceOver |
| **CI/CD GitHub Actions + Fastlane** | ⏳ Planejado | Analyze → Test → Build Android/iOS → Artifacts |
| **ADRs + Documentação** | ✅ **Concluído** | 15 ADRs, Requisitos, Backlog, DoD |

**Legenda:** ✅ Concluído | 🚧 Em andamento | ⏳ Planejado

---

## 🚀 Como Rodar

```bash
# Pré-requisitos
- Flutter SDK 3.24+ (channel stable)
- Dart 3.5+
- Android Studio / Xcode (para emuladores)
- Firebase CLI (`npm i -g firebase-tools`) + projetos Firebase (dev, staging, prod) — *a configurar*
- Ruby + Bundler + Fastlane (para builds de release) — *a configurar*

# Setup
git clone https://github.com/Rysgothal/chopper.git
cd chopper
flutter pub get
dart run build_runner build --delete-conflicting-outputs  # codegen (injectable, freezed, graphql, drift)

# Debug (entry point único temporário)
flutter run

# Testes
flutter analyze          # ✅ Deve passar (0 issues)
flutter test --coverage  # Quando testes existirem
```

---

## 📦 Estrutura de Pastas (feature-first)

```
lib/
├── core/
│   ├── config/           # env, theme, router, di (get_it)
│   ├── errors/           # failures, exceptions
│   ├── utils/            # extensions, constants, helpers
│   └── design/           # design system (tokens, theme_extension, widgets)
├── features/
│   ├── auth/
│   │   ├── data/         # datasources, repositories impl, models
│   │   ├── domain/       # ✅ entities, repositories (contracts), usecases
│   │   └── presentation/ # bloc, pages, widgets
│   ├── medication/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── notification/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── sync/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── report/
│       ├── data/
│       ├── domain/
│       └── presentation/
├── injection.dart        # get_it setup (generated by injectable)
└── main.dart             # entry point temporário (dev)
```

---

## 🛠️ Stack Tecnológica

| Categoria | Tecnologias |
|-----------|-------------|
| **UI & Estado** | Flutter 3.24+, Material 3, BLoC 8+, Freezed, Equatable, GoRouter |
| **Dados & Persistência** | Drift (SQLite), Dio 5+, GraphQL Flutter, Firebase (Auth, Crashlytics, Analytics, Performance) |
| **DI & Codegen** | GetIt, Injectable, Freezed, Build Runner, JsonSerializable, GraphQL Codegen |
| **Testes** | flutter_test, Mocktail, Integration Test, Patrol (opcional), Coverage |
| **CI/CD** | GitHub Actions, Fastlane, Match (iOS certs), Codecov |
| **Qualidade** | flutter_lints (strict), dart_format, commitlint, conventional commits |
| **Notificações/Background** | flutter_local_notifications, timezone, workmanager, permission_handler |
| **Outros** | cached_network_image, fl_chart, pdf, printing, share_plus, intl, url_launcher |

---

## 📈 Métricas de Qualidade (Atuais)

- **flutter analyze:** ✅ 0 warnings, 0 errors
- **Commits semânticos:** ✅ 100% (Conventional Commits)
- **Documentação:** ✅ 15 ADRs, Requisitos, Backlog, DoD
- **Estrutura base:** ✅ Clean Architecture feature-first montada

*Outras métricas (cobertura, APK size, cold start, frame raster) serão medidas quando features estiverem implementadas.*

---

## 🗺️ Próximos Passos (Foco Atual)

1. **Auth Data Layer** — `AuthRepositoryImpl` + `FirebaseAuthDataSource` + mappers + DI
2. **Auth Presentation** — `AuthBloc` + `LoginPage` + `OnboardingPermissionsPage`
3. **GoRouter + Auth Guards** — Rotas protegidas, redirecionamento
4. **Firebase Config** — Projetos por flavor, `google-services.json`, `GoogleService-Info.plist`
5. **Design System** — Tokens, `ThemeExtension`, componentes base (`AppButton`, `AppInput`, `AppCard`)
6. **Drift Database v1** — Schema, DAOs, migrations, outbox queue
7. **Medication Domain + Data** — CRUD offline-first + outbox
8. **Notificações + Workmanager** — Exact alarms, sync periódico, boot strap
9. **GraphQL (Busca)** — Codegen, cache normalizado, fallback offline
10. **CI/CD + Fastlane** — Pipeline completa com artifacts

---

## 👨‍💻 Autor

**Lucas Souza Frade**  
Software Engineer | Flutter & Backend  
[LinkedIn](https://www.linkedin.com/in/-lucas-frade) • [GitHub](https://github.com/Rysgothal) • [E-mail](mailto:dev.lucasfrade@gmail.com)

---

## 📄 Licença

MIT License — veja [LICENSE](LICENSE) para detalhes.