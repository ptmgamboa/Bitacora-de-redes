import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class SecurityView extends StatefulWidget {
  const SecurityView({super.key});

  @override
  State<SecurityView> createState() => _SecurityViewState();
}

class _SecurityViewState extends State<SecurityView> {
  bool _is2FAEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Seguridad & Credenciales'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          _buildSecurityCard(
            icon: Icons.lock_reset_rounded,
            title: 'Cambiar Contraseña',
            subtitle: 'Actualiza tu clave de acceso a Supabase Auth',
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Acción enviada. Revisa tu correo electrónico para restablecer la contraseña.'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildSecurityCard(
            icon: Icons.shield_outlined,
            title: 'Autenticación de Dos Factores (2FA)',
            subtitle: 'Seguridad adicional para cuentas administradoras',
            trailing: Switch(
              value: _is2FAEnabled,
              activeColor: AppColors.primary,
              onChanged: (val) {
                setState(() => _is2FAEnabled = val);
              },
            ),
          ),
          const SizedBox(height: 12),
          _buildSecurityCard(
            icon: Icons.phonelink_setup_rounded,
            title: 'Sesiones Activas',
            subtitle: '1 dispositivo conectado actualmente',
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}