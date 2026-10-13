import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _totalRedes = 0;
  int _totalDispositivos = 0;
  int _cambiosHoy = 0;
  bool _isLoading = true;
  List<Map<String, String>> _notificaciones = [];

  @override
  void initState() {
    super.initState();
    _fetchRealData();
  }

  Future<void> _fetchRealData() async {
    setState(() => _isLoading = true);
    try {
      final redesRes = await Supabase.instance.client.from('redes').select();
      List dispRes = [];
      try {
        dispRes = await Supabase.instance.client.from('dispositivos').select();
      } catch (_) {
        dispRes = await Supabase.instance.client.from('devices').select();
      }

      final redesList = List<Map<String, dynamic>>.from(redesRes as List);
      final dispList = List<Map<String, dynamic>>.from(dispRes);

      // Calcular registros creados el día de hoy
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      int cambiosCount = 0;

      for (var r in redesList) {
        if (r['created_at'] != null) {
          final dt = DateTime.tryParse(r['created_at'].toString());
          if (dt != null && dt.isAfter(todayStart)) {
            cambiosCount++;
          }
        }
      }

      for (var d in dispList) {
        if (d['created_at'] != null) {
          final dt = DateTime.tryParse(d['created_at'].toString());
          if (dt != null && dt.isAfter(todayStart)) {
            cambiosCount++;
          }
        }
      }

      // Generar notificaciones dinámicas basadas en los datos reales
      List<Map<String, String>> notifs = [];

      final redesSinEquipos = redesList.where((r) {
        final id = r['id'];
        return !dispList.any((d) => d['red_id'] == id);
      }).toList();

      if (redesSinEquipos.isNotEmpty) {
        notifs.add({
          'titulo': 'Redes sin equipos asignados',
          'detalle': 'Hay ${redesSinEquipos.length} red(es) configurada(s) sin dispositivos vinculados.',
          'nivel': 'advertencia',
        });
      }

      if (dispList.isEmpty) {
        notifs.add({
          'titulo': 'Sin dispositivos en bitácora',
          'detalle': 'Aún no se han registrado equipos en la infraestructura.',
          'nivel': 'info',
        });
      } else {
        notifs.add({
          'titulo': 'Estado de Infraestructura',
          'detalle': 'Operando ${dispList.length} dispositivo(s) en ${redesList.length} segmento(s) de red.',
          'nivel': 'ok',
        });
      }

      setState(() {
        _totalRedes = redesList.length;
        _totalDispositivos = dispList.length;
        _cambiosHoy = cambiosCount;
        _notificaciones = notifs;
      });
    } catch (e) {
      debugPrint('Error al cargar datos del dashboard: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.email?.split('@').first ?? 'Administrador';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F3F9),
      // Se removió el AppBar interno para evitar que se duplique con el de HomeView
      body: RefreshIndicator(
        color: const Color(0xFF673AB7),
        onRefresh: _fetchRealData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Saludo e Identificación del Administrador
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
                  Container(
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
                ],
              ),
              const SizedBox(height: 20),

              // Métricas Principales
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
                  _buildMetricCard(Icons.hub, '$_totalRedes', 'Redes', const Color(0xFF6A1B9A)),
                  _buildMetricCard(Icons.devices, '$_totalDispositivos', 'Dispositivos', Colors.teal),
                  _buildMetricCard(Icons.admin_panel_settings, '1', 'Administrador', Colors.deepOrange),
                  _buildMetricCard(Icons.history, '$_cambiosHoy', 'Cambios Hoy', Colors.indigo),
                ],
              ),
              const SizedBox(height: 20),

              // SECCIÓN DE NOTIFICACIONES DEL SISTEMA
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
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Estado de la Red
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
                          _buildStatItem('$_totalRedes', 'Segmentos activos', const Color(0xFF6A1B9A)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Analítica de Disponibilidad
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

  static Widget _buildMetricCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
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