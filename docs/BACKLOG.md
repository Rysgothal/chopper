# Backlog Priorizado (MoSCoW) — Chopper MVP

> **Legenda:** M=Must, S=Should, C=Could, W=Won't | **Estimativa:** Pontos de história (Fibonacci: 1,2,3,5,8,13) relativos a 1 dev Flutter.  
> **Capacidade estimada:** ~40-50 pts em 10 dias úteis (4-5 pts/dia realistas com setup, revisão, imprevistos).

---

## Sprint 1 (Dias 1-5): Fundação + Auth + Core Domain + Testes Base

| ID | Item | Tipo | MoSCoW | Pts | Dependências | Critério de Pronto |
|----|------|------|--------|-----|--------------|-------------------|
| TB-01 | Setup projeto: flavors (dev/staging/prod), `flutter_flavorizr`, `analysis_options.yaml` estrito, `commitlint` + husky | Task | M | 3 | - | `flutter analyze`=0; 3 `main_*.dart` entry points; `dart run build_runner` roda |
| TB-02 | Clean Architecture structure: `core/` + `features/` skeleton + DI (GetIt+Injectable codegen) | Task | M | 3 | TB-01 | Pastas criadas; `injection.dart` gerado; imports funcionam |
| TB-03 | Design System v1: Tokens (cores, espaçamento, tipografia, raios, sombras) + `ThemeExtension` + componentes base (Button, Input, Card, Chip, Dialog, Snackbar) | Task | M | 5 | TB-01 | Storybook/widgetbook rodando; 0 hardcoded colors nos widgets novos |
| TB-04 | Firebase Config: projeto real + `google-services.json` / `GoogleService-Info.plist` + `firebase_core` init por flavor | Task | M | 2 | TB-01 | `FirebaseApp.configure()` ok; Crashlytics/Analytics/Performance inicializam |
| TB-05 | Auth Domain: Entity `User`, Repository Contract `AuthRepository`, UseCases `SignInEmail`, `SignInGoogle`, `SignOut`, `DeleteAccount`, `GetCurrentUser` | Task | M | 3 | TB-02 | Testes unitários usecases >90% |
| TB-06 | Auth Data: `AuthRepositoryImpl` com `FirebaseAuthDataSource` + mappers + error handling (Failures) | Task | M | 3 | TB-05 | Testes unitários repo >85% |
| TB-07 | Auth Presentation: `AuthBloc` (Freezed states/events) + `LoginPage` + `OnboardingPermissionsPage` (rationale + request) | Task | M | 5 | TB-03, TB-06 | Widget tests Login/Onboarding; BLoC tests >90% |
| TB-08 | GoRouter config: rotas, auth guard, redirect logic, deep link placeholder | Task | M | 2 | TB-07 | Navegação testada; guard bloqueia rotas autenticadas |
| TB-09 | Drift Setup: Database v1 schema (users, medications, doses, sync_queue), DAOs, `DatabaseManager` singleton | Task | M | 5 | TB-02 | `flutter test` passa; migração v1 criada; streams reativas funcionam |
| TB-10 | Medicamento Domain: Entity `Medication`, `Dosage`, `Schedule`, `AdherenceRecord`; Repository Contract; UseCases CRUD + `SearchMedications` (GraphQL placeholder) | Task | M | 5 | TB-02, TB-09 | Testes unitários usecases >90% |
| TB-11 | Medicamento Data: `MedicationRepositoryImpl` (Drift local + outbox queue) + `MedicationLocalDataSource` | Task | M | 5 | TB-09, TB-10 | Testes unitários repo >85%; outbox persistido |
| **Subtotal Sprint 1** | | | | **36** | | |

---

## Sprint 2 (Dias 6-10): UI Medicamentos + Notificações + Sync + GraphQL + Observabilidade + CI/CD + A11y + Docs

| ID | Item | Tipo | MoSCoW | Pts | Dependências | Critério de Pronto |
|----|------|------|--------|-----|--------------|-------------------|
| TB-12 | Medicamento Presentation: `MedicationBloc` + `MedicationListPage` (filtros, busca, ordenação) + `MedicationFormPage` (validação, foto opcional) + `MedicationDetailPage` (ações, histórico) | Task | M | 8 | TB-03, TB-07, TB-11 | Widget tests 4 telas; BLoC tests >90%; a11y labels em todos inputs/botões |
| TB-13 | Notificações Locais: `NotificationService` (flutter_local_notifications + timezone) + agendamento batch + actions (Tomar/Pular/Adiar) + cancelamento/reagendamento | Task | M | 5 | TB-09, TB-11 | Unit tests service; integration test dispara notif mockada |
| TB-14 | Exact Alarms + Workmanager: `AlarmScheduler` (Android exact + iOS) + `WorkmanagerBootstrap` (boot + periodic 15min) + reagendamento pós-reboot | Task | M | 5 | TB-13 | Testes unitários scheduler; log workmanager visível em background |
| TB-15 | Sync Engine: `SyncRepositoryImpl` + Outbox Processor (FIFO, retry exponencial, conflict resolution RN-11) + `SyncBloc` (status stream UI) | Task | M | 8 | TB-11, TB-14 | Unit tests sync logic >85%; integration test simula offline→online |
| TB-16 | GraphQL Feature: `graphql_flutter` + codegen (`build_runner`) + schema `graphql_schema.json` + `MedicationSearchQuery` + cache normalizado + fallback offline | Task | M | 5 | TB-02, TB-10 | Query roda; codegen gera tipos; widget test busca com cache |
| TB-17 | Adesão Dashboard: `AdherenceBloc` + `AdherenceDashboardPage` (métricas, gráficos fl_chart, estado vazio) | Task | S | 5 | TB-09, TB-11 | Widget test; cálculos testados unitariamente |
| TB-18 | Relatório PDF: `ReportUseCase` + `pdf` package + `share_plus` + `ReportPage` (CTA) | Task | S | 3 | TB-17 | Gera PDF válido; share sheet abre; unit test usecase |
| TB-19 | Observabilidade: Crashlytics custom logs + Analytics eventos (tabela US-63) + Performance traces custom + `FirebaseAnalyticsObserver` no GoRouter | Task | M | 3 | TB-04 | Eventos visíveis no DebugView; traces no console Performance |
| TB-20 | Acessibilidade WCAG 2.1 AA: Auditoria completa (semântica, contraste, touch targets, escalonamento, TalkBack/VoiceOver manual) + correções | Task | M | 5 | TB-12, TB-17 | 0 violations `flutter_test` semantics; teste manual TalkBack passa |
| TB-21 | CI/CD GitHub Actions: `analyze-test` (ubuntu) → `build-android` (ubuntu) → `build-ios` (macos) + Fastlane `Fastfile` (match, versioning, build) + artifacts upload | Task | M | 8 | TB-01, TB-04 | Pipeline verde; artifacts .aab/.ipa baixáveis; version code/name auto |
| TB-22 | ADRs + Documentação: `docs/adr/001-architecture.md` ... `008-accessibility.md` + `DEFINICAO_DE_PRONTO.md` + atualização `README.md` | Task | M | 3 | TB-01 | 8 ADRs + DoD + README atualizado |
| TB-23 | Polish & Bug Bash: Correção bugs conhecidos, performance (DevTools profile), revisão código, screenshots/gifs para README | Task | S | 3 | TB-12 a TB-20 | 0 crashes integration test; cold start <1s; APK <25MB |
| **Subtotal Sprint 2** | | | | **61** | | |

---

## Backlog "Should/Could" (Pós-MVP / Se Sobrar Tempo)

| ID | Item | MoSCoW | Pts | Notas |
|----|------|--------|-----|-------|
| TB-31 | Exportação JSON/CSV (LGPD Art. 18) | C | 3 | UseCase + share_plus |
| TB-32 | Patrol integration tests (iOS/Android real device cloud) | C | 5 | Opcional; substitui integration_test nativo |
| TB-33 | Widgetbook/Storybook deploy (GitHub Pages) | C | 2 | Visual regression futuro |
| TB-34 | Firebase Remote Config (feature flags) | C | 2 | Ex: habilitar/desabilitar GraphQL search |
| TB-35 | Biometria (local_auth) para unlock app | W | 3 | Fora do escopo MVP |
| TB-36 | Push notifications FCM (background messages) | W | 5 | Requer backend; fora do escopo |

---

## Resumo de Capacidade vs Escopo

| Categoria | Pontos | Comentário |
|-----------|--------|------------|
| **Must (Sprint 1 + 2)** | 97 | **Excede capacidade realista (~50pts)** — **Cortar/Simplificar obrigatório** |
| **Should** | 11 | Fazer se Must completados antecipadamente |
| **Could** | 12 | Apenas se tempo sobrar |
| **Won't** | 8 | Documentado para não esquecer |

### ⚠️ Decisão de Corte Obrigatória (Scope Reduction)

Para caber em 2 semanas (1 dev), **reduza Must para ~45-50 pts**:

| Item Original | Ação | Nova Estimativa |
|---------------|------|-----------------|
| TB-03 Design System v1 completo | **Mínimo viável**: tokens + Button + Input + Card + Snackbar (sem Dialog/Chip/BottomSheet) | 3 (era 5) |
| TB-12 Medicamento Presentation 4 telas | **Focar em List + Form + Detail** (AdherenceDashboard = TB-17) | 6 (era 8) |
| TB-15 Sync Engine completo | **Simplificar**: Outbox FIFO + retry básico (sem conflict resolution UI); conflict resolution apenas log + server-wins automático | 5 (era 8) |
| TB-16 GraphQL | **Manter** mas **schema mínimo** (apenas `searchMedications`) | 3 (era 5) |
| TB-17 Adesão Dashboard | **Manter** (core value) mas **gráficos simples** (apenas barra 14 dias, sem rosca) | 3 (era 5) |
| TB-18 Relatório PDF | **Mover para Should** (fazer se sobrar) | 0 (Must→Should) |
| TB-20 Acessibilidade | **Focar no essencial**: labels, contraste, touch target, escalonamento (teste manual TalkBack rápido) | 3 (era 5) |
| TB-21 CI/CD | **Manter completo** (qualidade inegociável) | 8 |
| TB-22 ADRs + Docs | **Manter leve** (8 ADRs curtos + DoD + README) | 3 |

**Total Ajustado Must ≈ 47 pts** → Viável em 10 dias com foco rigoroso.

---

## Sequenciamento Sugerido (Daily Focus)

| Dia | Foco Principal | Entregável do Dia |
|-----|----------------|-------------------|
| 1 | TB-01, TB-02, TB-04, TB-09 | Projeto compila, flavors, Firebase, Drift v1 |
| 2 | TB-03 (mínimo), TB-05, TB-06, TB-08 | DI, Auth Domain/Data, Router |
| 3 | TB-07, TB-10, TB-11 | Auth UI + Medicamento Domain/Data |
| 4 | TB-12 (List+Form+Detail), TB-13 | CRUD UI + Notificações base |
| 5 | TB-14, TB-15 (simplificado) | Exact alarms + Workmanager + Sync básico |
| 6 | TB-16 (GraphQL mínimo), TB-17 (dashboard simples) | Busca GraphQL + Adesão |
| 7 | TB-19, TB-20 (essencial) | Observabilidade + A11y core |
| 8 | TB-21 (CI/CD completo) | Pipeline verde end-to-end |
| 9 | TB-22, TB-23 | ADRs, Docs, Polish, Bug bash |
| 10 | Buffer | Correções, gravação demo |

---

## Definição de "Pronto" por Tipo (Referência Rápida)

| Tipo | DoD Resumido |
|------|--------------|
| **Task (Setup/Infra)** | Compila; `flutter analyze`=0; testes unitários passam; documentado no README/ADR |
| **Feature (Domain/Data)** | Entities/Contracts/UseCases/RepoImpl cobertos >85%; mocks gerados; zero `// TODO` |
| **Feature (Presentation)** | BLoC tests >90%; Widget tests telas críticas; A11y labels; Semântica TalkBack ok |
| **Integration Test** | Fluxo E2E passa em device real; 0 crashes; traces Performance coletados |
| **CI/CD Job** | Pipeline verde 3x consecutivas; artifacts gerados; versionamento automático |
| **ADR** | Markdown em `docs/adr/NNN-title.md`: Contexto, Decisão, Consequências, Alternativas |