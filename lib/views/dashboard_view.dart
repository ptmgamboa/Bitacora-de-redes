import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_colors.dart';
import '../services/supabase_service.dart';
import 'notifications_view.dart';

class DashboardView extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const DashboardView({super.key, this.onNavigateTab});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final _service = SupabaseService();

  int _totalRedes = 0;
  int _totalDispositivos = 0;
  int _cambiosHoy = 0;
  bool _isLoading = true;
  List<Map<String, String>> _notificaciones = [];
  List<Map<String, dynamic>> _detallesCambios = [];

  @override
  void initState() {
    super.initState();
    _fetchRealData();
  }

  Future<void> _fetchRealData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getDatosDashboard();
      final historial = List<Map<String, dynamic>>.from(data['ultimosCambios'] ?? []);

      List<Map<String, dynamic>> cambiosFormateados = [];
      for (var h in historial) {
        final tipoStr = h['tipo']?.toString() ?? '';

        IconData icono = Icons.history_rounded;
        Color color = AppColors.primary;

        if (tipoStr == 'red') {
          icono = Icons.hub_outlined;
          color = AppColors.secondary;
        } else if (tipoStr == 'dispositivo') {
          icono = Icons.devices_other;
          color = AppColors.statusActive;
        } else if (tipoStr == 'vlan') {
          icono = Icons.alt_route_rounded;
          color = AppColors.accent;
        }

        cambiosFormateados.add({
          'id': h['id']?.toString() ?? '',
          'titulo': h['titulo'] ?? 'Cambio Registrado',
          'usuario': h['usuario'] ?? 'Administrador',
          'detalle': h['detalle'] ?? '',
          'hora': h['hora'] ?? '--:--',
          'grupo': h['grupo'] ?? 'Anteriores',
          'icono': icono,
          'color': color,
        });
      }

      setState(() {
        _totalRedes = data['totalRedes'] ?? 0;
        _totalDispositivos = data['totalDispositivos'] ?? 0;
        _notificaciones = List<Map<String, String>>.from(data['notificaciones'] ?? []);
        _detallesCambios = cambiosFormateados;
        _cambiosHoy = data['cambiosHoy'] ?? 0;
      });
    } catch (e) {
      debugPrint('Error al cargar datos del dashboard: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _eliminarRegistro(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Borrar registro'),
        content: const Text('¿Deseas eliminar este evento del historial?'),
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
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteHistorialCambio(id);
        await _fetchRealData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registro eliminado del historial'),
              backgroundColor: AppColors.statusActive,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar registro: $e'),
              backgroundColor: AppColors.statusCritical,
            ),
          );
        }
      }
    }
  }

  void _mostrarModalCambiosHoy() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final grupos = _detallesCambios.map((e) => e['grupo']?.toString() ?? 'Anteriores').toSet().toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.65,
              minChildSize: 0.4,
              maxChildSize: 0.88,
              builder: (context, scrollController) {
                return Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.history_rounded, color: AppColors.primary, size: 24),
                          const SizedBox(width: 10),
                          const Text(
                            'Detalle de Cambios',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _detallesCambios.isEmpty
                            ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, size: 48, color: AppColors.textMuted),
                              const SizedBox(height: 8),
                              const Text(
                                'No hay registros o cambios en la bitácora.',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                            : ListView.builder(
                          controller: scrollController,
                          itemCount: grupos.length,
                          itemBuilder: (context, gIndex) {
                            final grupoNombre = grupos[gIndex];
                            final itemsDelGrupo = _detallesCambios.where((e) => e['grupo'] == grupoNombre).toList();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: grupoNombre == 'Hoy'
                                              ? AppColors.primary.withOpacity(0.12)
                                              : AppColors.background,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          grupoNombre.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: grupoNombre == 'Hoy' ? AppColors.primary : AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Expanded(child: Divider(color: AppColors.border, height: 1)),
                                    ],
                                  ),
                                ),

                                ...itemsDelGrupo.map((item) {
                                  final id = item['id']?.toString() ?? '';

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: (item['color'] as Color).withOpacity(0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(item['icono'] as IconData, color: item['color'] as Color, size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      item['titulo'] as String,
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Text(
                                                    item['hora'] as String,
                                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                item['detalle'] as String,
                                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                              ),
                                            ],
                                          ),
                                        ),

                                        if (id.isNotEmpty)
                                          IconButton(
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.only(left: 8),
                                            icon: const Icon(Icons.delete_outline, color: AppColors.statusCritical, size: 20),
                                            onPressed: () async {
                                              await _eliminarRegistro(id);
                                              setModalState(() {});
                                            },
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.email?.split('@').first ?? 'Administrador';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _fetchRealData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Hola, $userName!',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'ITSU · Infraestructura de red',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => widget.onNavigateTab?.call(5),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.admin_panel_settings_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            user?.email ?? 'Administrador',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const Text(
                'Resumen de Infraestructura',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),

              _isLoading
                  ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
                  : GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  _buildMetricCard(
                    Icons.hub_rounded,
                    '$_totalRedes',
                    'Redes',
                    AppColors.primary,
                    onTap: () => widget.onNavigateTab?.call(1),
                  ),
                  _buildMetricCard(
                    Icons.devices_rounded,
                    '$_totalDispositivos',
                    'Dispositivos',
                    AppColors.secondary,
                    onTap: () => widget.onNavigateTab?.call(2),
                  ),
                  _buildMetricCard(
                    Icons.admin_panel_settings_rounded,
                    '1',
                    'Administrador',
                    AppColors.accent,
                    onTap: () => widget.onNavigateTab?.call(5),
                  ),
                  _buildMetricCard(
                    Icons.history_rounded,
                    '$_cambiosHoy',
                    'Cambios Hoy',
                    AppColors.statusWarning,
                    onTap: _mostrarModalCambiosHoy,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // TARJETA DE NOTIFICACIONES DEL SISTEMA
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notifications_active_outlined, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Notificaciones del Sistema',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const NotificationsView()),
                              ).then((_) => _fetchRealData());
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '${_notificaciones.length}',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (_notificaciones.isEmpty)
                        const Text(
                          'No hay alertas pendientes.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        )
                      else
                        Column(
                          children: _notificaciones.map((n) {
                            Color colorIcon;
                            IconData iconData;

                            switch (n['nivel']) {
                              case 'advertencia':
                                colorIcon = AppColors.statusWarning;
                                iconData = Icons.warning_amber_rounded;
                                break;
                              case 'ok':
                                colorIcon = AppColors.statusActive;
                                iconData = Icons.check_circle_outline_rounded;
                                break;
                              default:
                                colorIcon = AppColors.secondary;
                                iconData = Icons.info_outline_rounded;
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const NotificationsView()),
                                  ).then((_) => _fetchRealData());
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colorIcon.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: colorIcon.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(iconData, color: colorIcon, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              n['titulo'] ?? '',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: colorIcon,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              n['detalle'] ?? '',
                                              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ESTADO Y DISPONIBILIDAD DE RED
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Estado actual de la red', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('$_totalDispositivos', 'Puntos totales', AppColors.textPrimary),
                          _buildStatItem('$_totalDispositivos', 'Operativos', AppColors.statusActive),
                          _buildStatItem('$_totalRedes', 'Redes activas', AppColors.primary),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Disponibilidad de Red', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 16),
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 120,
                              height: 120,
                              child: CircularProgressIndicator(
                                value: _totalDispositivos > 0 ? 1.0 : 0.0,
                                strokeWidth: 12,
                                backgroundColor: AppColors.border,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('$_totalDispositivos', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                const Text('activos', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                              ],
                            ),
                          ],
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
    );
  }

  static Widget _buildMetricCard(IconData icon, String value, String label, Color color, {VoidCallback? onTap}) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildStatItem(String val, String label, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }
}