# ADR 013: Testes — Pirâmide (Unit > Widget > Integration) + Cobertura Mínima

**Status:** Accepted  
**Data:** 2026-10-07  
**Autor:** Lucas Souza Frade

---

## Contexto

iFood pede "testes automatizados". Pirâmide clássica: muitos unit (rápidos, isolados), alguns widget (UI logic), poucos integration (E2E, lentos). Cobertura mínima objetiva para entrevista ("cobertura 87%").

---

## Decisão

### Estratégia de Testes

| Camada | Ferramentas | Target | Foco |
|--------|-------------|--------|------|
| **Unit (Domain/Data)** | `flutter_test` + `mocktail` | **>85% linhas, >80% branches** | UseCases, Repositories, Blocs, Mappers, Services, DAOs |
| **Widget (Presentation)** | `flutter_test` + `pumpWidget` | Telas críticas 100% | Render, interações, estados (loading/error/success), **semântica (find.bySemanticsLabel)** |
| **Integration (E2E)** | `integration_test` + `patrol` (opcional) | Fluxo crítico 1 | Login → Criar med → Notificação → Action → Sync → Relatório → Logout |
| **Static** | `flutter analyze` (strict) + `dart format` | 0 warnings/errors | Qualidade de código |

### 1. Unit Tests (Domain/Data)

```dart
// test/features/medication/domain/usecases/create_medication_usecase_test.dart
void main() {
  late CreateMedicationUseCase useCase;
  late MockMedicationRepository mockRepository;

  setUp(() {
    mockRepository = MockMedicationRepository();
    useCase = CreateMedicationUseCase(mockRepository);
  });

  group('CreateMedicationUseCase', () {
    const tMedication = Medication(
      id: 1, name: 'Dipirona', dosage: '500mg', form: 'Comprimido',
      frequencyType: 'interval', frequencyConfig: '{"intervalHours": 8}',
      schedules: [MedicationSchedule(index: 0, time: '08:00'), MedicationSchedule(index: 1, time: '16:00'), MedicationSchedule(index: 2, time: '00:00')],
      startDate: '2024-01-01', endDate: '2024-01-08', userId: 1,
    );

    test('deve chamar repository.create e retornar Right(medication)', () async {
      when(() => mockRepository.create(any())).thenAnswer((_) async => const Right(tMedication));

      final result = await useCase(CreateMedicationParams(medication: tMedication));

      expect(result, const Right(tMedication));
      verify(() => mockRepository.create(tMedication)).called(1);
    });

    test('deve retornar Left(ValidationFailure) quando nome vazio', () async {
      final invalidMed = tMedication.copyWith(name: '');
      final result = await useCase(CreateMedicationParams(medication: invalidMed));
      expect(result, isA<Left<Failure, Medication>>());
      verifyNever(() => mockRepository.create(any()));
    });

    test('deve retornar Left(ServerFailure) quando repository falha', () async {
      when(() => mockRepository.create(any())).thenAnswer((_) async => Left(ServerFailure('DB error')));
      final result = await useCase(CreateMedicationParams(medication: tMedication));
      expect(result, isA<Left<Failure, Medication>>());
    });
  });
}
```

```dart
// test/features/medication/data/repositories/medication_repository_impl_test.dart
void main() {
  late MedicationRepositoryImpl repository;
  late MockMedicationLocalDataSource mockLocalDataSource;
  late MockSyncQueueDao mockSyncQueueDao;

  setUp(() {
    mockLocalDataSource = MockMedicationLocalDataSource();
    mockSyncQueueDao = MockSyncQueueDao();
    repository = MedicationRepositoryImpl(mockLocalDataSource, mockSyncQueueDao);
  });

  group('MedicationRepositoryImpl', () {
    test('create: salva no local + adiciona outbox entry + retorna medication com id', () async {
      final medication = Medication(id: 0, name: 'Test', ...);
      final savedMed = medication.copyWith(id: 42);
      when(() => mockLocalDataSource.insertMedication(any())).thenAnswer((_) async => 42);
      when(() => mockSyncQueueDao.insertOutboxEntry(any())).thenAnswer((_) async => 1);

      final result = await repository.create(medication);

      expect(result, Right(savedMed));
      verify(() => mockLocalDataSource.insertMedication(argThat(predicate<MedicationsCompanion>((c) => c.name.value == 'Test')))).called(1);
      verify(() => mockSyncQueueDao.insertOutboxEntry(argThat(predicate<SyncQueueCompanion>((c) => c.operation.value == 'create')))).called(1);
    });
  });
}
```

### 2. Bloc Tests (Presentation)

```dart
// test/features/medication/presentation/blocs/medication_bloc_test.dart
void main() {
  late MedicationBloc bloc;
  late MockGetMedicationsUseCase mockGetMedications;
  late MockCreateMedicationUseCase mockCreateMedication;
  late MockDeleteMedicationUseCase mockDeleteMedication;

  setUp(() {
    mockGetMedications = MockGetMedicationsUseCase();
    mockCreateMedication = MockCreateMedicationUseCase();
    mockDeleteMedication = MockDeleteMedicationUseCase();
    bloc = MedicationBloc(
      getMedications: mockGetMedications,
      createMedication: mockCreateMedication,
      deleteMedication: mockDeleteMedication,
    );
  });

  tearDown(() => bloc.close());

  blocTest<MedicationBloc, MedicationState>(
    'emite [Loading, Loaded] quando GetMedications dispara e retorna lista',
    build: () {
      when(() => mockGetMedications(any())).thenAnswer((_) async => Right([tMedication1, tMedication2]));
      return bloc;
    },
    act: (bloc) => bloc.add(const MedicationEvent.getMedications()),
    expect: () => [
      const MedicationState.loading(),
      MedicationState.loaded([tMedication1, tMedication2]),
    ],
    verify: (_) => verify(() => mockGetMedications(const GetMedicationsParams(userId: 1))).called(1),
  );

  blocTest<MedicationBloc, MedicationState>(
    'emite [Loading, Error] quando CreateMedication falha',
    build: () {
      when(() => mockCreateMedication(any())).thenAnswer((_) async => Left(ServerFailure('Network error')));
      return bloc;
    },
    act: (bloc) => bloc.add(MedicationEvent.createMedication(medication: tNewMedication)),
    expect: () => [
      const MedicationState.loading(),
      const MedicationState.error('Network error'),
    ],
  );
}
```

### 3. Widget Tests (Semântica + A11y)

```dart
// test/features/medication/presentation/pages/medication_list_page_test.dart
void main() {
  late MockMedicationBloc mockBloc;

  setUp(() {
    mockBloc = MockMedicationBloc();
    when(() => mockBloc.state).thenReturn(const MedicationState.loaded([]));
    when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockBloc.add(any())).thenAnswer((_) {});
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('pt', 'BR')],
      home: BlocProvider<MedicationBloc>.value(
        value: mockBloc,
        child: const MedicationListPage(),
      ),
    );
  }

  testWidgets('renderiza estado vazio com CTA acessível', (tester) async {
    when(() => mockBloc.state).thenReturn(const MedicationState.empty());
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.bySemanticsLabel('Lista de medicamentos vazia'), findsOneWidget);
    expect(find.bySemanticsLabel('Cadastrar primeiro medicamento'), findsOneWidget);
    expect(find.byType(AppButton), findsOneWidget);
  });

  testWidgets('lista medicamentos com semântica correta', (tester) async {
    when(() => mockBloc.state).thenReturn(MedicationState.loaded([tMedication1, tMedication2]));
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.bySemanticsLabel('Dipirona 500mg - Comprimido'), findsOneWidget);
    expect(find.bySemanticsLabel('Losartana 50mg - Comprimido'), findsOneWidget);
    // Verifica touch targets
    final buttons = find.byWidgetPredicate((w) => w is InkWell || w is IconButton);
    for (final button in buttons.evaluate()) {
      final renderBox = button.renderObject as RenderBox?;
      expect(renderBox?.size.width, greaterThanOrEqualTo(48));
      expect(renderBox?.size.height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('navega para form ao tocar FAB', (tester) async {
    when(() => mockBloc.state).thenReturn(const MedicationState.loaded([]));
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.bySemanticsLabel('Adicionar medicamento'));
    await tester.pumpAndSettle();
    verify(() => mockBloc.add(const MedicationEvent.navigateToForm())).called(1);
  });
}
```

### 4. Integration Test (E2E)

```dart
// integration_test/app_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Fluxo Crítico E2E', () {
    testWidgets('login → criar med → notificação → action → sync → logout', (tester) async {
      app.main(); // main.dart com flavor dev
      await tester.pumpAndSettle();

      // 1. Login
      await tester.enterText(find.bySemanticsLabel('Email'), 'test@test.com');
      await tester.enterText(find.bySemanticsLabel('Senha'), '123456');
      await tester.tap(find.bySemanticsLabel('Entrar'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.bySemanticsLabel('Home'), findsOneWidget);

      // 2. Criar medicamento
      await tester.tap(find.bySemanticsLabel('Adicionar medicamento'));
      await tester.pumpAndSettle();
      await tester.enterText(find.bySemanticsLabel('Nome'), 'Losartana');
      await tester.enterText(find.bySemanticsLabel('Dosagem'), '50mg');
      // ... preencher horários, frequência
      await tester.tap(find.bySemanticsLabel('Salvar'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Losartana 50mg'), findsOneWidget);

      // 3. Simular notificação (mock time) + action "Tomar"
      // Usar `clock` package para controlar DateTime.now()
      // await tester.tap(find.bySemanticsLabel('Tomar')); // Na notificação mockada

      // 4. Verificar histórico atualizado
      await tester.tap(find.bySemanticsLabel('Losartana 50mg'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Tomada às'), findsOneWidget);

      // 5. Sync (mock network)
      await tester.tap(find.bySemanticsLabel('Sincronizar agora'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Sincronizado'), findsOneWidget);

      // 6. Relatório PDF → share sheet
      await tester.tap(find.bySemanticsLabel('Gerar relatório'));
      await tester.pumpAndSettle();
      // Share sheet abre (não testável headless, mas não crasha)

      // 7. Logout
      await tester.tap(find.bySemanticsLabel('Sair'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Entrar'), findsOneWidget);
    });
  }
}
```

### 5. Configuração Cobertura + CI

```yaml
# .github/workflows/ci.yml (trecho)
- name: Run Tests with Coverage
  run: flutter test --coverage --coverage-path=coverage/lcov.info

- name: Check Coverage Thresholds
  run: |
    # Requer lcov instalado
    genhtml coverage/lcov.info -o coverage/html
    LINES=$(lcov --summary coverage/lcov.info 2>&1 | grep 'lines' | sed 's/.*: \([0-9.]*\)%.*/\1/')
    BRANCHES=$(lcov --summary coverage/lcov.info 2>&1 | grep 'branches' | sed 's/.*: \([0-9.]*\)%.*/\1/')
    echo "Lines: $LINES%, Branches: $BRANCHES%"
    if (( $(echo "$LINES < 85" | bc -l) )); then exit 1; fi
    if (( $(echo "$BRANCHES < 80" | bc -l) )); then exit 1; fi
```

### 6. Mutation Testing (Opcional - Qualidade dos Asserts)
```bash
# dart_mutation_testing
dart pub global activate dart_mutation_testing
dart_mutation_testing --exclude="**/*.g.dart,**/*.freezed.dart" --threshold=80
```

---

## Consequências

### Positivas
- ✅ Confiança para refatorar: regressões pegas no CI
- ✅ Métrica objetiva para entrevista: "Cobertura 87% linhas, 82% branches"
- ✅ Testes de semântica garantem a11y não regressa
- ✅ Integration test valida fluxo real (device/emulator)

### Negativas/Riscos
- ⚠️ Tempo CI aumenta (mitigado: cache `pub`, sharding unit tests)
- ⚠️ Integration tests flaky (mitigado: mock tempo/rede, `patrol` opcional)

### Mitigações
- `actions/cache` para `.pub-cache` + `build`
- Unit tests shard: `flutter test --shard-index=0 --shard-count=4`
- `clock` package para controlar `DateTime.now()` em testes

---

## Alternativas Consideradas

| Alternativa | Prós | Contras | Por que não |
|-------------|------|---------|-------------|
| **Só unit tests** | Rápido; barato | Não pega bugs de UI/integração; sem semântica a11y | iFood espera testes de UI |
| **Só integration tests** | Testa fluxo real | Lento; flaky; difícil debugar; não isola lógica | Pirâmide invertida = anti-pattern |

---

## Referências
- [Flutter Testing](https://docs.flutter.dev/testing)
- [Bloc Testing](https://bloclibrary.dev/#/testing)
- [Mocktail](https://pub.dev/packages/mocktail)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Mutation Testing](https://pub.dev/packages/dart_mutation_testing)