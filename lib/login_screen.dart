import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  bool _showPassword = false;

  Future<void> _submit() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.status == AuthStatus.authenticating ||
        _formKey.currentState?.validate() != true) {
      return;
    }

    FocusScope.of(context).unfocus();
    final success = await authProvider.login(
      _userController.text.trim(),
      _passController.text,
    );
    if (!mounted) return;
    if (!success) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.removeCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
              authProvider.errorMessage ?? 'Usuario o contraseña incorrectos'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Container(
        // Fondo con un degradado moderno y elegante
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icono o Logo superior con brillo
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00C9FF), Color(0xFF92FE9D)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00C9FF).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      size: 48,
                      color: Color(0xFF16222A),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Título llamativo
                  const Text(
                    'Bienvenido de nuevo',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Inicia sesión para continuar',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Tarjeta central con estilo translúcido (Glassmorphism)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        children: [
                          // Campo de Usuario
                          TextFormField(
                            controller: _userController,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) =>
                                _passwordFocusNode.requestFocus(),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Ingresa tu usuario'
                                    : null,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Usuario',
                              errorStyle:
                                  const TextStyle(color: Color(0xFFFFCDD2)),
                              labelStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7)),
                              prefixIcon: const Icon(
                                  Icons.person_outline_rounded,
                                  color: Color(0xFF00C9FF)),
                              filled: true,
                              fillColor: Colors.black.withValues(alpha: 0.2),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                    color: Color(0xFF00C9FF), width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Campo de Contraseña
                          TextFormField(
                            controller: _passController,
                            focusNode: _passwordFocusNode,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            validator: (value) => value == null ||
                                    value.length < 6
                                ? 'La contraseña debe tener al menos 6 caracteres'
                                : null,
                            style: const TextStyle(color: Colors.white),
                            obscureText: !_showPassword,
                            enableSuggestions: false,
                            autocorrect: false,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              errorStyle:
                                  const TextStyle(color: Color(0xFFFFCDD2)),
                              suffixIcon: IconButton(
                                tooltip: _showPassword
                                    ? 'Ocultar contraseña'
                                    : 'Mostrar contraseña',
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: const Color(0xFF00C9FF),
                                ),
                                onPressed: () => setState(() {
                                  _showPassword = !_showPassword;
                                }),
                              ),
                              labelStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7)),
                              prefixIcon: const Icon(Icons.lock_outline_rounded,
                                  color: Color(0xFF00C9FF)),
                              filled: true,
                              fillColor: Colors.black.withValues(alpha: 0.2),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                    color: Color(0xFF00C9FF), width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Botón de Ingresar moderno
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00C9FF),
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 6,
                                shadowColor: const Color(0xFF00C9FF)
                                    .withValues(alpha: 0.5),
                              ),
                              onPressed: authProvider.status ==
                                      AuthStatus.authenticating
                                  ? null
                                  : _submit,
                              child: authProvider.status ==
                                      AuthStatus.authenticating
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.black87,
                                      ),
                                    )
                                  : const Text(
                                      'Ingresar',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
