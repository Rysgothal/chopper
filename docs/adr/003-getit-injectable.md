# ADR 003: Injeção de Dependência — GetIt + Injectable (Codegen)

**Status:** Accepted  
**Data:** 2026-10-07  
**Autor:** Lucas Souza Frade

---

## Contexto

Precisamos de DI que seja:
- Compile-time (zero reflection, tree-shaking ok, startup rápido)
- Setup idêntico em produção e testes (mocks fáceis)
- Baixa manutenção (não espalhar `registerSingleton`/`registerFactory` pelo código)
- Padrão enterprise (Nubank, iFood usam GetIt + Injectable)

---

## Decisão

### Stack
| Package | Versão | Papel |
|---------|--------|-------|
| `get_it` | ^7.6+ | Service locator runtime |
| `injectable` | ^2.3+ | Anotações para geração |
| `injectable_generator` | ^2.4+ | Codegen do `configureDependencies()` |

### Padrão de Uso

```dart
// core/di/injection.dart (GERADO — não editar manualmente)
// ignore_for_file: unused_import
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'configureDependencies', // default
  preferRelativeImports: true,
  asExtension: false,
)
void configureDependencies({String? environment}) => $configureDependencies(getIt, environment: environment);
```

```dart
// features/auth/data/datasources/firebase_auth_data_source.dart
@injectable
class FirebaseAuthDataSource implements AuthDataSource {
  final FirebaseAuth _firebaseAuth;
  FirebaseAuthDataSource(this._firebaseAuth); // Injectable injeta via construtor
  // ...
}

// features/auth/data/repositories/auth_repository_impl.dart
@injectable
class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource _dataSource;
  AuthRepositoryImpl(this._dataSource);
  // ...
}

// features/auth/domain/usecases/sign_in_email.dart
@injectable
class SignInEmailUseCase extends UseCase<User, SignInEmailParams> {
  final AuthRepository _repository;
  SignInEmailUseCase(this._repository);
  @override Future<Either<Failure, User>> call(SignInEmailParams params) => _repository.signInEmail(params.email, params.password);
}
```

### Third-party (Module)
```dart
// core/di/modules.dart
@module
abstract class AppModule {
  @singleton
  Dio dio(EnvironmentConfig config) => Dio(BaseOptions(baseUrl: config.apiBaseUrl, connectTimeout: 10.seconds, receiveTimeout: 30.seconds))
    ..interceptors.addAll([AuthInterceptor(getIt()), RetryInterceptor(), LoggingInterceptor(), CacheInterceptor()]);

  @singleton
  FirebaseAuth firebaseAuth() => FirebaseAuth.instance;

  @singleton
  FirebaseCrashlytics crashlytics() => FirebaseCrashlytics.instance;

  @singleton
  FirebaseAnalytics analytics() => FirebaseAnalytics.instance;

  @singleton
  FirebasePerformance performance() => FirebasePerformance.instance;

  @singleton
  GraphQLClient graphQLClient(EnvironmentConfig config) => GraphQLClient(
    link: HttpLink(config.graphqlEndpoint),
    cache: GraphQLCache(),
  );
}
```

### Setup no main.dart
```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  configureDependencies(environment: Environment.name); // dev/staging/prod
  runApp(const ChopperApp());
}
```

### Testes
```dart
// test/features/auth/presentation/bloc/auth_bloc_test.dart
void main() {
  late MockAuthRepository mockAuthRepository;
  late AuthBloc authBloc;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    // Sobrescreve apenas o que precisa no container de teste
    getIt.registerSingleton<AuthRepository>(mockAuthRepository);
    authBloc = AuthBloc(signInEmail: getIt(), signInGoogle: getIt(), signOut: getIt(), deleteAccount: getIt());
  });

  tearDown(() {
    getIt.reset(); // Limpa container entre testes
  });

  blocTest<AuthBloc, AuthState>('emits [Loading, Authenticated] on SignInEmail success', ...);
}
```

---

## Consequências

### Positivas
- ✅ Zero reflection → tree-shaking preservado, startup < 100ms
- ✅ Setup idêntico prod/teste → `configureDependencies(environment: 'test')` com mocks
- ✅ Fácil substituir implementação: `getIt.registerSingleton<MedicationRepository>(mockRepo)`
- ✅ Codegen: `dart run build_runner build --delete-conflicting-outputs` atualiza `injection.dart` automaticamente

### Negativas/Riscos
- ⚠️ Build runner obrigatório a cada mudança de `@injectable`/`@module`
- ⚠️ `getIt.reset()` em `tearDown` essencial para isolamento de testes

### Mitigações
- `build_runner` no CI (`dart run build_runner build --delete-conflicting-outputs`)
- Snippet VS Code: `injectable-class`, `injectable-module`

---

## Alternativas Consideradas

| Alternativa | Prós | Contras | Por que não |
|-------------|------|---------|-------------|
| **Riverpod/Provider** | DI built-in; scoped providers | Acopla Presentation ao container; menos controle sobre lifecycle; migração para BLoC difícil | BLoC + GetIt = separação clara: DI no container, estado no Bloc |
| **GetIt Manual** | Funciona; controle total | `registerSingleton`/`factory` espalhados; manutenção manual propensa a erros; setup teste ≠ prod | Injectable gera `configureDependencies()` único, versionado, testável |

---

## Referências
- [GetIt Docs](https://pub.dev/packages/get_it)
- [Injectable Docs](https://pub.dev/packages/injectable)
- [Dependency Injection in Flutter](https://docs.flutter.dev/app-architecture/guide#dependency-injection)