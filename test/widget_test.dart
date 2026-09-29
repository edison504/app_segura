import 'package:app_segura/auth_provider.dart';
import 'package:app_segura/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class MemorySessionStorage implements SessionStorage {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

void main() {
  testWidgets('El login valida longitud y credenciales antes de entrar',
      (tester) async {
    final storage = MemorySessionStorage();
    final auth = AuthProvider(storage: storage);
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: auth,
      child: const MaterialApp(home: LoginScreen()),
    ));

    await tester.enterText(find.byType(TextField).at(0), 'edison');
    await tester.enterText(find.byType(TextField).at(1), '12345');
    await tester.tap(find.text('Ingresar'));
    await tester.pump();
    expect(find.text('La contraseña debe tener al menos 6 caracteres'),
        findsOneWidget);
    expect(auth.isAuthenticated, isFalse);

    await tester.enterText(find.byType(TextField).at(1), 'equivocada');
    await tester.tap(find.text('Ingresar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Usuario o contraseña incorrectos'), findsOneWidget);
    expect(auth.isAuthenticated, isFalse);

    await tester.enterText(find.byType(TextField).at(1), 'Edison123');
    await tester.tap(find.text('Ingresar'));
    await tester.pump();
    expect(auth.isAuthenticated, isTrue);
    expect(storage.values['session_token'], isNotEmpty);
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
  });

  testWidgets('La sesión se recupera y vence tras cinco minutos',
      (tester) async {
    final storage = MemorySessionStorage();
    var now = DateTime.utc(2026, 9, 28, 12);
    final auth = AuthProvider(storage: storage, now: () => now);
    expect(await auth.login('nicolas', 'Nicolas123'), isTrue);
    expect(auth.userName, 'Nicolas');
    auth.dispose();

    final restored = AuthProvider(storage: storage, now: () => now);
    await restored.checkSession();
    expect(restored.isAuthenticated, isTrue);
    expect(restored.userName, 'Nicolas');

    now = now.add(const Duration(minutes: 5));
    await tester.pump(const Duration(minutes: 5));
    await tester.pump();
    expect(restored.isAuthenticated, isFalse);
    expect(storage.values, isEmpty);
    restored.dispose();
  });

  testWidgets('Una sesión caducada no se restaura al reabrir', (tester) async {
    final storage = MemorySessionStorage();
    var now = DateTime.utc(2026, 9, 28, 12);
    final auth = AuthProvider(storage: storage, now: () => now);
    expect(await auth.login('edison', 'Edison123'), isTrue);
    auth.dispose();

    now = now.add(const Duration(minutes: 6));
    final reopened = AuthProvider(storage: storage, now: () => now);
    await reopened.checkSession();
    expect(reopened.isAuthenticated, isFalse);
    expect(storage.values, isEmpty);
    reopened.dispose();
  });
}
