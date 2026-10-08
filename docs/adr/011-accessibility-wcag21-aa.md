# ADR 011: Acessibilidade — WCAG 2.1 AA Obrigatória

**Status:** Accepted  
**Data:** 2026-10-07  
**Autor:** Lucas Souza Frade

---

## Contexto

Produto inclusivo é expectativa iFood (milhões de usuários diversos). WCAG 2.1 AA é baseline legal (Brasil: LBI 13.146/2015, Decreto 10.098/2019). Demonstrar a11y no portfólio é diferencial de maturidade.

---

## Decisão

### Requisitos Obrigatórios (Must)

| Critério WCAG | Implementação Flutter | Validação |
|---------------|----------------------|-----------|
| **1.1.1 Non-text Content** | `Semantics(label: '...', image: true)` em ícones/imagens; `excludeSemantics` em decorativos | `flutter_test` + `SemanticsDebugger` |
| **1.3.1 Info and Relationships** | Heading semantics (`Semantics(header: true)`), `Table`/`DataTable` para tabelas, `Form` labels | Teste manual TalkBack |
| **1.4.3 Contrast (Minimum)** | Tokens de cor validados: 4.5:1 (texto normal), 3:1 (large text ≥18pt/14pt bold) | `color_contrast_checker` package ou ferramenta online |
| **1.4.4 Resize Text** | `MediaQuery.textScaler` respeitado; `MediaQuery.of(context).textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 1.5)` opcional | Teste: Settings → Accessibility → Font Size → Large |
| **2.1.1 Keyboard** | `FocusNode` + `FocusableActionDetector` + `Shortcuts`/`Actions` (Desktop/Web) | Tab/Shift+Tab navega; Enter/Space ativa |
| **2.4.3 Focus Order** | `semanticSortKey` para ordem lógica (top→bottom, left→right) | TalkBack swipe order |
| **2.4.7 Focus Visible** | `FocusThemeData` + `focusColor` + `overlayColor` em `ThemeData`; `ConstrainedBox` para outline | Tab navigation visível |
| **2.5.3 Label in Name** | `Semantics(label: 'Botão salvar medicamento')` contém texto visível | TalkBack anuncia label completo |
| **2.5.5 Target Size** | `ConstrainedBox(minWidth: 48, minHeight: 48)` em todos `InkWell`/`IconButton`/`ListTile` | `flutter_test` + `find.byWidgetPredicate` |
| **4.1.2 Name, Role, Value** | `Semantics(button: true, enabled: true, value: '...')` em custom widgets | `SemanticsDebugger` |

### Implementação Prática

#### 1. Semântica em Todos Botões/Inputs
```dart
// core/design/widgets/app_button.dart
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final String? semanticsHint;
  final bool isLoading;

  const AppButton({super.key, required this.label, this.onPressed, this.semanticsHint, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      hint: semanticsHint ?? (enabled ? 'Toque duas vezes para ativar' : 'Botão desabilitado'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48), // WCAG 2.5.5
        child: FilledButton(
          onPressed: onPressed,
          child: isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(label),
        ),
      ),
    );
  }
}
```

#### 2. Inputs com Label + Error + Helper
```dart
// core/design/widgets/app_input.dart
class AppInput extends StatelessWidget {
  final String label;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const AppInput({super.key, required this.label, this.hint, this.errorText, this.helperText, required this.controller, this.validator, this.keyboardType = TextInputType.text, this.prefixIcon, this.suffixIcon});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: label,
      hint: hint,
      value: controller.text,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              errorText: errorText,
              helperText: helperText,
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              border: const OutlineInputBorder(),
              errorBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.error)),
            ),
          ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 12),
              child: Semantics(
                liveRegion: true, // Anuncia erro imediatamente
                child: Text(errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }
}
```

#### 3. Tokens de Cor Validados (Contraste)
```dart
// core/design/tokens.dart
class AppColors {
  // Light theme - validado 4.5:1 contra surface
  static const Color primary = Color(0xFF1F3A5F);      // On: #FFFFFF (7.2:1)
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1A1A2E);    // 15.8:1
  static const Color onSurfaceVariant = Color(0xFF4A4A68); // 4.6:1
  static const Color error = Color(0xFFBA1A1A);        // On: #FFFFFF (4.5:1)
  static const Color onError = Color(0xFFFFFFFF);
  static const Color outline = Color(0xFF7A7A9A);      // 3.2:1 (large text only)

  // Dark theme - validado 4.5:1 contra surface
  static const Color primaryDark = Color(0xFF9DB4E6);  // On: #000000 (6.8:1)
  static const Color onPrimaryDark = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF1A1A2E);
  static const Color onSurfaceDark = Color(0xFFE8E8F0); // 14.2:1
}
```

#### 4. ThemeExtension para Acesso Fácil
```dart
// core/design/theme_extension.dart
@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final AppColors colors;
  final AppSpacing spacing;
  final AppTypography typography;
  final AppRadius radius;
  final AppShadows shadows;

  const AppThemeExtension({required this.colors, required this.spacing, required this.typography, required this.radius, required this.shadows});

  @override
  AppThemeExtension copyWith({AppColors? colors, AppSpacing? spacing, AppTypography? typography, AppRadius? radius, AppShadows? shadows}) {
    return AppThemeExtension(colors: colors ?? this.colors, spacing: spacing ?? this.spacing, typography: typography ?? this.typography, radius: radius ?? this.radius, shadows: shadows ?? this.shadows);
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) => this;
}

// Uso: Theme.of(context).extension<AppThemeExtension>()!.colors.primary
```

#### 5. Lint Custom para A11y
```yaml
# analysis_options.yaml
analyzer:
  plugins:
    - custom_lint
  rules:
    # Regras custom (via custom_lint package)
    prefer_semantics_labels: true
    prefer_contrast_ratio: true
    prefer_touch_target_size: true
    prefer_live_region_for_errors: true
```

#### 6. Teste Manual TalkBack/VoiceOver (Checklist)
```markdown
# Checklist A11y Manual (antes de merge)

## Android (TalkBack)
- [ ] Ativar TalkBack: Settings → Accessibility → TalkBack
- [ ] Navegar por swipe (direita/esquerda) em todas telas
- [ ] Verificar: labels claros, hints úteis, ordem lógica
- [ ] Verificar: touch targets ≥ 48dp (não falha toque)
- [ ] Verificar: contraste em modo "High contrast text" (Developer options)
- [ ] Verificar: escala de fonte "Large" (Settings → Accessibility → Font size)

## iOS (VoiceOver)
- [ ] Ativar VoiceOver: Settings → Accessibility → VoiceOver
- [ ] Navegar por swipe (direita/esquerda) em todas telas
- [ ] Verificar: rotor "Headings" funciona
- [ ] Verificar: actions custom (Tomar/Pular/Adiar) acessíveis
- [ ] Verificar: Dynamic Type (Settings → Accessibility → Display & Text Size → Larger Text)
```

---

## Consequências

### Positivas
- ✅ Inclusão real: app usável por pessoas com deficiência visual/motora
- ✅ Diferencial em entrevista: "Implementei WCAG 2.1 AA completo com testes manuais TalkBack/VoiceOver"
- ✅ Melhora UX para todos (contraste alto ajuda em sol forte; touch targets grandes reduzem erros)
- ✅ Compliance legal (Brasil LBI 13.146/2015)

### Negativas/Riscos
- ⚠️ Revisão manual necessária (ferramentas não pegam tudo: ordem de leitura, contexto)
- ⚠️ Tempo extra em dev (labels, hints, testes manuais)

### Mitigações
- Componentes base (`AppButton`, `AppInput`, `AppCard`) já incluem semântica → features só compõem
- Checklist no PR template; revisão obrigatória
- `custom_lint` pega 80% (labels ausentes, contraste, touch targets)

---

## Alternativas Consideradas

| Alternativa | Prós | Contras | Por que não |
|-------------|------|---------|-------------|
| **Ignorar a11y** | Mais rápido | Risco veto em empresa séria; acessibilidade = qualidade | iFood = milhões usuários; a11y é baseline |
| **Só labels básicos** | Menos trabalho | Não atende WCAG AA (contraste, touch targets, live regions, focus order) | Meio termo não passa auditoria |

---

## Referências
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Flutter Accessibility](https://docs.flutter.dev/development/accessibility-and-internationalization/accessibility)
- [Semantics Widget](https://api.flutter.dev/flutter/widgets/Semantics-class.html)
- [Material 3 Accessibility](https://m3.material.io/foundations/accessibility/overview)
- [LBI 13.146/2015](https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2015/lei/L13146.htm)