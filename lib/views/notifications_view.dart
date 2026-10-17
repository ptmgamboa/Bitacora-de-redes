import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_colors.dart';
import '../services/supabase_service.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  final _service = SupabaseService();
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  List<Map<String, String>> _notificaciones = [];

  @override
  void initState() {
    super.initState();
    _cargarNotificaciones();
  }

  Future<void> _cargarNotificaciones() async {
    setState(() => _isLoading = true);
    try {
      // 1. Obtener notificaciones calculadas por el sistema (alertas de redes vacías, etc.)
      final data = await _service.getDatosDashboard();
      final notifCalculadas = List<Map<String, String>>.from(data['notificaciones'] ?? []);

      // 2. Intentar obtener notificaciones registradas en la tabla de Supabase
      List<Map<String, String>> notifDB = [];
      try {
        final res = await _supabase
            .from('notificaciones')
            .select()
            .order('created_at', ascending: false);

        for (var item in res) {
          notifDB.add({
            'id': item['id']?.toString() ?? '',
            'titulo': item['titulo'] ?? 'Aviso del sistema',
            'detalle': item['mensaje'] ?? item['detalle'] ?? '',
            'nivel': item['tipo'] ?? 'info',
            'leida': (item['leida'] ?? false).toString(),
          });
        }
      } catch (_) {
        // Si no existe la tabla o está vacía, no interrumpe el flujo
      }

      // 3. Unificar ambas listas
      final unificadas = [...notifCalculadas, ...notifDB];

      if (mounted) {
        setState(() {
          _notificaciones = unificadas;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar notificaciones unificadas: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _clearAllNotifications() async {
    try {
      await _supabase.from('notificaciones').delete().neq('id', 0);
      await _cargarNotificaciones();
    } catch (e) {
      debugPrint('Error al limpiar notificaciones: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Limpiar notificaciones',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('Limpiar notificaciones'),
                  content: const Text('¿Deseas eliminar las notificaciones registradas?'),
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
                      child: const Text('Limpiar'),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _cargarNotificaciones,
        child: _notificaciones.isEmpty
            ? SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_off_outlined,
                    size: 56,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Sin notificaciones',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'No tienes alertas o avisos pendientes en este momento.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _notificaciones.length,
          itemBuilder: (context, index) {
            final notif = _notificaciones[index];
            final nivel = notif['nivel'] ?? 'info';
            final leida = notif['leida'] == 'true';

            Color colorIcon = AppColors.primary;
            IconData iconData = Icons.info_outline_rounded;

            if (nivel == 'advertencia' || nivel == 'warning') {
              colorIcon = AppColors.statusWarning;
              iconData = Icons.warning_amber_rounded;
            } else if (nivel == 'ok') {
              colorIcon = AppColors.statusActive;
              iconData = Icons.check_circle_outline_rounded;
            } else if (nivel == 'error') {
              colorIcon = AppColors.statusCritical;
              iconData = Icons.error_outline_rounded;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: leida ? AppColors.border : colorIcon.withOpacity(0.4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: CircleAvatar(
                  backgroundColor: colorIcon.withOpacity(0.12),
                  child: Icon(iconData, color: colorIcon, size: 22),
                ),
                title: Text(
                  notif['titulo'] ?? 'Aviso del sistema',
                  style: TextStyle(
                    fontWeight: leida ? FontWeight.normal : FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  notif['detalle'] ?? '',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                trailing: !leida
                    ? Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colorIcon,
                    shape: BoxShape.circle,
                  ),
                )
                    : null,
                onTap: () async {
                  final id = notif['id'];
                  if (id != null && id.isNotEmpty && !leida) {
                    try {
                      await _supabase
                          .from('notificaciones')
                          .update({'leida': true})
                          .eq('id', id);
                      _cargarNotificaciones();
                    } catch (_) {}
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }
}