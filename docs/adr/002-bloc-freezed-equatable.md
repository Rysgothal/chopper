# ADR 002: Gerenciamento de Estado — BLoC + Freezed + Equatable

**Status:** Accepted  
**Data:** 2026-10-07  
**Autor:** Lucas Souza Frade

---

## Contexto

Precisamos de gerenciamento de estado que seja:
- Previsível e testável (unit tests de lógica de UI sem widget tree)
- Imutável (evita bugs de mutação acidental de estado)
- Padrão no mercado enterprise brasileiro (iFood, Nubank, Mercado Livre usam BLoC)
- Com tooling forte (Bloc Observer, blocTest, DevTools integration)

---

## Decisão

### Stack de Estado
| Camada | Tecnologia | Papel |
|--------|------------|-------|
| **Presentation** | `flutter_bloc` (Bloc/Cubit) | Gerenciar estado de UI, eventos do usuário, side effects |
| **Domain/Entities** | `equatable` | Value equality para Entities (domain) |
| **Data/Models + Presentation/States** | `freezed` | Sealed classes, copyWith, toString, equality, pattern matching, codegen |

### Padrões Obrigatórios
1. **Events/States com Freezed** — sealed classes + `when`/`map` exhaustiveness checking
2. **Bloc por feature/tela** — `AuthBloc`, `MedicationBloc`, `NotificationBloc`, `SyncBloc`, `AdherenceBloc`
3. **Cubit para estado simples** — ex: `ThemeCubit`, `OnboardingCubit` (sem events complexos)
4. **Exhaustiveness checking** — `state.when(...)` ou `state.map(...)` em todos handlers; CI falha se missing case
5. **BlocObserver global** — logging de transições, errors, performance traces

### Exemplo de Estrutura (Auth)
```dart
// domain/entities/user.dart (Equatable)
class User extends Equatable {
  final String uid;
  final String email;
  const User({required this.uid, required this.email});
  @override List<Object?> get props => [uid, email];
}

// presentation/bloc/auth_event.dart (Freezed)
@freezed
abstract class AuthEvent with _$AuthEvent {
  const factory AuthEvent.signInEmail({required String email, required String password}) = _SignInEmail;
  const factory AuthEvent.signInGoogle() = _SignInGoogle;
  const factory AuthEvent.signOut() = _SignOut;
  const factory AuthEvent.deleteAccount() = _DeleteAccount;
  const factory AuthEvent.authStateChanged({User? user}) = _AuthStateChanged;
}

// presentation/bloc/auth_state.dart (Freezed)
@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated({required User user}) = _Authenticated;
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.error({required String message}) = _Error;
}
```

---

## Consequências

### Positivas
- ✅ Estados imutáveis → zero bugs de "estado mutou sem emitir"
- ✅ `blocTest` nativo: `blocTest<AuthBloc, AuthState>('sign in success', build: ..., act: ..., expect: [...])`
- ✅ Mocks fáceis: `when(() => mockAuthRepository.signInEmail(...)).thenAnswer((_) async => Right(user))`
- ✅ Codegen: `dart run build_runner build` gera `.freezed.dart` + `.g.dart`
- ✅ BlocObserver: log unificado de todas transições para Crashlytics/Analytics

### Negativas/Riscos
- ⚠️ Verbosidade inicial (Event + State + Bloc por feature)
- ⚠️ Curva Freezed (sealed classes, `when`, `map`, `maybeWhen`)

### Mitigações
- Snippets VS Code: `bloc`, `freezed-event`, `freezed-state`, `bloc-test`
- Documentação interna com exemplos reais do projeto

---

## Alternativas Consideradas

| Alternativa | Prós | Contras | Por que não |
|-------------|------|---------|-------------|
| **Riverpod + Freezed** | Menos boilerplate; DI built-in; reatividade automática | Menos padrão enterprise (iFood usa BLoC); acopla Presentation ao ProviderContainer; migração futura difícil | Vaga pede "Clean Code & Design Pattern" — BLoC força separação Event/State explícita |
| **Cubit + Classes Manuais** | Controle total; menos mágica | Boilerplate alto (copyWith, ==, hashCode, toString); propenso a erros; sem exhaustiveness checking | Freezed elimina boilerplate com codegen seguro |

---

## Referências
- [Bloc Library Docs](https://bloclibrary.dev/)
- [Freezed Docs](https://pub.dev/packages/freezed)
- [Equatable Docs](https://pub.dev/packages/equatable)
- [Bloc Testing](https://bloclibrary.dev/#/testing)