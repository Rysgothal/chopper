# ADR 001: Clean Architecture Feature-First

**Status:** Accepted  
**Data:** 2026-10-07  
**Autor:** Lucas Souza Frade

---

## Contexto

Precisamos isolar regras de negócio de frameworks (Flutter, Firebase, Drift) para:
- Testabilidade (unit tests rápidos, sem `flutter_test` no Domain)
- Trocabilidade de implementação (REST↔GraphQL, Drift↔Hive sem tocar UI)
- Clareza de domínio e onboarding de novos devs
- Alinhamento com expectativa iFood (arquitetura limpa, separação de responsabilidades)

---

## Decisão

Adotar **Clean Architecture feature-first** com a seguinte estrutura:

```
lib/
├── core/
│   ├── config/           # Environment, Theme, Router, DI
│   ├── errors/           # Failures, Exceptions
│   ├── utils/            # Extensions, Constants, Helpers
│   └── widgets/          # Design System (tokens, componentes base)
├── features/
│   ├── auth/
│   │   ├── data/         # DataSources, RepositoryImpl, Models
│   │   ├── domain/       # Entities, Repository Contracts, UseCases
│   │   └── presentation/ # Blocs, Pages, Widgets
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
├── injection.dart        # GetIt setup (gerado pelo Injectable)
└── main.dart             # Entry point + flavor config
```

**Regras de dependência:**
- **Domain:** Zero dependências Flutter/packages externos. Apenas Dart core + `equatable` + `dartz`/`fpdart` (Either).
- **Data:** Depende de Domain + packages (Dio, Drift, Firebase, GraphQL, Freezed, JsonSerializable).
- **Presentation:** Depende de Domain + core + Flutter packages (flutter_bloc, go_router, etc.).
- **Core:** Compartilhado por features; sem dependência de features.

---

## Consequências

### Positivas
- ✅ Domain puro = unit tests rápidos (ms), sem device/emulator
- ✅ Troca REST↔GraphQL, Drift↔Hive, Firebase↔Mock sem tocar UI
- ✅ Estrutura previsível: novo dev sabe onde procurar/colocar código
- ✅ Escalabilidade: features isoladas, baixo acoplamento

### Negativas/Riscos
- ⚠️ Boilerplate inicial (pastas, arquivos de contrato, mappers)
- ⚠️ Curva de aprendizado para devs acostumados com MVVM simples

### Mitigações
- Codegen resolve 80% do boilerplate: `freezed` (models/states), `injectable` (DI), `drift` (DAOs), `graphql_codegen` (GraphQL), `json_serializable` (DTOs)
- Templates/snippets no VS Code para UseCase, Repository, Bloc

---

## Alternativas Consideradas

| Alternativa | Prós | Contras | Por que não |
|-------------|------|---------|-------------|
| **MVVM + Riverpod/Provider** | Menos boilerplate; reatividade simples | Acoplamento maior; difícil trocar data sources; menos padrão enterprise | iFood usa BLoC + Clean Arch; Riverpod acopla Presentation ao container |
| **Clean Architecture layer-first** (data/domain/presentation na raiz) | Familiar para alguns times | Menos coesão por feature; imports cruzados entre features; escalabilidade menor | Feature-first é padrão Google/Flutter team para apps grandes |

---

## Referências
- [Clean Architecture (Uncle Bob)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter Architecture Guide](https://docs.flutter.dev/app-architecture/guide)
- [Feature-first vs Layer-first](https://verygood.ventures/blog/feature-first-vs-layer-first)