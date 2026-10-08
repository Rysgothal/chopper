# ADR 012: Design System — Tokens + ThemeExtension + Componentes Reutilizáveis

**Status:** Accepted  
**Data:** 2026-10-07  
**Autor:** Lucas Souza Frade

---

## Contexto

Consistência visual, velocidade de desenvolvimento, manutenibilidade. iFood tem Design System próprio; mostrar que sabe construir um é sinal de maturidade Pleno/Sênior. Zero hardcoded colors/spacings em features.

---

## Decisão

### Estrutura
```
lib/core/design/
├── tokens.dart              # AppColors, AppSpacing, AppTypography, AppRadius, AppShadows
├── theme_extension.dart     # AppThemeExtension (ThemeExtension)
├── app_theme.dart           # ThemeData builder (light/dark) usando tokens
└── widgets/
    ├── app_button.dart
    ├── app_input.dart
    ├── app_card.dart
    ├── app_chip.dart
    ├── app_snackbar.dart
    ├── app_dialog.dart
    └── app_bottom_sheet.dart
```

### 1. Tokens (Single Source of Truth)
```dart
// core/design/tokens.dart

// Cores (Light + Dark validados contraste WCAG AA)
class AppColors {
  // Light
  static const Color primary = Color(0xFF1F3A5F);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFD6E4FF);
  static const Color onPrimaryContainer = Color(0xFF001B3F);
  static const Color secondary = Color(0xFF4A6FA5);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1A1A2E);
  static const Color onSurfaceVariant = Color(0xFF4A4A68);
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color outline = Color(0xFF7A7A9A);
  static const Color shadow = Color(0x33000000);

  // Dark
  static const Color primaryDark = Color(0xFF9DB4E6);
  static const Color onPrimaryDark = Color(0xFF000000);
  static const Color primaryContainerDark = Color(0xFF001B3F);
  static const Color onPrimaryContainerDark = Color(0xFFD6E4FF);
  static const Color secondaryDark = Color(0xFFB4C9E8);
  static const Color onSecondaryDark = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF1A1A2E);
  static const Color onSurfaceDark = Color(0xFFE8E8F0);
  static const Color onSurfaceVariantDark = Color(0xFFC4C4D8);
  static const Color errorDark = Color(0xFFFFB4AB);
  static const Color onErrorDark = Color(0xFF690005);
  static const Color outlineDark = Color(0xFF8E8EA8);
  static const Color shadowDark = Color(0x66000000);
}

// Espaçamento (base 4dp)
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

// Tipografia (Material 3 TextStyles nomeadas)
class AppTypography {
  static const TextStyle displayLarge = TextStyle(fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: -0.25);
  static const TextStyle displayMedium = TextStyle(fontSize: 45, fontWeight: FontWeight.w400);
  static const TextStyle displaySmall = TextStyle(fontSize: 36, fontWeight: FontWeight.w400);
  static const TextStyle headlineLarge = TextStyle(fontSize: 32, fontWeight: FontWeight.w600);
  static const TextStyle headlineMedium = TextStyle(fontSize: 28, fontWeight: FontWeight.w600);
  static const TextStyle headlineSmall = TextStyle(fontSize: 24, fontWeight: FontWeight.w600);
  static const TextStyle titleLarge = TextStyle(fontSize: 22, fontWeight: FontWeight.w500);
  static const TextStyle titleMedium = TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.15);
  static const TextStyle titleSmall = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1);
  static const TextStyle bodyLarge = TextStyle(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5);
  static const TextStyle bodyMedium = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25);
  static const TextStyle bodySmall = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4);
  static const TextStyle labelLarge = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1);
  static const TextStyle labelMedium = TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5);
  static const TextStyle labelSmall = TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5);
}

// Raios
class AppRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 999;
}

// Sombras (Elevation 1-4)
class AppShadows {
  static List<BoxShadow> get elevation1 => [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: Offset(0, 1))];
  static List<BoxShadow> get elevation2 => [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2))];
  static List<BoxShadow> get elevation3 => [BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: Offset(0, 4))];
  static List<BoxShadow> get elevation4 => [BoxShadow(color: AppColors.shadow, blurRadius: 24, offset: Offset(0, 8))];
}
```

### 2. ThemeExtension (Acesso Type-Safe)
```dart
// core/design/theme_extension.dart
@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final AppColors colors;
  final AppSpacing spacing;
  final AppTypography typography;
  final AppRadius radius;
  final AppShadows shadows;

  const AppThemeExtension({
    required this.colors,
    required this.spacing,
    required this.typography,
    required this.radius,
    required this.shadows,
  });

  @override
  AppThemeExtension copyWith({
    AppColors? colors,
    AppSpacing? spacing,
    AppTypography? typography,
    AppRadius? radius,
    AppShadows? shadows,
  }) {
    return AppThemeExtension(
      colors: colors ?? this.colors,
      spacing: spacing ?? this.spacing,
      typography: typography ?? this.typography,
      radius: radius ?? this.radius,
      shadows: shadows ?? this.shadows,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) => this;
}

// Extensão para acesso fácil
extension AppThemeExt on BuildContext {
  AppThemeExtension get appTheme => Theme.of(this).extension<AppThemeExtension>()!;
  AppColors get appColors => appTheme.colors;
  AppSpacing get appSpacing => appTheme.spacing;
  AppTypography get appTypography => appTheme.typography;
  AppRadius get appRadius => appTheme.radius;
  AppShadows get appShadows => appTheme.shadows;
}
```

### 3. ThemeData Builder (Light + Dark)
```dart
// core/design/app_theme.dart
class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      error: AppColors.error,
      onError: AppColors.onError,
      outline: AppColors.outline,
      shadow: AppColors.shadow,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      extensions: [const AppThemeExtension(
        colors: AppColors(), // Instância com getters estáticos
        spacing: AppSpacing(),
        typography: AppTypography(),
        radius: AppRadius(),
        shadows: AppShadows(),
      )],
      // Componentes globais (opcional, sobrescreve defaults)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48), // WCAG touch target
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      ),
      cardTheme: CardTheme(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        margin: EdgeInsets.zero,
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.dark(
      primary: AppColors.primaryDark,
      onPrimary: AppColors.onPrimaryDark,
      primaryContainer: AppColors.primaryContainerDark,
      onPrimaryContainer: AppColors.onPrimaryContainerDark,
      secondary: AppColors.secondaryDark,
      onSecondary: AppColors.onSecondaryDark,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.onSurfaceDark,
      onSurfaceVariant: AppColors.onSurfaceVariantDark,
      error: AppColors.errorDark,
      onError: AppColors.onErrorDark,
      outline: AppColors.outlineDark,
      shadow: AppColors.shadowDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      extensions: [const AppThemeExtension(
        colors: AppColors(),
        spacing: AppSpacing(),
        typography: AppTypography(),
        radius: AppRadius(),
        shadows: AppShadows(),
      )],
      // ... mesmos component themes com cores dark
    );
  }
}
```

### 4. Componentes Base (Zero Hardcoded)
```dart
// core/design/widgets/app_button.dart
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final String? semanticsHint;

  const AppButton({
    super.key, 
    required this.label, 
    this.onPressed, 
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.semanticsHint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final enabled = onPressed != null && !isLoading;
    final colorScheme = Theme.of(context).colorScheme;

    Widget child = isLoading
        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _getLoadingColor(variant, colorScheme)))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingIcon != null) ...[leadingIcon!, SizedBox(width: theme.spacing.sm)],
              Text(label, style: theme.typography.labelLarge),
              if (trailingIcon != null) ...[SizedBox(width: theme.spacing.sm), trailingIcon!],
            ],
          );

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      hint: semanticsHint ?? (enabled ? 'Toque duas vezes para ativar' : 'Botão desabilitado'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: _buildButton(context, child, variant, enabled, colorScheme, theme),
      ),
    );
  }

  Widget _buildButton(BuildContext context, Widget child, AppButtonVariant variant, bool enabled, ColorScheme colorScheme, AppThemeExtension theme) {
    switch (variant) {
      case AppButtonVariant.primary:
        return FilledButton(onPressed: enabled ? onPressed : null, child: child);
      case AppButtonVariant.secondary:
        return FilledButton.tonal(onPressed: enabled ? onPressed : null, child: child);
      case AppButtonVariant.outline:
        return OutlinedButton(onPressed: enabled ? onPressed : null, child: child);
      case AppButtonVariant.ghost:
        return TextButton(onPressed: enabled ? onPressed : null, child: child);
    }
  }
}

enum AppButtonVariant { primary, secondary, outline, ghost }
```

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
  final bool obscureText;

  const AppInput({super.key, required this.label, this.hint, this.errorText, this.helperText, required this.controller, this.validator, this.keyboardType = TextInputType.text, this.prefixIcon, this.suffixIcon, this.obscureText = false});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;

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
            obscureText: obscureText,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              errorText: errorText,
              helperText: helperText,
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(theme.radius.md)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(theme.radius.md), borderSide: BorderSide(color: colorScheme.outline)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(theme.radius.md), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(theme.radius.md), borderSide: BorderSide(color: colorScheme.error)),
              contentPadding: EdgeInsets.symmetric(horizontal: theme.spacing.lg, vertical: theme.spacing.md),
            ),
          ),
          if (errorText != null)
            Padding(
              padding: EdgeInsets.only(top: theme.spacing.xs, left: theme.spacing.md),
              child: Semantics(
                liveRegion: true,
                child: Text(errorText!, style: theme.typography.bodySmall.copyWith(color: colorScheme.error)),
              ),
            ),
        ],
      ),
    );
  }
}
```

### 5. Uso em Features (Zero Hardcoded)
```dart
// features/medication/presentation/pages/medication_form_page.dart
class MedicationFormPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    return Scaffold(
      appBar: AppBar(title: Text('Novo Medicamento', style: theme.typography.titleLarge)),
      body: Padding(
        padding: EdgeInsets.all(theme.spacing.lg),
        child: Form(
          child: Column(
            children: [
              AppInput(label: 'Nome', controller: _nameController, validator: (v) => v?.isEmpty == true ? 'Obrigatório' : null),
              SizedBox(height: theme.spacing.md),
              AppInput(label: 'Dosagem', controller: _dosageController, hint: 'Ex: 500mg'),
              SizedBox(height: theme.spacing.md),
              // ... outros campos
              SizedBox(height: theme.spacing.xl),
              SizedBox(
                width: double.infinity,
                child: AppButton(label: 'Salvar', onPressed: _save, variant: AppButtonVariant.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## Consequências

### Positivas
- ✅ Mudança global de tema/cor/espaçamento = 1 arquivo (`tokens.dart`)
- ✅ Onboarding visual: novos devs veem componentes prontos no `core/design/widgets/`
- ✅ A11y built-in: touch targets, contraste, semântica nos componentes base
- ✅ Type-safe: `context.appColors.primary` vs `Colors.blue` (refatoração segura)

### Negativas/Riscos
- ⚠️ Investimento inicial (~2-3 dias para tokens + 5 componentes base)
- ⚠️ Disciplina: code review deve barrar hardcoded `Colors.blue`, `16.0`, `TextStyle(...)`

### Mitigações
- Copiar/adaptar de projeto anterior ou template open source (ex: `flutter_design_system`)
- `custom_lint` rule: `prefer_theme_extensions` flagga `Colors.*`, `EdgeInsets.all(16)`, `TextStyle()` fora do theme

---

## Alternativas Consideradas

| Alternativa | Prós | Contras | Por que não |
|-------------|------|---------|-------------|
| **Hardcoded em cada widget** | Rápido no início | Dívida técnica imediata; inconsistência visual; refatoração dolorosa | Não passa code review enterprise |
| **Package externo (Material 3 apenas)** | Zero setup | Limita customização; não demonstra habilidade de construir DS | iFood tem DS próprio; saber construir é diferencial |

---

## Referências
- [Material 3 Theme](https://m3.material.io/styles/color/the-color-system/overview)
- [ThemeExtension](https://api.flutter.dev/flutter/material/ThemeExtension-class.html)
- [Design Tokens](https://designtokens.org/)
- [Flutter Custom Lint](https://pub.dev/packages/custom_lint)