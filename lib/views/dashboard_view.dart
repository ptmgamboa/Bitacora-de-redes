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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRealData();
  }

  Future<void> _fetchRealData() async {
    setState(() => _isLoading = true);
    try {
      final redesRes = await Supabase.instance.client.from('redes').select('id');
      List dispRes = [];
      try {
        dispRes = await Supabase.instance.client.from('dispositivos').select('id');
      } catch (_) {
        dispRes = await Supabase.instance.client.from('devices').select('id');
      }

      setState(() {
        _totalRedes = (redesRes as List).length;
        _totalDispositivos = (dispRes as List).length;
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
    final userName = user?.email?.split('@').first ?? 'Usuario';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F3F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.hub, color: Color(0xFF6A1B9A), size: 20),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Bitacora.Net',
                  style: TextStyle(color: Color(0xFF2C143E), fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const Text('ITSU · Infraestructura de red', style: TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchRealData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Hola, $userName!',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C143E)),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  user?.email ?? 'Administrador',
                  style: const TextStyle(color: Color(0xFF6A1B9A), fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(height: 20),

              const Text('Resumen de Infraestructura', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1, // Solución al desbordamiento
                children: [
                  _buildMetricCard(Icons.hub, '$_totalRedes', 'Redes', const Color(0xFF6A1B9A)),
                  _buildMetricCard(Icons.devices, '$_totalDispositivos', 'Dispositivos', Colors.teal),
                  _buildMetricCard(Icons.people, '1', 'Usuarios', Colors.deepOrange),
                  _buildMetricCard(Icons.history, '5', 'Cambios Hoy', Colors.indigo),
                ],
              ),
              const SizedBox(height: 20),

              // Estado de la Red
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                          _buildStatItem('$_totalRedes', 'VLANs activas', const Color(0xFF6A1B9A)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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