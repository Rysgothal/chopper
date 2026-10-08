# Requisitos do Projeto Chopper

---

## 1. Visão Geral do Produto

**Chopper** é um app mobile de gestão de medicamentos (offline-first, multi-dispositivo) para pessoas acompanharem seu tratamento. O MVP deve evidenciar: Clean Architecture, BLoC, testes automatizados (>85%), CI/CD (GitHub Actions + Fastlane), observabilidade (Firebase Crashlytics/Analytics/Performance), GraphQL em 1 feature, acessibilidade WCAG 2.1 AA, Design System, notificações locais + workmanager, commits semânticos e ADRs.

---

## 2. Atores

| Ator | Descrição |
|------|-----------|
| **Paciente (Usuário Principal)** | Pessoa que gerencia seus próprios medicamentos e adesão. |
| **Cuidador (Opcional)** | Acesso de leitura/compartilhamento de relatórios (fora do MVP). |
| **Sistema (Background)** | Workmanager para sync periódica e agendamento de notificações exact. |
| **Firebase/Backend Simulado** | Auth, Crashlytics, Analytics, Performance, Remote Config (mockado via JSON local ou Firebase Emulator). |

---

## 3. Histórias de Usuário (Formato: Como [ator], quero [ação], para [benefício])

### Épico 1: Fundação Técnica (Infra & Arquitetura)

| ID | História | Prioridade |
|----|----------|------------|
| US-01 | Como **dev**, quero **Clean Architecture feature-first com camadas Domain/Data/Presentation** isoladas, para **trocar implementações (REST↔GraphQL, Drift↔Hive) sem tocar UI** e ter testabilidade nativa. | Must |
| US-02 | Como **dev**, quero **BLoC + Freezed + Equatable** para **estado imutável, sealed classes, exhaustiveness checking e mocks fáceis em testes**. | Must |
| US-03 | Como **dev**, quero **GetIt + Injectable (codegen)** para **DI compile-time, zero reflection, setup idêntico em prod e testes**. | Must |
| US-04 | Como **dev**, quero **GoRouter com guards de auth e deep linking** para **navegação declarativa, testável e protegida**. | Must |
| US-05 | Como **dev**, quero **3 flavors (dev, staging, prod) via flutter_flavorizr** para **configuração isolada por ambiente (Firebase, API base URL, bundle ID)**. | Should |
| US-06 | Como **dev**, quero **analysis_options.yaml estrito (flutter_lints + custom rules) + dart format + commitlint** para **zero warnings/errors em CI e padrão de commits semânticos**. | Must |

### Épico 2: Autenticação & Onboarding

| ID | História | Prioridade |
|----|----------|------------|
| US-11 | Como **paciente**, quero **login via Email/Senha e Google (Firebase Auth)** com **persistência de sessão e auto-login**, para **acessar meus dados de forma segura e contínua**. | Must |
| US-12 | Como **paciente**, quero **tela de onboarding solicitando permissões (notificações, exact alarms, battery optimization)** com **rationale claro**, para **receber alertas de medicamento no horário certo mesmo em background/doze mode**. | Must |
| US-13 | Como **paciente**, quero **logout e exclusão de conta (LGPD)** com **limpeza de dados locais (Drift) e revogação de tokens**, para **controlar meus dados pessoais**. | Should |

### Épico 3: CRUD Medicamentos (Domínio Central)

| ID | História | Prioridade |
|----|----------|------------|
| US-21 | Como **paciente**, quero **cadastrar medicamento** (nome, dosagem, forma, frequência, horários, duração, observações, foto opcional), para **ter minha lista completa e estruturada**. | Must |
| US-22 | Como **paciente**, quero **editar/excluir/arquivar medicamentos** com **confirmação e undo (snackbar)**, para **manter a lista atualizada sem perda acidental**. | Must |
| US-23 | Como **paciente**, quero **listar medicamentos** com **filtros (ativos, arquivados, hoje, todos)**, **ordenação (próximo horário, A-Z)** e **busca textual**, para **encontrar rápido o que preciso**. | Must |
| US-24 | Como **paciente**, quero **visualizar detalhes do medicamento** com **próximas doses, histórico de adesão (últimos 30 dias) e ações rápidas (tomar agora, pular, editar)**, para **agir no contexto certo**. | Must |
| US-25 | Como **paciente**, quero **buscar medicamentos via GraphQL (simulado)** com **autocomplete, cache normalizado e fallback offline**, para **experimentar GraphQL codegen + cache Apollo-like**. | Must |

### Épico 4: Notificações & Agendamento (Core Value)

| ID | História | Prioridade |
|----|----------|------------|
| US-31 | Como **paciente**, quero **notificações locais agendadas (flutter_local_notifications + timezone)** com **som, vibration, actions (Tomar/Pular/Adiar 15min)**, para **aderir ao tratamento sem abrir o app**. | Must |
| US-32 | Como **paciente**, quero **alarms exactos (Android 12+ exact alarms + iOS UNNotificationRequest)** com **workmanager fallback para reagendamento após reboot/doze**, para **garantir entrega no horário exato**. | Must |
| US-33 | Como **paciente**, quero **reagendamento automático ao editar horários/frequência** e **cancelamento ao arquivar**, para **não receber notificações obsoletas**. | Must |
| US-34 | Como **sistema**, quero **workmanager periodic sync (15min) + sync imediata ao abrir app** com **resolução de conflitos (last-write-wins + server-wins para críticos)**, para **manter multi-dispositivo consistente**. | Must |

### Épico 5: Offline-First & Sincronização

| ID | História | Prioridade |
|----|----------|------------|
| US-41 | Como **paciente**, quero **funcionamento 100% offline** (CRUD, notificações, histórico) com **Drift/SQLite como source of truth local**, para **usar em qualquer lugar sem depender de rede**. | Must |
| US-42 | Como **paciente**, quero **sincronização bidirecional em background** com **queue de operações (outbox pattern), retry exponencial e indicador visual de status (synced/pending/conflict)**, para **confiar que meus dados estão seguros**. | Must |
| US-43 | Como **paciente**, quero **resolução de conflitos transparente** (timestamp + version vector) com **opção de revisar conflitos manuais em tela dedicada**, para **não perder dados em edições concorrentes**. | Should |

### Épico 6: Histórico de Adesão & Relatórios

| ID | História | Prioridade |
|----|----------|------------|
| US-51 | Como **paciente**, quero **dashboard de adesão** (taxa % últimos 7/30/90 dias, streaks, medicamentos mais/menos aderidos) com **gráficos fl_chart**, para **visualizar meu progresso**. | Must |
| US-52 | Como **paciente**, quero **gerar relatório PDF** (lista medicamentos, adesão, observações) e **compartilhar via share_plus (WhatsApp, e-mail, Drive)**, para **levar ao médico/farmacêutico**. | Should |
| US-53 | Como **paciente**, quero **exportar dados (JSON/CSV)** para **backup portável e portabilidade (LGPD Art. 18)**, para **ter posse total dos meus dados**. | Could |

### Épico 7: Qualidade, Observabilidade & Acessibilidade

| ID | História | Prioridade |
|----|----------|------------|
| US-61 | Como **dev**, quero **testes unitários (>85% blocs/usecases/repos) com mocktail**, **widget tests (telas críticas)** e **integration tests (fluxos E2E: login→sync→notificação→relatório)**, para **provar qualidade e evitar regressões**. | Must |
| US-62 | Como **dev**, quero **CI/CD GitHub Actions: analyze → test → build (Android .aab / iOS .ipa) → upload artifacts** com **Fastlane (match, versioning, build)**, para **entregar builds de release reprodutíveis**. | Must |
| US-63 | Como **dev**, quero **Firebase Crashlytics (crashes + logs custom), Analytics (eventos-chave), Performance (traces custom: api_latency, db_query_time, notification_schedule_time)**, para **observabilidade de nível produção**. | Must |
| US-64 | Como **paciente com deficiência**, quero **WCAG 2.1 AA: semântica correta, contraste 4.5:1, escalonamento de fonte, TalkBack/VoiceOver testado, touch target ≥48dp**, para **usar o app sem barreiras**. | Must |
| US-65 | Como **dev**, quero **Design System (tokens: cores, espaçamento, tipografia, raios, sombras + ThemeExtension + componentes reutilizáveis: Button, Input, Card, Chip, Dialog, Snackbar, BottomSheet)**, para **consistência visual e velocidade de desenvolvimento**. | Must |
| US-66 | Como **dev**, quero **ADRs leves (Markdown em docs/adr/) para decisões: arquitetura, DI, banco, notificações, GraphQL, CI/CD, testes, acessibilidade**, para **documentar *por que* e facilitar onboarding/revisão**. | Must |

---

## 4. Critérios de Aceite (Gherkin) — Histórias Críticas

### US-11: Login Email/Google + Persistência

```gherkin
Funcionalidade: Autenticação Firebase
  Como paciente
  Quero fazer login e permanecer logado
  Para acessar meus medicamentos com segurança

  Cenário: Login com email/senha válidos
    Dado que o app está na tela de login
    E tenho uma conta cadastrada no Firebase Auth
    Quando preencho email e senha corretos
    E toco em "Entrar"
    Então devo ser redirecionado para a Home
    E meu uid deve estar persistido no AuthState
    E o bloc AuthBloc deve emitir Authenticated(uid)

  Cenário: Auto-login ao reabrir app
    Dado que já fiz login anteriormente
    E não fiz logout
    Quando abro o app (cold start)
    Então a tela de login não deve ser exibida
    E devo ir direto para Home com Authenticated(uid)

  Cenário: Login Google
    Dado que estou na tela de login
    Quando toco em "Continuar com Google"
    E seleciono uma conta Google válida
    Então devo ser autenticado via Firebase Auth
    E redirecionado para Home

  Cenário: Erro de credenciais inválidas
    Dado que estou na tela de login
    Quando preencho email/senha incorretos
    E toco em "Entrar"
    Então devo ver erro "Credenciais inválidas" em Snackbar acessível
    E permanecer na tela de login
```

### US-21/22/23/24: CRUD Medicamentos (Offline-First)

```gherkin
Funcionalidade: Gestão de Medicamentos (CRUD Offline-First)
  Como paciente
  Quero cadastrar, listar, editar e arquivar meus remédios
  Para manter minha lista sempre atualizada mesmo sem internet

  Cenário: Cadastrar medicamento válido offline
    Dado que estou offline (modo avião)
    E estou na tela "Novo Medicamento"
    Quando preencho:
      | campo        | valor                    |
      | nome         | "Dipirona"               |
      | dosagem      | "500mg"                  |
      | forma        | "Comprimido"             |
      | frequencia   | "A cada 8 horas"         |
      | horarios     | ["08:00", "16:00", "00:00"] |
      | duracao_dias | 7                        |
      | observacoes  | "Após refeições"         |
    E toco em "Salvar"
    Então o medicamento deve aparecer na lista "Ativos" imediatamente
    E deve ser persistido no Drift (SQLite)
    E notificações para os 3 horários devem ser agendadas
    E a operação deve entrar na outbox queue com status "pending"

  Cenário: Editar medicamento e reagendar notificações
    Dado que tenho "Dipirona 500mg" ativo com horários ["08:00", "16:00"]
    Quando altero horários para ["09:00", "17:00", "01:00"]
    E salvo
    Então as notificações antigas devem ser canceladas
    E novas notificações para os 3 horários devem ser agendadas
    E a versão local deve incrementar (optimistic locking)

  Cenário: Arquivar medicamento cancela notificações
    Dado que tenho "Amoxicilina" ativo com notificações agendadas
    Quando deslizo para arquivar e confirmo
    Então o medicamento deve mover para lista "Arquivados"
    E todas as notificações pendentes devem ser canceladas
    E a outbox deve registrar operação "archive"

  Cenário: Busca textual e filtros
    Dado que tenho 15 medicamentos (10 ativos, 5 arquivados)
    Quando digito "dip" na busca
    Então devo ver apenas "Dipirona" nos resultados
    Quando seleciono filtro "Arquivados"
    Então devo ver apenas os 5 arquivados
```

### US-31/32/33: Notificações + Exact Alarms + Workmanager

```gherkin
Funcionalidade: Notificações Locais Confiáveis
  Como paciente
  Quero receber alertas no horário exato do remédio
  Para nunca esquecer uma dose

  Cenário: Notificação dispara no horário exato (Android 14+ / iOS 17+)
    Dado que tenho "Losartana 50mg" agendado para 08:00 hoje
    E o app está em background/fechado
    E o device está em Doze mode (Android) / Background (iOS)
    Quando o relógio marca 08:00:00
    Então a notificação deve aparecer com:
      | atributo        | valor esperado              |
      | titulo          | "Hora do remédio"           |
      | corpo           | "Losartana 50mg - 1 comprimido" |
      | actions         | ["Tomar", "Pular", "Adiar 15min"] |
      | sound           | custom (não padrão)         |
      | vibration       | pattern [0, 500, 200, 500]  |
    E o evento analytics "notification_fired" deve ser enviado

  Cenário: Action "Tomar" registra adesão e agenda próxima dose
    Dado que a notificação de "Losartana 50mg 08:00" está visível
    Quando toco em "Tomar"
    Então o app deve abrir na tela de detalhes do medicamento
    E a dose deve ser registrada como "taken" no histórico (Drift)
    E a próxima notificação (16:00) deve permanecer agendada
    E analytics "medication_taken" com {medication_id, scheduled_time, taken_time} deve ser enviado

  Cenário: Reagendamento após reboot do dispositivo
    Dado que tenho 5 medicamentos com notificações agendadas
    Quando o device é reiniciado (boot completed)
    Então o workmanager (boot strap) deve reagendar todas as notificações
    Baseado nos dados persistidos no Drift
    Sem requerer abertura manual do app
```

### US-41/42: Offline-First + Sync Bidirecional

```gherkin
Funcionalidade: Sincronização Bidirecional com Outbox Pattern
  Como paciente
  Quero que minhas alterações offline sincronizem quando houver rede
  Para ter dados consistentes em todos dispositivos

  Cenário: Criação offline → sync online
    Dado que estou offline
    E cadastro "Omeprazol 20mg" (cria local + outbox entry "create")
    Quando a conectividade retorna
    E o workmanager executa sync periódico (ou abro o app)
    Então a outbox deve ser processada em ordem FIFO
    E a chamada POST /medications deve retornar 201 + server_id + server_version
    E o registro local deve atualizar server_id, server_version, status="synced"
    E analytics "sync_completed" com {created: 1, updated: 0, conflicts: 0} deve ser enviado

  Cenário: Conflito de edição concorrente (last-write-wins + server-wins crítico)
    Dado que editei "Dipirona" no Device A (offline) → dosagem "1g"
    E editei "Dipirona" no Device B (online) → dosagem "500mg" + observação "pós almoço"
    E ambos sincronizam
    Quando o sync do Device A processa
    Então o servidor deve detectar version conflict (version vector)
    E aplicar regra: campos não-críticos (observação) → merge; críticos (dosagem) → server-wins
    E o Device A deve receber resposta com conflict_resolution
    E UI deve mostrar toast "Conflito resolvido: dosagem atualizada para 500mg (server)"

  Cenário: Indicador visual de status de sync
    Dado que tenho 3 medicamentos: 2 synced, 1 pending (offline)
    Quando olho a lista principal
    Então devo ver ícone de nuvem:
      | medicamento   | ícone esperado |
      | Dipirona      | ✅ check verde (synced) |
      | Losartana     | ✅ check verde (synced) |
      | Omeprazol     | ⏳ relógio laranja (pending) |
    E ao tocar no ícone pending → tooltip "Aguardando sincronização"
```

### US-51: Dashboard de Adesão

```gherkin
Funcionalidade: Visualização de Adesão
  Como paciente
  Quero ver minha taxa de adesão e streaks
  Para me motivar a manter o tratamento

  Cenário: Dashboard carrega com dados reais do Drift
    Dado que tenho 30 dias de histórico de doses (taken/skipped/missed)
    Quando abro a tela "Adesão"
    Então devo ver:
      | métrica              | cálculo                                    |
      | taxa_7_dias          | (taken_7d / scheduled_7d) * 100          |
      | taxa_30_dias         | (taken_30d / scheduled_30d) * 100        |
      | streak_atual         | dias consecutivos com 100% adesão        |
      | melhor_streak        | maior streak histórica                     |
      | medicamento_top      | maior % adesão individual                  |
      | medicamento_bottom   | menor % adesão individual                  |
    E gráfico de barras (fl_chart) últimos 14 dias
    E gráfico de rosca distribuição taken/skipped/missed

  Cenário: Estado vazio (primeiro uso)
    Dado que não tenho doses registradas
    Quando abro "Adesão"
    Então devo ver estado vazio ilustrado + CTA "Começar a tomar seu primeiro remédio"
    E botão navega para "Novo Medicamento"
```

### US-61: Testes Automatizados (Cobertura & Tipos)

```gherkin
Funcionalidade: Suíte de Testes Automatizados
  Como dev
  Quero cobertura >85% em unit + widget + integration E2E
  Para provar qualidade e evitar regressões

  Cenário: Cobertura unitária (blocs, usecases, repositories)
    Dado que executo `flutter test --coverage`
    Então a cobertura de linhas deve ser ≥ 85%
    E cobertura de branches ≥ 80%
    E zero testes flaky em 3 execuções consecutivas

  Cenário: Widget tests - telas críticas
    Dado que executo testes de widget
    Então devem existir testes para:
      | tela                    | cenários mínimos                              |
      | LoginPage               | sucesso, erro, loading, acessibilidade        |
      | MedicationListPage      | lista vazia, lista com itens, filtro, busca   |
      | MedicationFormPage      | validação, salvar, editar, foto               |
      | MedicationDetailPage    | ações (tomar/pular), histórico, editar        |
      | AdherenceDashboardPage  | dados reais, estado vazio, gráficos           |
      | OnboardingPermissions   | rationale, concessão, negação, abrir settings |
    E cada teste deve usar `testWidgets` + `pumpWidget` + `find.bySemanticsLabel`

  Cenário: Integration test - fluxo E2E crítico
    Dado que executo `flutter test integration_test/app_test.dart` em device real
    Então o fluxo deve completar sem crashes:
      1. Login (email/senha) → Home
      2. Criar medicamento com 3 horários → verificar notificações agendadas (local)
      3. Colocar device em background → aguardar 1 notificação (mock time) → action "Tomar"
      4. Verificar histórico atualizado
      5. Sincronizar (mock network) → verificar status synced
      6. Gerar relatório PDF → share sheet abre
      7. Logout → tela de login
    E traces Performance: api_latency, db_query_time, notification_schedule_time reportados
```

### US-63: Observabilidade (Firebase)

```gherkin
Funcionalidade: Observabilidade Produção
  Como dev
  Quero Crashlytics, Analytics e Performance instrumentados
  Para observabilidade de nível produção

  Cenário: Crash não-tratado capturado no Crashlytics
    Dado que ocorre uma exceção não capturada (ex: null check em release)
    Quando o app crasha
    Então o Crashlytics deve receber o crash com:
      | campo              | valor esperado                    |
      | fatal              | true                                |
      | stack_trace        | completo com source maps (se R8)    |
      | custom_keys        | {user_id, flavor, app_version}      |
      | logs               | últimos 100 logs estruturados       |

  Cenário: Eventos Analytics estruturados
    Dado que o usuário realiza ações-chave
    Quando eventos ocorrem
    Então os seguintes eventos devem ser enviados com parâmetros:
      | evento                   | parâmetros obrigatórios                          |
      | login_success            | {method: "email"|"google", user_id}              |
      | medication_created       | {medication_id, has_photo, frequency_type}       |
      | medication_taken         | {medication_id, scheduled_ts, taken_ts, delay_s} |
      | notification_fired       | {medication_id, action: "received"|"dismissed"}  |
      | notification_action_taken| {medication_id, action: "take"|"skip"|"snooze"}|
      | sync_completed           | {created, updated, deleted, conflicts, duration_ms}|
      | report_shared            | {format: "pdf", channel: "whatsapp"|"email"|...} |

  Cenário: Custom traces Performance
    Dado que operações críticas executam
    Quando medimos
    Então traces custom devem ser iniciados/parados:
      | trace_name              | operação medida                              |
      | api_latency             | chamadas Dio/GraphQL (start/stop no interceptor) |
      | db_query_time           | queries Drift complexas (select/insert/update)   |
      | notification_schedule_time | agendamento batch de notificações (workmanager) |
```

### US-64: Acessibilidade WCAG 2.1 AA

```gherkin
Funcionalidade: Acessibilidade Total
  Como usuário com deficiência visual/motora
  Quero usar o app com leitor de tela e navegação por teclado/switch
  Para ter autonomia no meu tratamento

  Cenário: TalkBack/VoiceOver navega todas as telas
    Dado que TalkBack (Android) ou VoiceOver (iOS) está ativo
    Quando navego por swipe/direcional em cada tela
    Então todos os elementos interativos devem:
      | requisito                    | validação                                    |
      | semantic_label presente      | `Semantics(label: "...")` em 100% botões/inputs |
      | semantic_hint em ações       | "Toque duas vezes para ativar" onde não óbvio |
      | reading_order lógico         | top→bottom, left→right (semanticSortKey)     |
      | live_region para toasts      | `Semantics(liveRegion: true)` em SnackBars   |
      | touch_target ≥ 48dp          | `ConstrainedBox(minWidth: 48, minHeight: 48)` |

  Cenário: Contraste e escalonamento de fonte
    Dado que o usuário define "Tamanho da fonte: Grande" no SO
    Quando abro qualquer tela
    Então textos devem escalar (MediaQuery.textScaler)
    E contraste texto/fundo ≥ 4.5:1 (WCAG AA)
    E elementos decorativos não essenciais devem ser ignorados por leitor (excludeSemantics)

  Cenário: Navegação por teclado (Desktop/Web) e Switch Access
    Dado que uso Tab/Shift+Tab ou Switch Access
    Quando navego
    Então foco visível (focusColor + outline) em todos elementos
    E ordem de foco = ordem visual
    E `onTap`/`onPressed` também disparáveis via Enter/Space
```

---

## 5. Regras de Negócio (RN)

| ID | Regra | Descrição |
|----|-------|-----------|
| RN-01 | **Medicamento único por nome+dosagem+usuário** | Impedir duplicata exata (case-insensitive) no cadastro local. |
| RN-02 | **Frequência suportada** | Apenas: "A cada X horas" (1-24h), "Horários fixos", "Dias da semana", "Sob demanda (PRN)". |
| RN-03 | **Horários únicos por medicamento** | Não permitir horários duplicados no mesmo medicamento. |
| RN-04 | **Duração mínima** | 1 dia; máxima: 365 dias (renovável). PRN = duração indeterminada. |
| RN-05 | **Notificação antecedência** | Disparar exatamente no horário (não antes). Snooze = +15min (máx 3x por dose). |
| RN-06 | **Adesão: dose tomada** | Registrar `taken_at` (timestamp real) + `scheduled_at` (horário programado). Delay = taken_at - scheduled_at. |
| RN-07 | **Adesão: dose pulada** | Registrar `skipped_at` + motivo opcional. Conta como não-aderido no %. |
| RN-08 | **Adesão: dose perdida (missed)** | Se notificação disparou e nenhuma action em 2h → auto-registrar "missed". |
| RN-09 | **Sync: outbox FIFO** | Operações processadas na ordem de criação (timestamp local). |
| RN-10 | **Sync: retry exponencial** | 1min, 2min, 4min, 8min, 16min, 32min (max 1h). Após max retries → status "failed" + notificação ao usuário. |
| RN-11 | **Conflito: server-wins em campos críticos** | Dosagem, frequência, horários, duração → server-wins. Observação, foto → merge (last-write-wins). |
| RN-12 | **Exclusão lógica (soft delete)** | Arquivar = `deleted_at` setado. Hard delete apenas via LGPD (exclusão de conta). |
| RN-13 | **LGPD: direito ao esquecimento** | Exclusão de conta → apagar Drift local + revogar tokens Firebase + solicitar delete no backend (se houver). |
| RN-14 | **Permissões: rationale obrigatório** | Nunca pedir permissão direta sem tela explicando *por que* (notificações, exact alarms, battery). |
| RN-15 | **Offline-first: UI nunca bloqueia por rede** | Todas operações CRUD são otimistas (local first). Erro de rede só aparece em toast não-bloqueante. |

---

## 6. Restrições Técnicas (RT)

| ID | Restrição | Justificativa |
|----|-----------|---------------|
| RT-01 | **Flutter 3.24+ (stable), Dart 3.5+** | Recursos modernos (macros, pattern matching). |
| RT-02 | **Android minSdk 24, targetSdk 34** | Exact alarms + workmanager + foreground service types exigem API 24+. |
| RT-03 | **iOS 15+ deployment target** | `UNUserNotificationCenter` + background tasks + Swift concurrency. |
| RT-04 | **Drift (SQLite) como único armazenamento local** | Type-safe, migrações, streams reativas, offline-first nativo. Sem SharedPreferences para dados de domínio. |
| RT-05 | **Dio 5+ com interceptors obrigatórios** | Auth (Bearer + refresh), Retry (exponential backoff + jitter), Logging (pretty), Cache (ETag/If-None-Match). |
| RT-06 | **GraphQL apenas na feature "Busca de Medicamentos"** | Demonstrar codegen + cache normalizado sem over-engineering. |
| RT-07 | **Firebase: Auth + Crashlytics + Analytics + Performance** | Projeto Firebase real (ou Emulator) — não mockar observabilidade. |
| RT-08 | **Fastlane + Match (iOS) obrigatório no CI** | Build .ipa em macOS runner exige certificados gerenciados. |
| RT-09 | **GitHub Actions: ubuntu-latest (analyze/test/build-android) + macos-latest (build-ios)** | Custo/benefício; iOS só builda em macOS. |
| RT-10 | **flutter_flavorizr para 3 flavors** | Configuração limpa; evita gambiarras de `--dart-define`. |
| RT-11 | **Commits semânticos (Conventional Commits) + commitlint + husky (local)** | Histórico legível; CHANGELOG automático futuro. |
| RT-12 | **Zero `flutter analyze` warnings/errors em CI** | Qualidade inegociável. |
| RT-13 | **Cobertura mínima 85% (linhas) / 80% (branches)** | Métrica objetiva de qualidade. |
| RT-14 | **Tamanho APK release < 25MB (arm64)** | Performance e distribuição. |
| RT-15 | **Cold start < 1s (profile mode, dispositivo médio)** | UX + métrica observabilidade. |

---

## 7. Riscos e Dependências

| ID | Risco/Dependência | Probabilidade | Impacto | Mitigação |
|----|-------------------|---------------|---------|-----------|
| RSK-01 | **Fastlane iOS build falha no GitHub Actions (certificados, provisioning, Xcode version)** | Alta | Alto | Usar `match` com `readonly: true`; testar local antes; ter `macos-latest` runner; documentar troubleshooting no README. |
| RSK-02 | **Codegen (freezed, injectable, graphql, drift) quebra com versões incompatíveis** | Média | Alto | Fixar versões no `pubspec.yaml`; `dart run build_runner build --delete-conflicting-outputs` no CI; testar upgrade isolado. |
| RSK-03 | **Exact alarms negados pelo usuário (Android 14+)** | Média | Alto | Rationale claro no onboarding; fallback para `setAlarmClock` + workmanager; toast explicando impacto se negado. |
| RSK-04 | **Workmanager não executa no horário exato (doze, battery saver, OEM restrictions)** | Alta | Médio | `flutter_local_notifications` com `AndroidNotificationDetails.fullScreenIntent` + `priority: high`; `setExactAndAllowWhileIdle`; testar em dispositivos físicos Samsung/Xiaomi. |
| RSK-05 | **GraphQL codegen gera tipos quebrados se schema mudar** | Baixa | Médio | Schema versionado no repo (`graphql_schema.json`); `graphql_codegen` no CI; testes de integração validam tipos. |
| RSK-06 | **Firebase Emulator instável no CI (portas, Java version)** | Média | Médio | Usar Firebase projeto real no CI (gratuito); Emulator apenas local. Configurar `FIREBASE_TOKEN` secret. |
| RSK-07 | **Drift migrações complexas se schema mudar durante desenvolvimento** | Baixa | Alto | Planejar schema v1 completo; usar `Migrator` versionado; testar migração v1→v2 local. |
| RSK-08 | **Testes de integração flaky (timing, rede, notificações)** | Alta | Médio | Mockar tempo (`clock` package); usar `integration_test` com `patrol` opcional; retries no CI; isolar testes E2E. |
| RSK-09 | **Design System inconsistente (tokens não usados, hardcoded colors)** | Média | Baixo | Lint custom `prefer_theme_extensions`; revisão de PR obrigatória; storybook/widgetbook para validação visual. |
| RSK-10 | **Escopo creep: adicionar features além do MVP** | Alta | Alto | **Congelar escopo no Day 1**; backlog "Won't" explícito; revisão diária de 15min (daily pessoal). |

---

## 8. Fora do Escopo (Won't - MVP)

- Autenticação Apple / Sign in with Apple (apenas Google + Email)
- Multi-idioma (i18n) — apenas pt-BR
- Compartilhamento entre cuidadores / família
- Backup/restore Google Drive / iCloud
- Modo "família" (múltiplos perfis)
- Gamificação (badges, streaks visuais além do dashboard)
- Widgets homescreen / complications WearOS
- Testes de carga / stress / monkey testing
- Publicação Play Store / App Store (apenas build artifacts)
- Backend real (API própria) — usar Firebase Functions mock ou JSON estático
- Push notifications (FCM) — apenas locais
- Biometria (face/fingerprint) para unlock app
- Tema customizado pelo usuário (apenas light/dark system)

---

## 9. Métricas de Sucesso (Exit Criteria MVP)

| Métrica | Target | Como Medir |
|---------|--------|------------|
| **Cobertura testes (unit+widget)** | ≥ 85% linhas / ≥ 80% branches | `flutter test --coverage` + `lcov` |
| **flutter analyze** | 0 warnings, 0 errors | GitHub Actions job `analyze` |
| **Build Android (.aab) release** | Sucesso + artifact upload | GitHub Actions `build-android` |
| **Build iOS (.ipa) release** | Sucesso + artifact upload | GitHub Actions `build-ios` (macos-latest) |
| **Crash-free users (simulado)** | 100% (0 crashes em integration tests) | Firebase Crashlytics dashboard |
| **Cold start (profile, device médio)** | < 1000ms | `flutter run --profile` + `dart:developer` Timeline |
| **Frame raster (lista 100 itens)** | < 16ms (60fps) | DevTools Performance overlay |
| **Acessibilidade (axe/accessibility_tools)** | 0 violations WCAG 2.1 AA | `flutter_test` + `semantics_debugger` + teste manual TalkBack |
| **Tamanho APK (arm64 release)** | < 25 MB | `flutter build apk --release --target-platform android-arm64` |
| **ADRs documentados** | ≥ 8 decisões arquiteturais | `docs/adr/*.md` count |
| **Commits semânticos** | 100% (feat/fix/test/ci/refactor/docs/chore) | `commitlint` no CI |
| **README profissional** | Completo (badges, arquitetura, como rodar, stack, roadmap) | Checklist manual |