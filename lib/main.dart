import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'login_screen.dart';
import 'home_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkSession()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Segura',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      // Validación reactiva: decide si muestra el Login o el Home según el estado de sesión
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          switch (authProvider.status) {
            case AuthStatus.checkingSession:
              return const _SessionStatusScreen(
                message: 'Comprobando sesión...',
              );
            case AuthStatus.error:
              return _SessionStatusScreen(
                message: authProvider.errorMessage ?? 'Error de sesión',
                onRetry: authProvider.retry,
              );
            case AuthStatus.authenticated:
              return const HomeScreen();
            case AuthStatus.unauthenticated:
            case AuthStatus.authenticating:
              return const LoginScreen();
          }
        },
      ),
    );
  }
}

class _SessionStatusScreen extends StatelessWidget {
  const _SessionStatusScreen({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onRetry == null)
                const CircularProgressIndicator(color: Color(0xFF00C9FF)),
              const SizedBox(height: 24),
              Text(message, style: const TextStyle(color: Colors.white)),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                TextButton(onPressed: onRetry, child: const Text('Reintentar')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
