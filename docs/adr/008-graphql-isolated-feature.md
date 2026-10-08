# ADR 008: GraphQL em Feature Isolada (Busca de Medicamentos)

**Status:** Accepted  
**Data:** 2026-10-07  
**Autor:** Lucas Souza Frade

---

## Contexto

Vaga pede "GraphQL" como diferencial. Não justifica GraphQL em todo app (overhead de schema, codegen, cache). Isolar em **1 feature** demonstra:
- Codegen (`graphql_codegen` + `build_runner`)
- Cache normalizado (Apollo-style type policies)
- Fallback offline (busca local no Drift se rede falhar)
- Comparação REST vs GraphQL na entrevista
- Domain contract compartilhado (swap transparente)

---

## Decisão

### Stack
| Package | Versão | Papel |
|---------|--------|-------|
| `graphql_flutter` | ^5.1+ | Client GraphQL (link, cache, queries/mutations) |
| `graphql_codegen` | ^3.0+ | Codegen tipos Dart a partir de schema + operations |
| `graphql` | ^5.1+ | Core types (DocumentNode, etc.) |

### Estrutura (Feature Isolada)
```
features/medication_search/
├── data/
│   ├── datasources/
│   │   ├── graphql_medication_search_data_source.dart
│   │   └── local_medication_search_data_source.dart  # Fallback Drift FTS5/LIKE
│   ├── repositories/
│   │   └── medication_search_repository_impl.dart
│   └── models/
│       ├── medication_search_query.graphql.dart      # GERADO
│       └── medication_search_query.req.g.dart        # GERADO
├── domain/
│   ├── entities/
│   │   └── medication_search_result.dart
│   ├── repositories/
│   │   └── medication_search_repository.dart         # Mesmo contract do REST
│   └── usecases/
│       └── search_medications_usecase.dart
└── presentation/
    ├── blocs/
    │   └── medication_search_bloc.dart
    └── widgets/
        └── medication_search_delegate.dart           # SearchDelegate custom
```

### Schema Versionado (Commit no Repo)
```json
// docs/graphql_schema.json
{
  "data": {
    "__schema": {
      "queryType": { "name": "Query" },
      "types": [
        {
          "name": "Query",
          "fields": [
            {
              "name": "searchMedications",
              "args": [
                { "name": "query", "type": { "kind": "NON_NULL", "ofType": { "kind": "SCALAR", "name": "String" } } },
                { "name": "limit", "type": { "kind": "SCALAR", "name": "Int" } },
                { "name": "offset", "type": { "kind": "SCALAR", "name": "Int" } }
              ],
              "type": { "kind": "OBJECT", "name": "MedicationSearchConnection" }
            }
          ]
        },
        {
          "name": "MedicationSearchConnection",
          "fields": [
            { "name": "edges", "type": { "kind": "LIST", "ofType": { "kind": "NON_NULL", "ofType": { "kind": "OBJECT", "name": "MedicationSearchEdge" } } } },
            { "name": "pageInfo", "type": { "kind": "NON_NULL", "ofType": { "kind": "OBJECT", "name": "PageInfo" } } },
            { "name": "totalCount", "type": { "kind": "NON_NULL", "ofType": { "kind": "SCALAR", "name": "Int" } } }
          ]
        },
        {
          "name": "MedicationSearchEdge",
          "fields": [
            { "name": "node", "type": { "kind": "NON_NULL", "ofType": { "kind": "OBJECT", "name": "Medication" } } },
            { "name": "cursor", "type": { "kind": "NON_NULL", "ofType": { "kind": "SCALAR", "name": "String" } } }
          ]
        },
        {
          "name": "Medication",
          "fields": [
            { "name": "id", "type": { "kind": "NON_NULL", "ofType": { "kind": "SCALAR", "name": "ID" } } },
            { "name": "name", "type": { "kind": "NON_NULL", "ofType": { "kind": "SCALAR", "name": "String" } } },
            { "name": "dosage", "type": { "kind": "NON_NULL", "ofType": { "kind": "SCALAR", "name": "String" } } },
            { "name": "form", "type": { "kind": "SCALAR", "name": "String" } },
            { "name": "genericName", "type": { "kind": "SCALAR", "name": "String" } },
            { "name": "manufacturer", "type": { "kind": "SCALAR", "name": "String" } }
          ]
        },
        {
          "name": "PageInfo",
          "fields": [
            { "name": "hasNextPage", "type": { "kind": "NON_NULL", "ofType": { "kind": "SCALAR", "name": "Boolean" } } },
            { "name": "endCursor", "type": { "kind": "SCALAR", "name": "String" } }
          ]
        }
      ]
    }
  }
}
```

### Query + Codegen
```graphql
# features/medication_search/data/queries/search_medications.graphql
query SearchMedications($query: String!, $limit: Int, $offset: Int) {
  searchMedications(query: $query, limit: $limit, offset: $offset) {
    totalCount
    edges {
      cursor
      node {
        id
        name
        dosage
        form
        genericName
        manufacturer
      }
    }
    pageInfo {
      hasNextPage
      endCursor
    }
  }
}
```

```yaml
# build.yaml (config codegen)
targets:
  $default:
    builders:
      graphql_codegen:build:
        options:
          schema_mapping:
            - schema: "docs/graphql_schema.json"
              queries_glob: "features/medication_search/data/queries/*.graphql"
              output_dir: "features/medication_search/data/models"
```

```bash
# Gera: medication_search_query.graphql.dart + .req.g.dart
dart run build_runner build --delete-conflicting-outputs
```

### Client GraphQL com Cache Normalizado
```dart
// core/network/graphql_client.dart
@singleton
class GraphQLClientProvider {
  final GraphQLClient _client;

  GraphQLClientProvider(EnvironmentConfig config) {
    final httpLink = HttpLink(config.graphqlEndpoint);
    final authLink = AuthLink(getToken: () async => _authRepository.getCurrentAccessToken() ?? '');
    final link = authLink.concat(httpLink);

    _client = GraphQLClient(
      link: link,
      cache: GraphQLCache(
        typePolicies: {
          'Medication': TypePolicy(keyFields: {'id': true}), // Normalizado por ID
          'Query': TypePolicy(fields: {
            'searchMedications': FieldPolicy(
              keyArgs: ['query'], // Cache por query string
              merge: (existing, incoming, {required readField}) {
                // Merge paginado: existing.edges + incoming.edges
                final existingEdges = existing?['edges'] as List? ?? [];
                final incomingEdges = incoming['edges'] as List;
                return {...incoming, 'edges': [...existingEdges, ...incomingEdges]};
              },
            ),
          }),
        },
      ),
    );
  }

  GraphQLClient get client => _client;
}
```

### DataSource com Fallback Offline
```dart
// data/datasources/graphql_medication_search_data_source.dart
class GraphQLMedicationSearchDataSourceImpl implements MedicationSearchDataSource {
  final GraphQLClient _client;
  final LocalMedicationSearchDataSource _localDataSource; // Drift FTS5/LIKE

  @override
  Future<List<MedicationSearchResult>> search(String query, {int limit = 20, int offset = 0}) async {
    final options = QueryOptions(
      document: searchMedicationsQueryDocument, // GERADO
      variables: {'query': query, 'limit': limit, 'offset': offset},
      fetchPolicy: FetchPolicy.cacheAndNetwork, // Cache first, then network
    );

    try {
      final result = await _client.query(options);
      if (result.hasException) throw result.exception!;
      
      final data = SearchMedicationsQuery$Query.fromJson(result.data!['searchMedications']);
      return data.edges.map((e) => e.node.toEntity()).toList();
    } catch (e) {
      // Fallback offline: busca local no Drift
      return _localDataSource.searchLocal(query, limit: limit, offset: offset);
    }
  }
}
```

### Domain Contract Compartilhado (Swap REST ↔ GraphQL)
```dart
// domain/repositories/medication_search_repository.dart
abstract class MedicationSearchRepository {
  Future<Either<Failure, List<MedicationSearchResult>>> search(
    String query, {
    int limit = 20,
    int offset = 0,
  });
}

// REST Implementation (existente)
class MedicationSearchRepositoryImpl implements MedicationSearchRepository {
  final RestMedicationSearchDataSource _dataSource;
  // ...
}

// GraphQL Implementation (nova - mesmo contract)
class GraphQLMedicationSearchRepositoryImpl implements MedicationSearchRepository {
  final GraphQLMedicationSearchDataSource _dataSource;
  // ...
}
```

---

## Consequências

### Positivas
- ✅ Demonstra GraphQL sem contaminar arquitetura (feature isolada)
- ✅ Codegen type-safe: schema → Dart types (zero runtime parsing errors)
- ✅ Cache normalizado: `Medication` por `id` → updates automáticos em listas
- ✅ Fallback offline transparente: rede falha → busca local Drift
- ✅ Swap REST ↔ GraphQL: mesma interface `MedicationSearchRepository`

### Negativas/Riscos
- ⚠️ Codegen adiciona step no CI (`dart run build_runner`)
- ⚠️ Schema versionado no repo (`docs/graphql_schema.json`) — se backend mudar, regenerar
- ⚠️ GraphQL endpoint mock necessário (Firebase Functions ou JSON estático)

### Mitigações
- Schema fixo no repo; `graphql_codegen` no CI valida tipos
- Mock endpoint: Firebase Functions simples retornando JSON estático ou `graphql_schema.json` introspecção
- Documentar no README: "GraphQL em feature isolada para demonstração; resto do app usa REST"

---

## Alternativas Consideradas

| Alternativa | Prós | Contras | Por que não |
|-------------|------|---------|-------------|
| **REST-only** | Simples; sem codegen | Perde diferencial pedido na vaga | iFood lista GraphQL como "diferencial" |
| **GraphQL full app (Apollo-like)** | Cache unificado, subscriptions | Overhead enorme; schema complexo; codegen em todo lugar | Não justifica para portfólio; REST + GraphQL híbrido é realista |
| **Apollo Client Dart** | Cache avançado, devtools | Não oficial; community menor; `graphql_flutter` é padrão Flutter | `graphql_flutter` mantido pela comunidade Flutter |

---

## Referências
- [graphql_flutter](https://pub.dev/packages/graphql_flutter)
- [graphql_codegen](https://pub.dev/packages/graphql_codegen)
- [GraphQL Cache Normalization](https://www.apollographql.com/docs/react/caching/cache-configuration/#type-policies)
- [Offline GraphQL](https://www.apollographql.com/docs/react/networking/offline-support/)