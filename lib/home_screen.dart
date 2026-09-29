import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _accessCamera(BuildContext context) async {
    var status = await Permission.camera.request();

    if (status.isGranted) {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      
      if (image != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Imagen capturada: ${image.name}!'),
            backgroundColor: Colors.teal.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permiso de cámara denegado'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Panel Seguro',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
              tooltip: 'Cerrar Sesión',
              onPressed: () {
                authProvider.logout();
              },
            ),
          )
        ],
      ),
      body: Container(
        // Fondo con un degradado moderno y elegante (Tonos oscuros y profesionales)
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
                  // Avatar superior con efecto de brillo moderno
                  Container(
                    padding: const EdgeInsets.all(4),
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
                    child: const CircleAvatar(
                      radius: 48,
                      backgroundColor: Color(0xFF16222A),
                      child: Icon(Icons.security_rounded, size: 50, color: Color(0xFF00C9FF)),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Tarjeta central con estilo Glassmorphism (translúcida)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          '¡Bienvenido,\n${authProvider.userName}!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Insignia de estado cifrado
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_person_rounded, size: 16, color: Colors.greenAccent),
                              SizedBox(width: 8),
                              Text(
                                'Sesión Activa y Encriptada',
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        if (kDebugMode && authProvider.debugTokenPreview != null) ...[
                          Text(
                            'Token (debug): ${authProvider.debugTokenPreview}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Vence: ${authProvider.sessionExpiresAt!.toLocal().toString().split('.').first}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Botón principal de la cámara con diseño moderno
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00C9FF),
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 8,
                              shadowColor: const Color(0xFF00C9FF).withValues(alpha: 0.4),
                            ),
                            onPressed: () => _accessCamera(context),
                            icon: const Icon(Icons.camera_alt_rounded, size: 22),
                            label: const Text(
                              'Usar Cámara del Dispositivo',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
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
