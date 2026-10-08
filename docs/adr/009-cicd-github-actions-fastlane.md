# ADR 009: CI/CD — GitHub Actions + Fastlane (Match iOS)

**Status:** Accepted  
**Data:** 2026-10-07  
**Autor:** Lucas Souza Frade

---

## Contexto

iFood pede "CI/CD" como diferencial. Precisamos de pipeline que:
- Rode `flutter analyze` + `flutter test --coverage` (quality gate)
- Build signed artifacts: Android `.aab` + iOS `.ipa` (release)
- Gerencie certificados iOS de forma segura (Fastlane Match)
- Versionamento automático (build number = GitHub run number)
- Upload artifacts para download na entrevista
- Gratuito e padrão open source (GitHub Actions)

---

## Decisão

### Stack
| Ferramenta | Papel |
|------------|-------|
| **GitHub Actions** | Orquestração CI/CD (ubuntu-latest + macos-latest) |
| **Fastlane** | Build, certificados (match), versionamento, upload stores (opcional) |
| **Codecov** | Coverage report (opcional, visual) |

### Estrutura de Jobs

```yaml
# .github/workflows/ci.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch: # Manual trigger para release

env:
  FLUTTER_VERSION: '3.24.3'
  JAVA_VERSION: '17'

jobs:
  # Job 1: Análise estática + Testes (ubuntu)
  analyze-test:
    name: Analyze & Test
    runs-on: ubuntu-latest
    timeout-minutes: 30
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          channel: stable
          cache: true
          cache-key: flutter-${{ runner.os }}-${{ hashFiles('**/pubspec.lock') }}

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: ${{ env.JAVA_VERSION }}
          cache: gradle

      - name: Get Dependencies
        run: flutter pub get

      - name: Generate Code (build_runner)
        run: dart run build_runner build --delete-conflicting-outputs

      - name: Analyze
        run: flutter analyze

      - name: Format Check
        run: dart format --set-exit-if-changed .

      - name: Run Tests with Coverage
        run: flutter test --coverage --coverage-path=coverage/lcov.info

      - name: Upload Coverage to Codecov
        uses: codecov/codecov-action@v4
        with:
          files: ./coverage/lcov.info
          flags: unittests
          fail_ci_if_error: false

  # Job 2: Build Android (ubuntu, precisa analyze-test passar)
  build-android:
    name: Build Android (AAB)
    runs-on: ubuntu-latest
    needs: analyze-test
    timeout-minutes: 30
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          channel: stable
          cache: true

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: ${{ env.JAVA_VERSION }}
          cache: gradle

      - name: Get Dependencies
        run: flutter pub get

      - name: Generate Code
        run: dart run build_runner build --delete-conflicting-outputs

      - name: Decode Keystore (Base64 secret)
        run: echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > android/app/upload-keystore.jks

      - name: Build AppBundle (Release)
        run: |
          flutter build appbundle --release \
            --flavor prod \
            --target lib/main_prod.dart \
            --build-number=${{ github.run_number }} \
            --build-name=1.0.${{ github.run_number }}

      - name: Upload Artifact (.aab)
        uses: actions/upload-artifact@v4
        with:
          name: app-release.aab
          path: build/app/outputs/bundle/prodRelease/app-release.aab
          retention-days: 30

  # Job 3: Build iOS (macOS, precisa analyze-test passar)
  build-ios:
    name: Build iOS (IPA)
    runs-on: macos-latest
    needs: analyze-test
    timeout-minutes: 45
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          channel: stable
          cache: true

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true
          working-directory: ./ios

      - name: Get Dependencies
        run: flutter pub get

      - name: Generate Code
        run: dart run build_runner build --delete-conflicting-outputs

      - name: Install Fastlane & Match (readonly)
        run: |
          cd ios
          bundle exec fastlane match appstore --readonly \
            --git_url ${{ secrets.MATCH_GIT_URL }} \
            --git_branch ${{ secrets.MATCH_GIT_BRANCH }} \
            --password ${{ secrets.MATCH_PASSWORD }}

      - name: Build IPA (Release)
        run: |
          cd ios
          bundle exec fastlane build_ios \
            build_number:${{ github.run_number }} \
            version_name:1.0.${{ github.run_number }}

      - name: Upload Artifact (.ipa)
        uses: actions/upload-artifact@v4
        with:
          name: app-release.ipa
          path: ios/build/ipa/app-release.ipa
          retention-days: 30

  # Job 4: Commitlint (pode rodar em paralelo)
  commitlint:
    name: Commitlint
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0 # Histórico completo para commitlint

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install Commitlint
        run: npm ci
        working-directory: .github/commitlint

      - name: Run Commitlint
        run: npx commitlint --from=${{ github.event.pull_request.base.sha || github.sha }} --to=${{ github.sha }}
        working-directory: .github/commitlint
```

### Fastlane Configuração

```ruby
# fastlane/Fastfile
default_platform(:android)

platform :android do
  lane :build do |options|
    gradle(
      task: 'bundle',
      build_type: 'Release',
      flavor: 'prod',
      properties: {
        'versionCode' => options[:build_number] || ENV['GITHUB_RUN_NUMBER'],
        'versionName' => "1.0.#{options[:build_number] || ENV['GITHUB_RUN_NUMBER']}",
      }
    )
  end
end

platform :ios do
  lane :build_ios do |options|
    # Match já executado no step anterior (readonly)
    increment_build_number(build_number: options[:build_number] || ENV['GITHUB_RUN_NUMBER'])
    increment_version_number(version_number: "1.0.#{options[:build_number] || ENV['GITHUB_RUN_NUMBER']}")

    build_app(
      scheme: 'Runner',
      export_method: 'app-store',
      export_options: {
        provisioningProfiles: {
          'com.yourcompany.chopper.prod' => 'match AppStore com.yourcompany.chopper.prod'
        }
      },
      output_directory: '../build/ipa',
      output_name: 'app-release.ipa'
    )
  end
end
```

```ruby
# fastlane/Appfile
app_identifier "com.yourcompany.chopper"
apple_id "seu@email.com"
team_id "SEU_TEAM_ID"

# Flavors
for_lane :build do
  app_identifier "com.yourcompany.chopper.prod"
end
```

```yaml
# fastlane/Matchfile
git_url "https://github.com/seuuser/certificates.git" # Repo privado só para certs
storage_mode "git"
type "appstore"
readonly true # CI só lê, não escreve
```

### Secrets Necessários (GitHub Settings → Secrets → Actions)

| Secret | Descrição | Como Obter |
|--------|-----------|------------|
| `ANDROID_KEYSTORE_BASE64` | Keystore `.jks` codificado em base64 | `base64 -w 0 upload-keystore.jks` |
| `ANDROID_KEY_ALIAS` | Alias da chave no keystore | Definido ao criar keystore |
| `ANDROID_KEY_PASSWORD` | Senha da chave | Definido ao criar keystore |
| `ANDROID_STORE_PASSWORD` | Senha do keystore | Definido ao criar keystore |
| `MATCH_GIT_URL` | URL do repo privado de certificados | `https://github.com/user/certificates.git` |
| `MATCH_GIT_BRANCH` | Branch do repo de certs | `main` |
| `MATCH_PASSWORD` | Senha para descriptografar certs | Definida no `fastlane match init` |
| `APP_STORE_CONNECT_API_KEY` | (Opcional) Upload automático TestFlight | App Store Connect → Users → Keys |
| `FIREBASE_TOKEN` | Token CI para Firebase (se usar emulator) | `firebase login:ci` |
| `CODECOV_TOKEN` | (Opcional) Upload coverage | Codecov.io → Repository → Settings |

### Flavor Config (flutter_flavorizr)
```yaml
# flutter_flavors.yaml
flavors:
  dev:
    app:
      name: "Chopper Dev"
    android:
      applicationId: "com.yourcompany.chopper.dev"
    ios:
      bundleId: "com.yourcompany.chopper.dev"
  staging:
    app:
      name: "Chopper Staging"
    android:
      applicationId: "com.yourcompany.chopper.staging"
    ios:
      bundleId: "com.yourcompany.chopper.staging"
  prod:
    app:
      name: "Chopper"
    android:
      applicationId: "com.yourcompany.chopper"
    ios:
      bundleId: "com.yourcompany.chopper"
```

---

## Consequências

### Positivas
- ✅ Pipeline reproduzível: `analyze → test → build-android → build-ios`
- ✅ Artifacts `.aab`/`.ipa` baixáveis na run (entrevista: "olha o build funcionando")
- ✅ Fastlane Match = padrão enterprise iOS (certificados versionados, seguros, readonly no CI)
- ✅ Versionamento automático: `1.0.{github_run_number}` → rastreável
- ✅ Gratuito: GitHub Actions minutes (ubuntu grátis, macOS 50h/mês grátis)

### Negativas/Riscos
- ⚠️ iOS build **só roda em `macos-latest`** (custa minutes GitHub Actions)
- ⚠️ Fastlane Match setup inicial chato (criar repo certs, `match init`, `match appstore`)
- ⚠️ Keystore Android: nunca commitar; usar secret base64

### Mitigações
- `timeout-minutes` em cada job (evita runaway)
- `cache: true` no `subosito/flutter-action` + `actions/cache` para `.pub-cache` + `build`
- Documentar troubleshooting no README (ex: "Match failed → verifique MATCH_PASSWORD, cert expiration")

---

## Alternativas Consideradas

| Alternativa | Prós | Contras | Por que não |
|-------------|------|---------|-------------|
| **Codemagic / Bitrise** | UI visual; mobile-first; cache inteligente | Pago para builds ilimitados; vendor lock-in | GitHub Actions é grátis, nativo do repo, padrão open source |
| **Fastlane only (local)** | Simples; controle total | Não prova CI no GitHub; artifacts não compartilháveis | Entrevistador quer ver pipeline verde no GitHub |

---

## Referências
- [GitHub Actions Flutter](https://github.com/subosito/flutter-action)
- [Fastlane Match](https://docs.fastlane.tools/actions/match/)
- [Flutter Build iOS](https://docs.flutter.dev/deployment/ios)
- [Flutter Build Android](https://docs.flutter.dev/deployment/android)