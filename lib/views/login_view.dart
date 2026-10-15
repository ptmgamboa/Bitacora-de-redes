import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/supabase_service.dart';
import 'home_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await SupabaseService().login(_emailCtrl.text.trim(), _passCtrl.text.trim());
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeView()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Revise sus credenciales de acceso'),
            backgroundColor: AppColors.statusCritical,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarDialogoRecuperacion() {
    final resetEmailCtrl = TextEditingController(text: _emailCtrl.text.trim());
    final resetFormKey = GlobalKey<FormState>();
    bool isSending = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.lock_reset_rounded, color: AppColors.primary),
                SizedBox(width: 10),
                Text('Recuperar Acceso', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Form(
              key: resetFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ingrese su correo registrado para recibir las instrucciones de restablecimiento.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: resetEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo Electrónico',
                      prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                    ),
                    validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Ingrese su correo' : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
              ),
              isSending
                  ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              )
                  : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  if (!resetFormKey.currentState!.validate()) return;
                  setDialogState(() => isSending = true);

                  try {
                    await SupabaseService().resetPassword(resetEmailCtrl.text.trim());
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Enlace de recuperación enviado a su correo'),
                          backgroundColor: AppColors.statusActive,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    setDialogState(() => isSending = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: AppColors.statusCritical,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Enviar Enlace'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Fondo Superior en Gradiente Corporativo
          Container(
            height: MediaQuery.of(context).size.height * 0.38,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ÍCONO DE BRANDING CON GLOW
                      Container(
                        width: 100,
                        height: 100,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.hub_rounded,
                            size: 48,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // TÍTULO Y SUBTÍTULO
                      const Text(
                        'Bitacora.Net',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Administración de Infraestructura de Red',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // TARJETA DE FORMULARIO
                      Container(
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Iniciar Sesión',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Campo Correo Electrónico
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Correo Electrónico',
                                hintText: 'ejemplo@itsu.edu.mx',
                                prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                              ),
                              validator: (val) =>
                              val == null || val.trim().isEmpty ? 'Ingrese su correo' : null,
                            ),
                            const SizedBox(height: 16),

                            // Campo Contraseña
                            TextFormField(
                              controller: _passCtrl,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                hintText: '••••••••',
                                prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppColors.textSecondary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (val) =>
                              val == null || val.trim().isEmpty ? 'Ingrese su contraseña' : null,
                            ),
                            const SizedBox(height: 8),

                            // Olvidaste tu contraseña
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _mostrarDialogoRecuperacion,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 30),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  '¿Olvidaste tu contraseña?',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Botón Iniciar Sesión
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _iniciarSesion,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 2,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                                    : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Ingresar al Sistema', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_rounded, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      Text(
                        '© 2026 Instituto Tecnológico Superior de Uruapan',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}