# ADR 015: Flavors — flutter_flavorizr (dev, staging, prod)

**Status:** Accepted  
**Data:** 2026-10-07  
**Autor:** Lucas Souza Frade

---

## Contexto

3 ambientes com configs isoladas:
- **Firebase project** diferente (dev/staging/prod)
- **API base URL** diferente
- **Bundle ID / Application ID** diferente
- **App name / ícone** diferente
- **Configurações nativas** (Android flavors, iOS schemes)

`flutter_flavorizr` gera tudo automaticamente: Android flavors, iOS schemes/xcconfigs, `main_<flavor>.dart`, `flutter_flavors.yaml`. Evita gambiarras com `--dart-define` manual.

---

## Decisão

### Stack
| Package | Versão | Papel |
|---------|--------|-------|
| `flutter_flavorizr` | ^2.2+ | Gera flavors Android/iOS + entry points Dart |

### Configuração Central (`flutter_flavors.yaml`)
```yaml
# flutter_flavors.yaml (raiz do projeto)
flavors:
  dev:
    app:
      name: "Chopper Dev"
    android:
      applicationId: "com.yourcompany.chopper.dev"
      icon: "assets/icons/dev/icon.png"
    ios:
      bundleId: "com.yourcompany.chopper.dev"
      icon: "assets/icons/dev/icon.png"
    firebase:
      android: "google-services-dev.json"
      ios: "GoogleService-Info-dev.plist"
  staging:
    app:
      name: "Chopper Staging"
    android:
      applicationId: "com.yourcompany.chopper.staging"
      icon: "assets/icons/staging/icon.png"
    ios:
      bundleId: "com.yourcompany.chopper.staging"
      icon: "assets/icons/staging/icon.png"
    firebase:
      android: "google-services-staging.json"
      ios: "GoogleService-Info-staging.plist"
  prod:
    app:
      name: "Chopper"
    android:
      applicationId: "com.yourcompany.chopper"
      icon: "assets/icons/prod/icon.png"
    ios:
      bundleId: "com.yourcompany.chopper"
      icon: "assets/icons/prod/icon.png"
    firebase:
      android: "google-services-prod.json"
      ios: "GoogleService-Info-prod.plist"

# Configurações gerais
ide: "vscode" # ou "android_studio"
flavor_dimensions: "environment"
```

### Geração (Uma Vez + Commit)
```bash
# Instala
dart pub global activate flutter_flavorizr

# Gera tudo (Android flavors, iOS schemes, main_*.dart, flutter_flavors.yaml)
flutter pub run flutter_flavorizr
```

### O Que É Gerado

#### Android (`android/app/build.gradle` + `src/`)
```gradle
// android/app/build.gradle (adicionado pelo flavorizr)
flavorDimensions "environment"
productFlavors {
    dev {
        dimension "environment"
        applicationId "com.yourcompany.chopper.dev"
        versionNameSuffix "-dev"
        resValue "string", "app_name", "Chopper Dev"
        manifestPlaceholders = [appIcon: "@mipmap/ic_launcher_dev"]
    }
    staging {
        dimension "environment"
        applicationId "com.yourcompany.chopper.staging"
        versionNameSuffix "-staging"
        resValue "string", "app_name", "Chopper Staging"
        manifestPlaceholders = [appIcon: "@mipmap/ic_launcher_staging"]
    }
    prod {
        dimension "environment"
        applicationId "com.yourcompany.chopper"
        resValue "string", "app_name", "Chopper"
        manifestPlaceholders = [appIcon: "@mipmap/ic_launcher"]
    }
}
```

#### iOS (`ios/Flutter/Flutter-<flavor>.xcconfig` + `ios/Runner.xcworkspace`)
```xcconfig
// ios/Flutter/Flutter-dev.xcconfig
#include "Generated.xcconfig"
FLUTTER_TARGET=lib/main_dev.dart
FLUTTER_BUILD_NAME=1.0.0
FLUTTER_BUILD_NUMBER=1
PRODUCT_BUNDLE_IDENTIFIER=com.yourcompany.chopper.dev
PRODUCT_NAME=Chopper Dev
ASSETCATALOG_COMPILER_APPICON_NAME=AppIcon-dev
```

#### Entry Points Dart (`lib/main_<flavor>.dart`)
```dart
// lib/main_dev.dart
import 'package:chopper/app.dart';
import 'package:chopper/core/config/environment.dart';

void main() {
  Environment.name = 'dev';
  runApp(const ChopperApp());
}

// lib/main_staging.dart
import 'package:chopper/app.dart';
import 'package:chopper/core/config/environment.dart';

void main() {
  Environment.name = 'staging';
  runApp(const ChopperApp());
}

// lib/main_prod.dart
import 'package:chopper/app.dart';
import 'package:chopper/core/config/environment.dart';

void main() {
  Environment.name = 'prod';
  runApp(const ChopperApp());
}
```

### EnvironmentConfig (Type-Safe)
```dart
// core/config/environment.dart
class Environment {
  static String name = 'dev'; // Sobrescrito no main_<flavor>.dart

  static EnvironmentConfig get config {
    switch (name) {
      case 'dev':
        return EnvironmentConfig(
          flavor: 'dev',
          apiBaseUrl: 'https://api-dev.chopper.app',
          graphqlEndpoint: 'https://api-dev.chopper.app/graphql',
          firebaseProjectId: 'chopper-dev',
          enableAnalytics: false,
          enableCrashlytics: true,
        );
      case 'staging':
        return EnvironmentConfig(
          flavor: 'staging',
          apiBaseUrl: 'https://api-staging.chopper.app',
          graphqlEndpoint: 'https://api-staging.chopper.app/graphql',
          firebaseProjectId: 'chopper-staging',
          enableAnalytics: true,
          enableCrashlytics: true,
        );
      case 'prod':
        return EnvironmentConfig(
          flavor: 'prod',
          apiBaseUrl: 'https://api.chopper.app',
          graphqlEndpoint: 'https://api.chopper.app/graphql',
          firebaseProjectId: 'chopper-prod',
          enableAnalytics: true,
          enableCrashlytics: true,
        );
      default:
        throw Exception('Unknown flavor: $name');
    }
  }
}

@immutable
class EnvironmentConfig {
  final String flavor;
  final String apiBaseUrl;
  final String graphqlEndpoint;
  final String firebaseProjectId;
  final bool enableAnalytics;
  final bool enableCrashlytics;

  const EnvironmentConfig({
    required this.flavor,
    required this.apiBaseUrl,
    required this.graphqlEndpoint,
    required this.firebaseProjectId,
    required this.enableAnalytics,
    required this.enableCrashlytics,
  });
}
```

### Uso no Código (DI + Config)
```dart
// core/di/modules.dart
@module
abstract class AppModule {
  @singleton
  Dio dio(EnvironmentConfig config) => Dio(BaseOptions(baseUrl: config.apiBaseUrl, ...));
  
  @singleton
  GraphQLClient graphQLClient(EnvironmentConfig config) => GraphQLClient(
    link: HttpLink(config.graphqlEndpoint),
    cache: GraphQLCache(),
  );
  
  @singleton
  EnvironmentConfig environmentConfig() => Environment.config;
}
```

```dart
// features/medication/data/datasources/remote_medication_data_source.dart
@injectable
class RemoteMedicationDataSourceImpl implements MedicationRemoteDataSource {
  final Dio _dio;
  RemoteMedicationDataSourceImpl(this._dio);
  // _dio já tem baseUrl correta via EnvironmentConfig injetado
}
```

### Build & Run (Commands)
```bash
# Desenvolvimento
flutter run --flavor dev --target lib/main_dev.dart
flutter run --flavor staging --target lib/main_staging.dart

# Build Release
flutter build appbundle --flavor prod --target lib/main_prod.dart --release
flutter build ipa --flavor prod --target lib/main_prod.dart --release --export-options-plist=ios/ExportOptions.plist

# CI/CD (GitHub Actions)
# build-android: flutter build appbundle --flavor prod --target lib/main_prod.dart
# build-ios: flutter build ipa --flavor prod --target lib/main_prod.dart
```

### Firebase por Flavor
```bash
# 1. Criar 3 projects no Firebase Console: chopper-dev, chopper-staging, chopper-prod
# 2. Baixar configs:
#    android/app/src/dev/google-services.json
#    android/app/src/staging/google-services.json
#    android/app/src/prod/google-services.json
#    ios/Runner/GoogleService-Info-dev.plist
#    ios/Runner/GoogleService-Info-staging.plist
#    ios/Runner/GoogleService-Info-prod.plist

# 3. flutterfire configure (gera firebase_options.dart por flavor)
flutterfire configure --project=chopper-dev --out=lib/firebase_options_dev.dart
flutterfire configure --project=chopper-staging --out=lib/firebase_options_staging.dart
flutterfire configure --project=chopper-prod --out=lib/firebase_options_prod.dart
```

```dart
// lib/main_dev.dart (atualizado)
import 'package:chopper/app.dart';
import 'package:chopper/core/config/environment.dart';
import 'package:chopper/firebase_options_dev.dart' as firebase_options;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebase_options.DefaultFirebaseOptions.currentPlatform);
  Environment.name = 'dev';
  runApp(const ChopperApp());
}
```

---

## Consequências

### Positivas
- ✅ Build nativo: `flutter build appbundle --flavor prod --target lib/main_prod.dart` funciona out-of-the-box
- ✅ CI/CD usa flavors nativos (não `--dart-define` frágil)
- ✅ Configs isoladas: Firebase, API, Bundle ID, ícone, nome — zero conflito
- ✅ Type-safe: `Environment.config.apiBaseUrl` injetado via DI
- ✅ Uma vez só: `flutter_flavorizr` gera, commita, depois só usa

### Negativas/Riscos
- ⚠️ Setup inicial chato (ícones, Firebase projects, `flutter_flavorizr` config)
- ⚠️ iOS: `flutter_flavorizr` modifica `Runner.xcworkspace` — commit todo o `ios/`
- ⚠️ Mudança de flavor = rebuild completo (não hot reload entre flavors)

### Mitigações
- Documentar no README: "Flavors: `flutter run --flavor dev --target lib/main_dev.dart`"
- Commitar tudo gerado (`android/app/src/`, `ios/Flutter/`, `lib/main_*.dart`, `flutter_flavors.yaml`)
- `flutter_flavorizr` idempotente: rodar novamente se adicionar flavor

---

## Alternativas Consideradas

| Alternativa | Prós | Contras | Por que não |
|-------------|------|---------|-------------|
| **`--dart-define` manual** | Funciona; sem tooling extra | Propenso a typos; não separa bundle ID/ícone; não type-safe | Frágil; não escala |
| **Fastlane only** | Gerencia certs/builds | Não gera código Dart/Android/iOS automaticamente | `flutter_flavorizr` complementa Fastlane |

---

## Referências
- [flutter_flavorizr](https://pub.dev/packages/flutter_flavorizr)
- [Flutter Flavors Guide](https://docs.flutter.dev/deployment/flavors)
- [Firebase Multi-project](https://firebase.google.com/docs/projects/learn-more#multi-project)