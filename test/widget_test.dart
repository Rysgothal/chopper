// This is a basic Flutter widget test.
// Tests the login screen UI.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chopper/main.dart';

void main() {
  testWidgets('Login screen renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MainApp());

    // Verify that the login screen is shown
    expect(find.text('Bem-vindo ao Chopper'), findsOneWidget);
    expect(find.text('Faça login para continuar'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Esqueceu a senha?'), findsOneWidget);
    expect(find.textContaining('Não tem uma conta'), findsOneWidget);
    expect(find.text('Cadastre-se'), findsOneWidget);
  });

  testWidgets('Login form validation works', (WidgetTester tester) async {
    await tester.pumpWidget(const MainApp());

    // Try to submit empty form
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    // Should show validation errors
    expect(find.text('Por favor, insira seu email'), findsOneWidget);
    expect(find.text('Por favor, insira sua senha'), findsOneWidget);
  });

  testWidgets('Email validation works', (WidgetTester tester) async {
    await tester.pumpWidget(const MainApp());

    // Enter invalid email
    await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    // Should show email validation error
    expect(find.text('Por favor, insira um email válido'), findsOneWidget);
  });
}