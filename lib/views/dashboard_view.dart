import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

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
        Color color = Colors.indigo;

        if (tipoStr == 'red') {
          icono = Icons.hub_outlined;
          color = const Color(0xFF6A1B9A);
        } else if (tipoStr == 'dispositivo') {
          icono = Icons.devices_other;
          color = Colors.teal;
        } else if (tipoStr == 'vlan') {
          icono = Icons.alt_route_rounded;
          color = Colors.deepOrange;
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
        title: const Text('Borrar registro'),
        content: const Text('¿Deseas eliminar este evento del historial?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
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
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar registro: $e'),
              backgroundColor: const Color(0xFFD32F2F),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.history_rounded, color: Colors.indigo, size: 24),
                          const SizedBox(width: 10),
                          const Text(
                            'Detalle de Cambios',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
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
                              Icon(Icons.check_circle_outline, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text(
                                'No hay registros o cambios en la bitácora.',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
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
                                // ENCABEZADO DE GRUPO (HOY, AYER, FECHA)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: grupoNombre == 'Hoy'
                                              ? const Color(0xFF673AB7).withOpacity(0.12)
                                              : Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          grupoNombre.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: grupoNombre == 'Hoy' ? const Color(0xFF673AB7) : Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(child: Divider(color: Colors.grey.shade300, height: 1)),
                                    ],
                                  ),
                                ),

                                // ELEMENTOS DEL GRUPO
                                ...itemsDelGrupo.map((item) {
                                  final id = item['id']?.toString() ?? '';

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: (item['color'] as Color).withOpacity(0.1),
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
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Text(
                                                    item['hora'] as String,
                                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                item['detalle'] as String,
                                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // BOTÓN BORRAR EVENTO INDIVIDUAL
                                        if (id.isNotEmpty)
                                          IconButton(
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.only(left: 8),
                                            icon: const Icon(Icons.delete_outline, color: Color(0xFFD32F2F), size: 20),
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
      backgroundColor: const Color(0xFFF6F3F9),
      body: RefreshIndicator(
        color: const Color(0xFF673AB7),
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
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C143E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'ITSU · Infraestructura de red',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => widget.onNavigateTab?.call(5),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E5F5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.admin_panel_settings, size: 16, color: Color(0xFF6A1B9A)),
                          const SizedBox(width: 4),
                          Text(
                            user?.email ?? 'Administrador',
                            style: const TextStyle(
                              color: Color(0xFF6A1B9A),
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              _isLoading
                  ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(color: Color(0xFF673AB7)),
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
                    Icons.hub,
                    '$_totalRedes',
                    'Redes',
                    const Color(0xFF6A1B9A),
                    onTap: () => widget.onNavigateTab?.call(1),
                  ),
                  _buildMetricCard(
                    Icons.devices,
                    '$_totalDispositivos',
                    'Dispositivos',
                    Colors.teal,
                    onTap: () => widget.onNavigateTab?.call(2),
                  ),
                  _buildMetricCard(
                    Icons.admin_panel_settings,
                    '1',
                    'Administrador',
                    Colors.deepOrange,
                    onTap: () => widget.onNavigateTab?.call(5),
                  ),
                  _buildMetricCard(
                    Icons.history,
                    '$_cambiosHoy',
                    'Cambios Hoy',
                    Colors.indigo,
                    onTap: _mostrarModalCambiosHoy,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // NOTIFICACIONES INTERACTIVAS
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notifications_active_outlined, color: Color(0xFF6A1B9A), size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Notificaciones del Sistema',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E5F5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_notificaciones.length}',
                              style: const TextStyle(
                                color: Color(0xFF6A1B9A),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (_notificaciones.isEmpty)
                        const Text(
                          'No hay alertas pendientes.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        )
                      else
                        Column(
                          children: _notificaciones.map((n) {
                            Color colorIcon;
                            IconData iconData;

                            switch (n['nivel']) {
                              case 'advertencia':
                                colorIcon = Colors.amber.shade800;
                                iconData = Icons.warning_amber_rounded;
                                break;
                              case 'ok':
                                colorIcon = Colors.green.shade700;
                                iconData = Icons.check_circle_outline_rounded;
                                break;
                              default:
                                colorIcon = Colors.blue.shade700;
                                iconData = Icons.info_outline_rounded;
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap: () {
                                  if (n['nivel'] == 'advertencia' || (n['titulo']?.contains('Redes') ?? false)) {
                                    widget.onNavigateTab?.call(1);
                                  } else if (n['titulo']?.contains('dispositivos') ?? false) {
                                    widget.onNavigateTab?.call(2);
                                  }
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
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
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
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Estado actual de la red', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('$_totalDispositivos', 'Puntos totales', Colors.black87),
                          _buildStatItem('$_totalDispositivos', 'Operativos', Colors.green),
                          _buildStatItem('$_totalRedes', 'Redes activas', const Color(0xFF6A1B9A)),
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
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Disponibilidad de Red', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
                                strokeWidth: 14,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6A1B9A)),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('$_totalDispositivos', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                const Text('activos', style: TextStyle(color: Colors.grey, fontSize: 11)),
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
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
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}