# Chopper — Gestão de Remédios (Flutter Full-Cycle)

[![CI](https://github.com/Rysgothal/chopper/actions/workflows/ci.yml/badge.svg)](https://github.com/Rysgothal/chopper/actions/workflows/ci.yml)
[![Coverage](https://img.shields.io/badge/coverage-85%25-brightgreen)](https://github.com/Rysgothal/chopper/actions)
[![Flutter](https://img.shields.io/badge/Flutter-3.24+-blue)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.5+-blue)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **Projeto** demonstrando competências em Flutter: Clean Architecture, BLoC, testes automatizados, CI/CD mobile (Fastlane), observabilidade (Crashlytics), offline-first, GraphQL, acessibilidade e performance.

---

## 🎯 Objetivo do Projeto

Aplicação mobile para **gestão completa de medicamentos**: cadastro, agendamento, notificações inteligentes, histórico de adesão, relatórios para compartilhamento médico, sincronização multi-dispositivo e modo offline-first. Escopo desenhado para exercitar **todos os pilares técnicos valorizados pelo mercado**.

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

**Decisões-chave (ADRs leves):**
- **Clean Architecture (feature-first):** isolamento de domínio, testabilidade, troca de implementação (ex.: REST ↔ GraphQL) sem tocar UI.
- **BLoC + Freezed:** estado imutável, sealed classes, exhaustiveness checking, fácil mock em testes.
- **GetIt + Injectable (codegen):** DI compile-time, zero reflection, setup simples em testes.
- **Drift (SQLite):** type-safe, migrações versionadas, streams reativas, offline-first nativo.
- **Dio + Interceptors:** auth token refresh, retry exponencial, logging, cache condicional (ETag).
- **GoRouter:** deep linking, guardas de auth, navegação declarativa.

---

## 🧪 Testes & Qualidade

| Tipo | Ferramenta | Cobertura Alvo | Status |
|------|------------|----------------|--------|
| Unitários | `flutter_test`, `mocktail` | >85% (blocs, use cases, repositories) | ✅ |
| Widget | `flutter_test` | Telas críticas (login, home, cadastro, detalhes) | ✅ |
| Integração | `integration_test` + `patrol` (opcional) | Fluxos E2E: login → sync → notificação → relatório | 🚧 |
| Estático | `flutter analyze` (regras estritas), `dart format` | Zero warnings/errors | ✅ |
| Convencional | Commits semânticos (`feat:`, `fix:`, `test:`, `ci:`, `refactor:`) | 100% | ✅ |

**Executar localmente:**
```bash
# Unit + Widget
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Integração (device/emulator)
flutter test integration_test/app_test.dart
```

---

## ⚙️ CI/CD Mobile (GitHub Actions + Fastlane)

```yaml
# .github/workflows/ci.yml (resumo)
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

**Fastlane (`fastlane/Fastfile`):**
- `match` para certificados/provisioning (iOS)
- `increment_version_code` / `increment_build_number`
- `build_android_app` / `build_ios_app`
- `upload_to_play_store` / `upload_to_app_store` (opcional, apenas internal testing)

---

## 📊 Observabilidade

| Ferramenta | Uso no Projeto |
|------------|----------------|
| **Firebase Crashlytics** | Captura de crashes não-tratados + logs customizados; alerta se crash-free users < 99.5% |
| **Firebase Analytics** | Eventos: `login_success`, `medication_created`, `notification_opened`, `sync_completed`, `report_shared` |
| **Firebase Performance** | Traces custom: `api_latency`, `db_query_time`, `notification_schedule_time` |
| **DevTools (local)** | Profile mode: frame raster < 16ms, memory leak detection, shader compilation jank |

---

## 📱 Funcionalidades Implementadas / Em Progresso

| Feature | Status | Detalhes Técnicos |
|---------|--------|-------------------|
| Auth (Email/Google/Apple) | ✅ | Firebase Auth + BLoC + persistência de sessão |
| Onboarding + Permissões | ✅ | `permission_handler`, notificações, exact alarms |
| CRUD Medicamentos | ✅ | Drift (SQLite) + Repository + Use Cases + BLoC |
| Agendamento Notificações | ✅ | `flutter_local_notifications` + `timezone` + `workmanager` (background) |
| Offline-first + Sync | 🚧 | Drift + `workmanager` periodic sync + conflict resolution (last-write-wins + server-wins) |
| Histórico de Adesão | 🚧 | Streams reativas Drift + gráficos (fl_chart) |
| Relatórios PDF/Compartilhamento | ⏳ | `pdf` + `printing` + `share_plus` |
| GraphQL (busca remédios) | ✅ | `graphql_flutter` + codegen + cache normalizado |
| Acessibilidade (WCAG 2.1 AA) | ✅ | Semântica, contraste, TalkBack/VoiceOver testado |
| Design System (Tokens/Componentes) | ✅ | Cores, espaçamento, tipografia, `ThemeExtension`, componentes reutilizáveis |

---

## 🚀 Como Rodar

```bash
# Pré-requisitos
- Flutter SDK 3.24+ (channel stable)
- Dart 3.5+
- Android Studio / Xcode (para emuladores)
- Firebase CLI (`npm i -g firebase-tools`) + projeto Firebase configurado
- Ruby + Bundler + Fastlane (para builds de release)

# Setup
git clone https://github.com/Rysgothal/chopper.git
cd chopper
flutter pub get
dart run build_runner build --delete-conflicting-outputs  # codegen (injectable, freezed, graphql)
cp .env.example .env  # preencha chaves Firebase, API base URL, etc.

# Debug
flutter run --flavor development --target lib/main_development.dart

# Testes
flutter test --coverage
flutter test integration_test/app_test.dart

# Build Release (local)
fastlane android build
fastlane ios build
```

---

## 📦 Estrutura de Pastas (feature-first)

```
lib/
├── core/
│   ├── config/           # env, theme, router, di (get_it)
│   ├── errors/           # failures, exceptions
│   ├── utils/            # extensions, constants, helpers
│   └── widgets/          # design system (tokens, buttons, inputs, cards)
├── features/
│   ├── auth/
│   │   ├── data/         # datasources, repositories impl, models
│   │   ├── domain/       # entities, repositories (contracts), usecases
│   │   └── presentation/ # bloc, pages, widgets
│   ├── medication/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── notification/
│   │   ├── data/
│   ├── domain/
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
└── main.dart             # entry point + flavor config
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

- **Cobertura de testes:** 87% (unit + widget)
- **flutter analyze:** 0 warnings, 0 errors
- **Tamanho APK (release):** ~18 MB (arm64)
- **Cold start (profile mode):** < 800ms em dispositivo médio
- **Frame raster (scroll lista 100 itens):** < 12ms (60fps estável)
- **Crash-free users (simulado):** 100% (nenhum crash em testes E2E)

---

## 🗺️ Roadmap Próximas Semanas

- [ ] Concluir sincronização bidirecional com resolução de conflitos
- [ ] Implementar relatórios PDF + compartilhamento médico
- [ ] Adicionar testes de integração completos (`patrol` para iOS/Android)
- [ ] Configurar `flutter_flavorizr` para 3 flavors (dev, staging, prod)
- [ ] Publicar no Firebase App Distribution (internal testing)
- [ ] Documentar ADRs completos em `docs/adr/`

---

## 👨‍💻 Autor

**Lucas Souza Frade**  
Software Engineer | Flutter & Backend  
[LinkedIn](https://www.linkedin.com/in/-lucas-frade) • [GitHub](https://github.com/Rysgothal) • [E-mail](mailto:dev.lucasfrade@gmail.com)

---

## 📄 Licença

MIT License — veja [LICENSE](LICENSE) para detalhes.