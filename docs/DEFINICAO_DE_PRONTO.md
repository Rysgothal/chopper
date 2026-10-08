# Definição de Pronto (Definition of Done) — Chopper MVP

> **Aplicável a:** Todos os itens do Backlog (Tasks, Features, Bugs, Docs).  
> **Regra:** Item só vai para "Done" se **TODOS** os critérios abaixo forem atendidos.  
> **Responsável:** Dev (auto-revisão) + CI (gate automatizado).

---

## 1. DoD Geral (Aplica-se a TODOS os itens)

| Critério | Verificação |
|----------|-------------|
| ✅ **Compila sem erros** | `flutter analyze` = 0 errors, 0 warnings (local + CI) |
| ✅ **Formatação** | `dart format --set-exit-if-changed .` passa (local + CI) |
| ✅ **Commits semânticos** | `commitlint` passa no PR (feat/fix/test/ci/refactor/docs/chore/perf/style/build) |
| ✅ **Testes passam** | `flutter test` (unit + widget) = 100% green; coverage ≥ 85% linhas / ≥ 80% branches |
| ✅ **Sem `// TODO`/`// FIXME`** | Busca no escopo do item retorna 0 ocorrências |
| ✅ **Documentação atualizada** | README/ADR/CHANGELOG (se aplicável) refletem a mudança |
| ✅ **Auto-revisão de PR** | PR aberto contra `main` com descrição, screenshots/gifs (UI), checklist DoD preenchido |

---

## 2. DoD por Tipo de Item

### 2.1 Task de Setup/Infra (ex: TB-01, TB-02, TB-04, TB-08, TB-21)

| Critério Específico | Verificação |
|---------------------|-------------|
| `flutter analyze` = 0 | CI job `analyze` verde |
| `flutter test` (unit) passa | Mesmo que 0 testes, comando executa sem erro |
| Configuração versionada | Arquivos gerados/alterados commitados (ex: `flutter_flavors.yaml`, `analysis_options.yaml`, `.github/workflows/ci.yml`, `fastlane/Fastfile`, `injection.dart`) |
| Documentação no README | Seção "Como Rodar" / "CI/CD" / "Flavors" atualizada |
| ADR criado (se decisão arquitetural) | `docs/adr/NNN-title.md` com Contexto, Decisão, Consequências, Alternativas |

### 2.2 Feature — Domain (Entities, Contracts, UseCases) (ex: TB-05, TB-10)

| Critério Específico | Verificação |
|---------------------|-------------|
| Entities imutáveis | `Equatable` + `props` + `copyWith` (se necessário) |
| Contracts (interfaces) | `abstract class` no `domain/repository`; zero dependências `flutter`/`package:` externos |
| UseCases | 1 classe por caso de uso; `call()` ou `execute()`; retornam `Either<Failure, Success>` (ou `Result` pattern) |
| Testes unitários | **>90% cobertura** (linhas + branches); mocks com `mocktail`; cenários: sucesso, falha, edge cases |
| Failures tipados | `Failure` hierarchy (ex: `ServerFailure`, `CacheFailure`, `NetworkFailure`, `ValidationFailure`) |

### 2.3 Feature — Data (RepositoryImpl, DataSources, Mappers, Models) (ex: TB-06, TB-09, TB-11, TB-15)

| Critério Específico | Verificação |
|---------------------|-------------|
| RepositoryImpl implementa Contract | Todos métodos do contract implementados; erros mapeados para `Failure` |
| DataSources isolados | `RemoteDataSource` (Dio/GraphQL) + `LocalDataSource` (Drift) separados |
| Mappers bidirecionais | `toEntity()`, `fromEntity()`, `toDto()`, `fromJson()` testados |
| Models (Freezed/JsonSerializable) | `part 'model.freezed.dart'` + `part 'model.g.dart'`; `build_runner` gera sem erro |
| Testes unitários | **>85% cobertura**; mocks de DataSources; testar: happy path, erro rede, erro parsing, cache hit/miss |
| Drift: DAOs + Streams | Queries expõem `Stream<List<T>>`; `watch*` para reatividade; transações onde necessário |
| Outbox pattern | Tabela `sync_queue` com status enum; processor FIFO testado |

### 2.4 Feature — Presentation (Blocs, Pages, Widgets) (ex: TB-07, TB-12, TB-13, TB-17)

| Critério Específico | Verificação |
|---------------------|-------------|
| Blocs/Cubits (Freezed) | Events/States sealed; `mapEventToState` ou `on<Event>()`; `emit` apenas states válidos; `blocTest` >90% |
| Widget Tests | **Telas críticas**: render, loading, error, success, empty, a11y (`find.bySemanticsLabel`); `pumpWidget` com `MaterialApp` + `BlocProvider` + `GoRouter` test wrapper |
| Acessibilidade (A11y) | **Obrigatório**: `Semantics(label/hint)`, `touch_target ≥ 48dp`, `contraste ≥ 4.5:1`, `textScaler` respeitado, `excludeSemantics` em decorativos |
| Design System | **Zero hardcoded** `Colors`, `TextStyle`, `EdgeInsets`, `BorderRadius` — usar tokens via `ThemeExtension` |
| Navegação | `context.go/push` (GoRouter); zero `Navigator.push` direto |
| Performance | `const` constructors onde possível; `RepaintBoundary` em listas longas; `ListView.builder` + `shrinkWrap: false` |

### 2.5 Integration Test (E2E) (ex: TB-23 fluxo crítico)

| Critério Específico | Verificação |
|---------------------|-------------|
| Fluxo completo passa | `flutter test integration_test/app_test.dart` em device/emulator real = 0 crashes |
| Cenários cobertos | Login → Criar med → Notificação → Action → Sync → Relatório → Logout |
| Mocks de tempo/rede | `clock` package para controlar `DateTime.now()`; `MockDio`/`MockGraphQL` para rede |
| Observabilidade | Traces Performance (`api_latency`, `db_query_time`, `notification_schedule_time`) emitidos |
| Crashlytics | Zero crashes fatais reportados no teste |

### 2.6 CI/CD Job (ex: TB-21)

| Critério Específico | Verificação |
|---------------------|-------------|
| Pipeline verde 3x | Re-run manual 3 vezes consecutivas = sucesso |
| Artifacts gerados | `app-release.aab` (Android) + `app-release.ipa` (iOS) baixáveis na run |
| Versionamento automático | `versionCode`/`versionName` (Android) + `CFBundleVersion`/`CFBundleShortVersionString` (iOS) incrementados via `github_run_number` |
| Fastlane match | `readonly: true`; certificados não expiram; provisioning profiles válidos |
| Cache `pub` | `actions/cache` para `.pub-cache` + `build` directories |

### 2.7 ADR (Architecture Decision Record) (ex: TB-22)

| Critério Específico | Verificação |
|---------------------|-------------|
| Formato padrão | `docs/adr/NNN-title.md` com: **Título, Status, Contexto, Decisão, Consequências, Alternativas** |
| Decisão rastreável | Referência no código/PR/issue relacionada |
| Alternativas documentadas | Pelo menos 2 alternativas consideradas com prós/contras |
| Data + Autor | Header com data ISO (YYYY-MM-DD) e autor |

### 2.8 Documentação (README, DEFINICAO_DE_PRONTO, BACKLOG)

| Critério Específico | Verificação |
|---------------------|-------------|
| README | Badges (CI, coverage, Flutter, Dart, License); Arquitetura (Mermaid); Stack; Como rodar; Testes; CI/CD; Roadmap; Autor |
| BACKLOG | MoSCoW atualizado; estimativas; sequenciamento diário; decisões de corte registradas |
| DEFINICAO_DE_PRONTO | Este arquivo versionado e referenciado no README |

---

## 3. Gates Automatizados (CI) — Não Negociáveis

| Job | Falha = PR Bloqueado |
|-----|----------------------|
| `analyze` | `flutter analyze` > 0 warnings/errors |
| `format` | `dart format --set-exit-if-changed .` falha |
| `test` | Qualquer teste unit/widget falha |
| `coverage` | Cobertura < 85% linhas OU < 80% branches |
| `commitlint` | Commit message fora do padrão Conventional Commits |
| `build-android` | `flutter build appbundle --release` falha |
| `build-ios` | `flutter build ipa --release` falha (macos-latest) |

> **Regra:** Merge na `main` **somente** via PR com **todos gates verdes** + auto-revisão preenchida.

---

## 4. Checklist Rápido de PR (Copiar para Description do PR)

```markdown
## Checklist DoD — PR #[número]

### Geral
- [ ] `flutter analyze` = 0 local
- [ ] `dart format` ok local
- [ ] Commits semânticos (commitlint passa)
- [ ] `flutter test` passa local (unit + widget)
- [ ] Cobertura ≥ 85% / ≥ 80% branches
- [ ] Zero `// TODO`/`// FIXME` no escopo
- [ ] Documentação atualizada (README/ADR/CHANGELOG)

### Por Tipo
#### [ ] Setup/Infra
- [ ] Configs versionadas
- [ ] ADR criado (se arquitetural)

#### [ ] Domain
- [ ] Entities imutáveis (Equatable)
- [ ] Contracts puros (sem deps Flutter)
- [ ] UseCases testados >90%
- [ ] Failures tipados

#### [ ] Data
- [ ] RepositoryImpl implementa Contract
- [ ] DataSources isolados
- [ ] Mappers testados
- [ ] Models Freezed/JsonSerializable gerados
- [ ] Testes >85%
- [ ] Drift DAOs + Streams + Outbox

#### [ ] Presentation
- [ ] Blocs Freezed + blocTest >90%
- [ ] Widget tests telas críticas + a11y
- [ ] Design System tokens (zero hardcoded)
- [ ] GoRouter navegação

#### [ ] Integration/E2E
- [ ] Fluxo crítico passa device real
- [ ] Mocks tempo/rede
- [ ] Traces Performance emitidos
- [ ] Zero crashes Crashlytics

#### [ ] CI/CD
- [ ] Pipeline verde 3x
- [ ] Artifacts .aab/.ipa gerados
- [ ] Versionamento automático
- [ ] Fastlane match readonly

#### [ ] ADR/Docs
- [ ] Formato padrão NNN-title.md
- [ ] Alternativas documentadas
- [ ] README/BACKLOG/DoD atualizados

---

**Assinatura (dev):** ___________________ **Data:** ___________
```

---

## 5. Exceções (Raras, Requerem Aprovação Escrita)

| Exceção | Condição | Aprovação |
|---------|----------|-----------|
| Cobertura < 85% em file gerado (`.g.dart`, `.freezed.dart`) | Arquivo 100% codegen; excluir via `coverage:exclude` no `lcov` | Dev + CI log |
| `flutter analyze` warning em package terceirão | Warning conhecido, não corrigível; documentar no PR com `// ignore: rule_name` + comentário justificativa | Dev |
| Integration test falha flaky conhecida | Documentado em `KNOWN_ISSUES.md`; re-run manual passa 3/3 | Dev + issue GitHub |

> **Princípio:** Exceção não vira regra. Cada exceção deve ter issue de follow-up para resolver na próxima iteração.