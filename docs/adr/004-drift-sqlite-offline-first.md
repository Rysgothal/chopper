# ADR 004: Persistência Local — Drift (SQLite) Offline-First

**Status:** Accepted  
**Data:** 2026-10-07  
**Autor:** Lucas Souza Frade

---

## Contexto

Offline-first é requisito não-negociável do app. Precisamos:
- Type-safety (erros de SQL em compile-time, não runtime)
- Migrações versionadas e testáveis
- Streams reativas (query → `Stream<List<T>>` para UI reativa)
- Transações, upsert, foreign keys, triggers
- Outbox pattern nativo para sync bidirecional

---

## Decisão

### Stack
| Package | Versão | Papel |
|---------|--------|-------|
| `drift` | ^2.18+ | ORM type-safe sobre SQLite |
| `sqlite3_flutter_libs` | ^0.5+ | SQLite bundled (versão consistente cross-platform) |
| `drift_dev` | ^2.18+ | Codegen (DAOs, Migrator) |

### Estrutura
```
lib/
├── core/
│   └── database/
│       ├── app_database.dart          # Database class + Migrator
│       ├── tables/
│       │   ├── users.dart
│       │   ├── medications.dart
│       │   ├── doses.dart
│       │   └── sync_queue.dart        # Outbox pattern
│       ├── daos/
│       │   ├── user_dao.dart
│       │   ├── medication_dao.dart
│       │   ├── dose_dao.dart
│       │   └── sync_queue_dao.dart
│       └── mappers/                   # TableRow → Entity (Domain)
└── features/.../data/datasources/     # LocalDataSource usa DAOs
```

### Schema v1 (Principais Tabelas)

```dart
// tables/medications.dart
@Table(name: 'medications')
class Medications extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text().nullable()(); // ID do backend
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get dosage => text().withLength(min: 1, max: 50)();
  TextColumn get form => text()(); // Comprimido, Líquido, etc.
  TextColumn get frequencyType => text()(); // fixed_times, interval, weekly, prn
  TextColumn get frequencyConfig => text()(); // JSON: horários, dias, intervalo
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get photoPath => text().nullable()();
  IntColumn get version => integer().withDefault(Constant(1))(); // Optimistic locking
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // Soft delete
  IntColumn get userId => integer().references(Users, #id)();
}

// tables/sync_queue.dart (Outbox Pattern)
@Table(name: 'sync_queue')
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operation => text().withLength(min: 1, max: 20)(); // create, update, delete, archive
  TextColumn get entityType => text().withLength(min: 1, max: 50)(); // medication, dose
  IntColumn get entityId => integer()(); // Local ID
  TextColumn get serverId => text().nullable()(); // Server ID (se create)
  TextColumn get payload => text().map(const JsonEncoder())(); // JSON completo da operação
  TextColumn get status => text().withLength(min: 1, max: 20).withDefault(Constant('pending'))(); // pending, processing, synced, failed, conflict
  IntColumn get retryCount => integer().withDefault(Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
}
```

### DAO com Streams Reativas
```dart
// daos/medication_dao.dart
@DriftAccessor(tables: [Medications, Doses])
class MedicationDao extends DatabaseAccessor<AppDatabase> with _$MedicationDaoMixin {
  MedicationDao(super.db);

  // Stream reativa: UI atualiza automaticamente quando dados mudam
  Stream<List<Medication>> watchActiveMedications(int userId) {
    return (select(medications)
          ..where((m) => m.userId.equals(userId) & m.deletedAt.isNull())
          ..orderBy([(m) => OrderingTerm.asc(m.name)]))
        .watch()
        .map((rows) => rows.map((r) => r.toEntity()).toList());
  }

  // Insert com retorno do ID
  Future<int> insertMedication(MedicationsCompanion entry) => into(medications).insert(entry);

  // Update otimista (version++)
  Future<bool> updateMedication(Medication entity) {
    return update(medications).replace(
      MedicationsCompanion(
        id: Value(entity.id),
        name: Value(entity.name),
        // ... outros campos
        version: Value(entity.version + 1),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // Soft delete
  Future<int> archiveMedication(int id) => (update(medications)..where((m) => m.id.equals(id)))
    .write(MedicationsCompanion(deletedAt: Value(DateTime.now()), updatedAt: Value(DateTime.now())));
}
```

### Migrações
```dart
// app_database.dart
@DriftDatabase(tables: [Users, Medications, Doses, SyncQueue], daos: [UserDao, MedicationDao, DoseDao, SyncQueueDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) => m.createAll(),
    onUpgrade: (Migrator m, int from, int to) async {
      // v1 → v2: adicionar coluna, índice, etc.
      // await m.addColumn(medications, medications.newColumn);
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
```

---

## Consequências

### Positivas
- ✅ Type-safe SQL → erros em compile-time (coluna não existe, tipo errado)
- ✅ Streams reativas → `watch*()` no DAO → `StreamBuilder`/`Bloc` atualiza UI automaticamente
- ✅ Offline-first nativo: escrita local imediata (`insert`/`update`/`delete`), sync assíncrona via outbox
- ✅ Migrações versionadas → `onUpgrade` testável local (v1→v2)
- ✅ Transações ACID → `transaction(() async { ... })` para operações atômicas

### Negativas/Riscos
- ⚠️ Schema changes exigem migração cuidadosa (`onUpgrade`)
- ⚠️ Codegen (`build_runner`) necessário para DAOs/Table classes

### Mitigações
- Planejar schema v1 completo (antecipar campos: `serverId`, `version`, `deletedAt`, `sync_queue`)
- Testar migração v1→v2 local antes de commit
- `drift_dev` no `dev_dependencies` para codegen

---

## Alternativas Consideradas

| Alternativa | Prós | Contras | Por que não |
|-------------|------|---------|-------------|
| **Floor (Room-like)** | Anotações similares Room/Android; migrações | Menos maduro no Flutter; community menor; codegen menos flexível | Drift é padrão Flutter (ex-Moor), mantido por simonbinder |
| **Isar** | NoSQL rápido; ACID; Dart nativo | Não relacional; migrações menos previsíveis; queries complexas limitadas | Precisamos SQL relacional (joins, foreign keys, transações) |
| **SharedPreferences + JSON** | Simples para chave-valor | Inadequado para queries, relacionamentos, concorrência, streams | Dados de domínio = relacional, não key-value |
| **Hive** | Rápido, simples | NoSQL; sem migrações versionadas; sem streams reativas nativas | Mesmo problema do Isar |

---

## Referências
- [Drift Docs](https://drift.simonbinder.eu/)
- [Drift Migration Guide](https://drift.simonbinder.eu/docs/advanced-features/migrations/)
- [Outbox Pattern](https://microservices.io/patterns/data/transactional-outbox.html)