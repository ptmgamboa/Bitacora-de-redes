import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> _fetchNotifications() async {
    try {
      final res = await _supabase
          .from('notificaciones')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      // Si no existe la tabla o está vacía, retorna lista vacía
      return [];
    }
  }

  Future<void> _clearAllNotifications() async {
    try {
      await _supabase.from('notificaciones').delete().neq('id', 0);
      setState(() {});
    } catch (e) {
      debugPrint('Error al limpiar notificaciones: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const purpleColor = Color(0xFF6A1B9A);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F3F9),
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: purpleColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Limpiar notificaciones',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Limpiar notificaciones'),
                  content: const Text('¿Deseas eliminar todas las notificaciones?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Limpiar', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await _clearAllNotifications();
              }
            },
          )
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: purpleColor));
          }

          final notifications = snapshot.data ?? [];

          // ESTADO VACÍO DINÁMICO
          if (notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3E5F5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_off_outlined,
                        size: 64,
                        color: purpleColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Sin notificaciones',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C143E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No tienes alertas o avisos pendientes en este momento.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }

          // LISTA DE NOTIFICACIONES REALES
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final isRead = notif['leida'] ?? false;
              final tipo = notif['tipo'] ?? 'info';

              Color iconColor = purpleColor;
              IconData iconData = Icons.info_outline;

              if (tipo == 'warning') {
                iconColor = Colors.amber.shade800;
                iconData = Icons.warning_amber_rounded;
              } else if (tipo == 'error') {
                iconColor = Colors.red;
                iconData = Icons.error_outline;
              }

              return Card(
                elevation: isRead ? 0 : 2,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isRead ? Colors.grey.shade200 : purpleColor.withOpacity(0.4),
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: iconColor.withOpacity(0.12),
                    child: Icon(iconData, color: iconColor),
                  ),
                  title: Text(
                    notif['titulo'] ?? 'Aviso del sistema',
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      color: const Color(0xFF2C143E),
                    ),
                  ),
                  subtitle: Text(notif['mensaje'] ?? ''),
                  trailing: !isRead
                      ? Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: purpleColor,
                      shape: BoxShape.circle,
                    ),
                  )
                      : null,
                  onTap: () async {
                    if (!isRead) {
                      await _supabase
                          .from('notificaciones')
                          .update({'leida': true})
                          .eq('id', notif['id']);
                      setState(() {});
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}