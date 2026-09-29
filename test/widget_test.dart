import 'dart:async';

import 'package:app_segura/auth_provider.dart';
import 'package:app_segura/auth_service.dart';
import 'package:app_segura/home_screen.dart';
import 'package:app_segura/login_screen.dart';
import 'package:app_segura/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class MemorySessionStorage implements SessionStorage {
  final values = <String, String>{};
  Completer<void>? waitForRead;
  Completer<void>? waitForWrite;
  bool failReads = false;
  bool failWrites = false;
  bool failDeletes = false;

  @override
  Future<String?> read(String key) async {
    if (waitForRead != null) await waitForRead!.future;
    if (failReads) throw StateError('No se puede leer');
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (waitForWrite != null) await waitForWrite!.future;
    if (failWrites) throw StateError('No se puede guardar');
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    if (failDeletes) throw StateError('No se puede eliminar');
    values.remove(key);
  }
}

void main() {
  test('El servicio comprueba las cuentas y persiste un token temporal',
      () async {
    final storage = MemorySessionStorage();
    var now = DateTime.utc(2026, 9, 28, 12);
    final service = AuthService(storage: storage, now: () => now);

    expect(await service.login('edison', 'incorrecta'), isNull);
    expect(storage.values, isEmpty);
    final session = await service.login(' EDISON ', 'Edison123');
    expect(session?.username, 'edison');
    expect(session?.token, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(session?.expiresAt, now.add(const Duration(minutes: 5)));
    expect(storage.values['session_token'], session?.token);
    expect((await service.restoreSession())?.token, session?.token);

    now = now.add(const Duration(minutes: 5));
    expect(await service.restoreSession(), isNull);
    expect(storage.values, isEmpty);
    final nextSession = await service.login('nicolas', 'Nicolas123');
    expect(nextSession?.token, isNot(session?.token));
    await service.logout();
    expect(storage.values, isEmpty);
  });

  testWidgets('El login valida longitud y credenciales antes de entrar',
      (tester) async {
    final storage = MemorySessionStorage();
    final auth = AuthProvider(service: AuthService(storage: storage));
    await auth.checkSession();
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

  testWidgets('El panel muestra solamente una parte del token en debug',
      (tester) async {
    final storage = MemorySessionStorage();
    final auth = AuthProvider(service: AuthService(storage: storage));
    await auth.checkSession();
    expect(await auth.login('edison', 'Edison123'), isTrue);
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: auth,
      child: const MaterialApp(home: HomeScreen()),
    ));

    expect(
        find.text('Token (debug): ${auth.debugTokenPreview}'), findsOneWidget);
    expect(find.textContaining('Vence: '), findsOneWidget);
    expect(find.textContaining(storage.values['session_token']!), findsNothing);
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
  });

  testWidgets('La sesión se recupera y vence tras cinco minutos',
      (tester) async {
    final storage = MemorySessionStorage();
    var now = DateTime.utc(2026, 9, 28, 12);
    final auth = AuthProvider(
      service: AuthService(storage: storage, now: () => now),
      now: () => now,
    );
    await auth.checkSession();
    expect(await auth.login('nicolas', 'Nicolas123'), isTrue);
    expect(auth.userName, 'Nicolas');
    auth.dispose();

    final restored = AuthProvider(
      service: AuthService(storage: storage, now: () => now),
      now: () => now,
    );
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
    final auth = AuthProvider(
      service: AuthService(storage: storage, now: () => now),
      now: () => now,
    );
    await auth.checkSession();
    expect(await auth.login('edison', 'Edison123'), isTrue);
    auth.dispose();

    now = now.add(const Duration(minutes: 6));
    final reopened = AuthProvider(
      service: AuthService(storage: storage, now: () => now),
      now: () => now,
    );
    await reopened.checkSession();
    expect(reopened.isAuthenticated, isFalse);
    expect(storage.values, isEmpty);
    reopened.dispose();
  });

  testWidgets('La app espera la lectura de sesión antes de mostrar el login',
      (tester) async {
    final storage = MemorySessionStorage()..waitForRead = Completer<void>();
    final auth = AuthProvider(service: AuthService(storage: storage));
    final checking = auth.checkSession();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: auth,
      child: const MyApp(),
    ));
    expect(find.text('Comprobando sesión...'), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);

    storage.waitForRead!.complete();
    await checking;
    await tester.pump();
    expect(find.byType(LoginScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
  });

  testWidgets('El botón se bloquea mientras persiste la sesión',
      (tester) async {
    final storage = MemorySessionStorage();
    final auth = AuthProvider(service: AuthService(storage: storage));
    await auth.checkSession();
    storage.waitForWrite = Completer<void>();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: auth,
      child: const MaterialApp(home: LoginScreen()),
    ));
    await tester.enterText(find.byType(TextField).at(0), 'edison');
    await tester.enterText(find.byType(TextField).at(1), 'Edison123');
    await tester.tap(find.text('Ingresar'));
    await tester.pump();
    expect(auth.status, AuthStatus.authenticating);
    expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    storage.waitForWrite!.complete();
    await tester.pump();
    expect(auth.status, AuthStatus.authenticated);
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
  });

  testWidgets('Una falla al leer la sesión permite reintentar', (tester) async {
    final storage = MemorySessionStorage()..failReads = true;
    final auth = AuthProvider(service: AuthService(storage: storage));
    await auth.checkSession();
    expect(auth.status, AuthStatus.error);
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: auth,
      child: const MyApp(),
    ));
    expect(find.text('Reintentar'), findsOneWidget);

    storage.failReads = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(LoginScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
  });

  testWidgets('Un error al guardar deja el login disponible', (tester) async {
    final storage = MemorySessionStorage();
    final auth = AuthProvider(service: AuthService(storage: storage));
    await auth.checkSession();
    storage.failWrites = true;
    expect(await auth.login('edison', 'Edison123'), isFalse);
    expect(auth.status, AuthStatus.unauthenticated);
    expect(auth.errorMessage, 'No se pudo iniciar sesión. Inténtalo de nuevo.');
    expect(storage.values, isEmpty);
    auth.dispose();
  });

  testWidgets('Al fallar el cierre se reintenta borrar la sesión',
      (tester) async {
    final storage = MemorySessionStorage();
    final auth = AuthProvider(service: AuthService(storage: storage));
    await auth.checkSession();
    expect(await auth.login('nicolas', 'Nicolas123'), isTrue);
    storage.failDeletes = true;
    await auth.logout();
    expect(auth.status, AuthStatus.error);
    expect(storage.values['session_token'], isNotNull);

    storage.failDeletes = false;
    await auth.retry();
    expect(auth.status, AuthStatus.unauthenticated);
    expect(storage.values, isEmpty);
    auth.dispose();
  });
}
