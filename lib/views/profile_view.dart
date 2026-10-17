import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_colors.dart';
import '../services/supabase_service.dart';
import 'login_view.dart';
import 'security_view.dart';
import 'server_view.dart';
import 'notifications_view.dart';
import 'support_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  int _unreadNotifCount = 0;

  @override
  void initState() {
    super.initState();
    _cargarNotificacionesNoLeidas();
  }

  Future<void> _cargarNotificacionesNoLeidas() async {
    try {
      final res = await Supabase.instance.client
          .from('notificaciones')
          .select('id')
          .eq('leida', false);

      if (mounted) {
        setState(() {
          _unreadNotifCount = (res as List).length;
        });
      }
    } catch (_) {}
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas salir de la bitácora?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusCritical,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SupabaseService().logout();

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginView()),
              (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = Supabase.instance.client.auth.currentUser?.email ?? 'admin@bitacora.com';
    final userName = userEmail.split('@').first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // BANNER DEL USUARIO
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: const Icon(Icons.person, size: 46, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  'Administrador: $userName',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  userEmail,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // OPCIONES DE CONFIGURACIÓN
          _buildOptionCard(
            context,
            icon: Icons.shield_outlined,
            title: 'Seguridad & Credenciales',
            subtitle: 'Conectado a Supabase Auth',
            targetPage: const SecurityView(),
          ),
          _buildOptionCard(
            context,
            icon: Icons.dns_outlined,
            title: 'Servidor Supabase',
            subtitle: 'Estado: En Línea (Sincronizado)',
            targetPage: const ServerView(),
          ),
          _buildOptionCard(
            context,
            icon: Icons.notifications_none_rounded,
            title: 'Notificaciones de Alertas',
            subtitle: _unreadNotifCount > 0
                ? '$_unreadNotifCount alerta(s) sin leer'
                : 'Sistema al día',
            badgeCount: _unreadNotifCount,
            targetPage: const NotificationsView(),
          ),
          _buildOptionCard(
            context,
            icon: Icons.help_outline_rounded,
            title: 'Soporte Técnico',
            subtitle: 'Manual de la Bitácora',
            targetPage: const SupportView(),
          ),

          const SizedBox(height: 12),

          // BOTÓN CERRAR SESIÓN
          Container(
            decoration: BoxDecoration(
              color: AppColors.statusCriticalBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.statusCritical.withOpacity(0.3)),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.statusCritical),
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: AppColors.statusCritical, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Salir de la cuenta actual', style: TextStyle(fontSize: 12)),
              onTap: () => _cerrarSesion(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Widget targetPage,
        int badgeCount = 0,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badgeCount > 0)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.statusCritical,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => targetPage)).then((_) {
            _cargarNotificacionesNoLeidas();
          });
        },
      ),
    );
  }
}