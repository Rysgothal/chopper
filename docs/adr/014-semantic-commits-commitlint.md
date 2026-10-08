# ADR 014: Commits Semânticos + Conventional Commits + Commitlint

**Status:** Accepted  
**Data:** 2026-10-07  
**Autor:** Lucas Souza Frade

---

## Contexto

Histórico legível, CHANGELOG automático, revisão de PR facilitada. Padrão enterprise (Angular, Conventional Commits). iFood valoriza engenharia disciplinada.

---

## Decisão

### Convenção (Conventional Commits 1.0)

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Tipos Obrigatórios

| Tipo | Uso | Exemplo |
|------|-----|---------|
| `feat` | Nova funcionalidade | `feat(medication): add CRUD with offline-first` |
| `fix` | Correção de bug | `fix(notification): handle exact alarm permission denied` |
| `test` | Adição/alteração de testes | `test(auth): add bloc tests for Google sign-in` |
| `ci` | Mudanças em CI/CD | `ci: add Fastlane match readonly for iOS build` |
| `refactor` | Refatoração sem mudança de comportamento | `refactor(database): optimize Drift queries with indexes` |
| `docs` | Documentação | `docs: update README with architecture diagram` |
| `chore` | Manutenção (deps, config, scripts) | `chore: upgrade Flutter to 3.24.3` |
| `perf` | Melhoria de performance | `perf(list): add RepaintBoundary to medication items` |
| `style` | Formatação, lint (sem mudança lógica) | `style: format with dart format` |
| `build` | Build system, deps externas | `build: add graphql_codegen to dev_dependencies` |

### Regras de Subject
- **Imperativo, presente**: "add" não "added" ou "adds"
- **Minúscula** no início
- **Sem ponto final**
- **Máx 72 chars** (ideal ≤ 50)

### Scope (Opcional mas Recomendado)
- `auth`, `medication`, `notification`, `sync`, `search`, `adherence`, `report`, `ui`, `core`, `ci`, `docs`, `deps`

### Body (Opcional)
- Explica **o que** e **por que** (não como)
- Quebra de linha em 72 chars

### Footer (Opcional)
- **Breaking Changes**: `BREAKING CHANGE: <description>`
- **Issues**: `Closes #123`, `Refs #456`

### Exemplos

```bash
# Feature completa
feat(medication): add offline-first CRUD with Drift and outbox pattern

- Implement MedicationRepositoryImpl with local DataSource
- Add SyncQueue table for outbox pattern (create/update/delete)
- Add MedicationBloc with Freezed states/events
- Add MedicationListPage, FormPage, DetailPage with a11y

Closes #15

# Bug fix com breaking change
fix(auth)!: handle token refresh race condition with Lock

- Add Lock in AuthInterceptor to prevent concurrent 401 refresh
- On refresh failure: sign out user and clear local data
- Update AuthBloc to handle unauthenticated state

BREAKING CHANGE: AuthInterceptor now requires Lock dependency; consumers must provide via DI

# Apenas docs
docs(adr): add ADR 007 for notifications exact alarms + workmanager

# Chore de dependências
chore(deps): upgrade Flutter to 3.24.3 and Dart 3.5.0
```

### Breaking Changes
- `!` após type: `feat!: ...` ou `fix!: ...`
- `BREAKING CHANGE:` no body (obrigatório se `!`)

---

## Tooling

### 1. Commitlint (CI Gate)
```json
// .github/commitlint/package.json
{
  "name": "commitlint-config",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "@commitlint/cli": "^19.0.0",
    "@commitlint/config-conventional": "^19.0.0"
  }
}
```

```javascript
// .github/commitlint/commitlint.config.js
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [2, 'always', ['feat', 'fix', 'test', 'ci', 'refactor', 'docs', 'chore', 'perf', 'style', 'build']],
    'scope-case': [2, 'always', 'lower-case'],
    'subject-case': [2, 'always', ['sentence-case', 'start-case']],
    'subject-empty': [2, 'never'],
    'subject-max-length': [2, 'always', 72],
    'body-max-line-length': [2, 'always', 72],
  },
  prompt: {
    types: [
      { value: 'feat', name: 'feat:     Nova funcionalidade' },
      { value: 'fix', name: 'fix:      Correção de bug' },
      { value: 'test', name: 'test:     Testes' },
      { value: 'ci', name: 'ci:       CI/CD' },
      { value: 'refactor', name: 'refactor: Refatoração' },
      { value: 'docs', name: 'docs:     Documentação' },
      { value: 'chore', name: 'chore:    Manutenção' },
      { value: 'perf', name: 'perf:     Performance' },
      { value: 'style', name: 'style:    Formatação' },
      { value: 'build', name: 'build:    Build system' },
    ],
  },
};
```

```yaml
# .github/workflows/ci.yml (trecho commitlint)
- name: Run Commitlint
  run: npx commitlint --from=${{ github.event.pull_request.base.sha || github.sha }} --to=${{ github.sha }}
  working-directory: .github/commitlint
```

### 2. Husky (Local Hook - Falha Rápida)
```bash
# Instalar husky (Node.js)
npm install --save-dev husky
npx husky install
npx husky add .husky/commit-msg 'npx --no-install commitlint --edit "$1"'
```

```json
// package.json (raiz do projeto Flutter - opcional para husky)
{
  "scripts": {
    "prepare": "husky install"
  },
  "devDependencies": {
    "husky": "^9.0.0"
  }
}
```

> **Nota:** Husky requer Node.js. Alternativa Dart: `melos` + `commitlint` wrapper ou script `tool/commitlint.dart` no `pre-commit` do `very_good_analysis`. Para MVP, **apenas CI gate** já basta; husky local é quality-of-life.

### 3. VS Code Snippets (Commit Message)
```json
// .vscode/commit-message.code-snippets
{
  "Conventional Commit": {
    "prefix": "cc",
    "body": [
      "${1:feat|fix|test|ci|refactor|docs|chore|perf|style|build}(${2:scope}): ${3:subject}",
      "",
      "${4:body}",
      "",
      "${5:BREAKING CHANGE: |Closes #}"
    ],
    "description": "Conventional Commit message"
  }
}
```

---

## Consequências

### Positivas
- ✅ Histórico navegável: `git log --oneline --grep="feat"` / `--grep="fix"` / `--author="Lucas"`
- ✅ `standard-version`/`semantic-release` futuro para versionamento automático + CHANGELOG
- ✅ PR review: commits pequenos, atômicos, semânticos → fácil bisect
- ✅ CI gate: commit inválido = pipeline falha → disciplina forçada

### Negativas/Riscos
- ⚠️ Disciplina inicial (mitigado: CI gate + snippet VS Code)
- ⚠️ Commitlint no CI requer Node.js (leve, `actions/setup-node`)

### Mitigações
- Snippet `cc` no VS Code gera template
- Commitlint roda em < 5s no CI
- Documentar no README: "Commits seguem Conventional Commits; use `cc` snippet"

---

## Alternativas Consideradas

| Alternativa | Prós | Contras | Por que não |
|-------------|------|---------|-------------|
| **Commits livres** | Zero overhead | Histórico ilegível; `git log` inútil; PR review difícil | Não passa bar enterprise |
| **Gitmoji** | Visual, divertido | Não machine-readable; sem tooling padrão | Conventional Commits = padrão indústria |

---

## Referências
- [Conventional Commits](https://www.conventionalcommits.org/pt-br/v1.0.0/)
- [Commitlint](https://commitlint.js.org/)
- [Husky](https://typicode.github.io/husky/)
- [Standard Version](https://github.com/conventional-changelog/standard-version)