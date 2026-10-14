import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'login_view.dart';
import 'security_view.dart';
import 'server_view.dart';
import 'notifications_view.dart';
import 'support_view.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  Future<void> _cerrarSesion(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas salir de la bitácora?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
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
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Color(0xFF673AB7),
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 10),
          const Text(
            'Administrador de Red',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Text(
            'admin@bitacora.com',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.shield, color: Color(0xFF673AB7)),
              title: const Text('Seguridad & Credenciales'),
              subtitle: const Text('Conectado a Supabase Auth'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SecurityView()),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.dns, color: Color(0xFF673AB7)),
              title: const Text('Servidor Supabase'),
              subtitle: const Text('Estado: En Línea (Sincronizado)'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ServerView()),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications, color: Color(0xFF673AB7)),
              title: const Text('Notificaciones de Alertas'),
              subtitle: const Text('Activadas'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationsView()),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.help_outline, color: Color(0xFF673AB7)),
              title: const Text('Soporte Técnico'),
              subtitle: const Text('Manual de la Bitácora'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SupportView()),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: Colors.red.shade50,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.red.shade200),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Salir de la cuenta actual'),
              onTap: () => _cerrarSesion(context),
            ),
          ),
        ],
      ),
    );
  }
}