import 'package:flutter/material.dart';

class SecurityView extends StatelessWidget {
  const SecurityView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguridad & Credenciales'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.lock_reset, color: Colors.deepPurple),
              title: const Text('Cambiar Contraseña'),
              subtitle: const Text('Actualiza tu clave de acceso a Supabase Auth'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Formulario para cambiar contraseña')),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.shield_outlined, color: Colors.deepPurple),
              title: const Text('Autenticación de Dos Factores (2FA)'),
              subtitle: const Text('Seguridad adicional para administradores'),
              trailing: Switch(
                value: true,
                activeColor: Colors.deepPurple,
                onChanged: (val) {},
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.phonelink_setup, color: Colors.deepPurple),
              title: const Text('Sesiones Activas'),
              subtitle: const Text('1 dispositivo activo actualmente'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}