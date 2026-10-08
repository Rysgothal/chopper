# ADR 006: Navegação — GoRouter com Auth Guards + Deep Linking

**Status:** Accepted  
**Data:** 2026-10-07  
**Autor:** Lucas Souza Frade

---

## Contexto

Precisamos de navegação que suporte:
- Declarativa (rotas como configuração, não código imperativo)
- Auth guards (redirecionamento baseado em estado de autenticação)
- Deep linking (futuro: `chopper://medication/123`)
- Testável (mock/override em widget tests)
- Padrão Google/Flutter team (iFood usa GoRouter)

---

## Decisão

### Stack
| Package | Versão | Papel |
|---------|--------|-------|
| `go_router` | ^13.2+ | Navegação declarativa, guards, deep links |

### Configuração Centralizada
```dart
// core/config/app_router.dart
@injectable
class AppRouter {
  final AuthBloc _authBloc;
  late final GoRouter router;

  AppRouter(this._authBloc) {
    router = GoRouter(
      initialLocation: '/splash', // Decide para onde ir após verificar auth
      refreshListenable: GoRouterRefreshStream(_authBloc.stream), // Reavalia guard na mudança de estado
      redirect: _authGuard,
      routes: _routes,
      errorBuilder: (context, state) => const Scaffold(body: Center(child: Text('Página não encontrada'))),
    );
  }

  // Auth Guard Centralizado
  String? _authGuard(BuildContext context, GoRouterState state) {
    final authenticated = _authBloc.state is Authenticated;
    final loggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/onboarding';

    if (!authenticated && !loggingIn) return '/login';     // Não autenticado → login
    if (authenticated && loggingIn) return '/home';        // Autenticado tentando acessar login → home
    return null; // Permite navegação
  }

  // Rotas
  List<RouteBase> get _routes => [
    GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPermissionsPage()),
    GoRoute(path: '/home', builder: (_, __) => const HomePage()),
    GoRoute(
      path: '/medication/:id',
      builder: (_, state) => MedicationDetailPage(medicationId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/medication/new', builder: (_, __) => const MedicationFormPage()),
    GoRoute(path: '/medication/:id/edit', builder: (_, state) => MedicationFormPage(medicationId: state.pathParameters['id'])),
    GoRoute(path: '/adherence', builder: (_, __) => const AdherenceDashboardPage()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
    // Deep link futuro:
    // GoRoute(path: '/medication/:id', builder: (_, state) => ...),
  ];
}
```

### GoRouterRefreshStream (Wrapper para Stream)
```dart
// core/config/go_router_refresh_stream.dart
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    stream.listen((_) => notifyListeners());
  }
}
```

### Uso em Blocs/Pages (Navegação Programática)
```dart
// Em Bloc (após sucesso)
context.go('/home');           // Substitui stack (login → home)
context.push('/medication/new'); // Adiciona à stack (home → form)
context.pop();                 // Volta
context.pushReplacement('/adherence'); // Substitui atual
```

### Deep Linking (Futuro)
```dart
// Android: AndroidManifest.xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="chopper" android:host="medication" />
</intent-filter>

// iOS: Info.plist
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array><string>chopper</string></array>
  </dict>
</array>
```

### Teste (Widget Test)
```dart
// test/features/medication/presentation/pages/medication_list_page_test.dart
testWidgets('navega para form ao tocar FAB', (tester) async {
  final mockRouter = MockGoRouter();
  when(mockRouter.push(any)).thenAnswer((_) async => null);

  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: mockRouter,
      // providers...
    ),
  );

  await tester.tap(find.byIcon(Icons.add));
  verify(mockRouter.push('/medication/new')).called(1);
});
```

---

## Consequências

### Positivas
- ✅ Guards centralizados em 1 lugar (`redirect`) — não espalhado por páginas
- ✅ Testável: `GoRouter` pode ser mockado/overridden em `MaterialApp.router`
- ✅ Deep linking pronto (configuração nativa Android/iOS)
- ✅ Navegação type-safe com `go_router_builder` (codegen opcional)

### Negativas/Riscos
- ⚠️ `refreshListenable` com `AuthBloc.stream` requer que `AuthBloc` emita estados consistentemente
- ⚠️ `GoRouter` 13+ mudou API (ex: `GoRouterState` → `GoRouterState`)

### Mitigações
- Testes de integração cobrem fluxos auth (login → home, logout → login)
- Pin version `go_router: ^13.2.0` no `pubspec.yaml`

---

## Alternativas Consideradas

| Alternativa | Prós | Contras | Por que não |
|-------------|------|---------|-------------|
| **AutoRoute** | Codegen type-safe; guards via `@AutoRoute(guards: [AuthGuard])` | Codegen heavy; mais boilerplate; GoRouter é padrão Google/Flutter team | GoRouter atende 100% dos requisitos com menos complexidade |
| **Navigator 2.0 manual** | Controle total | Verboso, propenso a erros de stack, guards manuais em cada página | Reinventar a roda; GoRouter resolve bem |

---

## Referências
- [GoRouter Docs](https://pub.dev/packages/go_router)
- [GoRouter Auth Guards](https://github.com/flutter/packages/blob/main/packages/go_router/example/lib/auth_flow.dart)
- [Deep Linking Flutter](https://docs.flutter.dev/development/ui/navigation/deep-linking)