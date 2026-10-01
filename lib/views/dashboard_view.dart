import 'package:flutter/material.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      appBar: AppBar(
        title: const Text('Panel de Control'),
        backgroundColor: const Color(0xFF673AB7),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Corregido: CrossAxisAlignment
          children: [
            // Saludo de bienvenida
            const Text(
              'Bienvenido de nuevo,',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const Text(
              'Administrador de Red',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 20),

            // Fila de tarjetas métricas
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Dispositivos Conectados',
                    value: '18',
                    subtitle: '14 activos',
                    icon: Icons.devices,
                    color: const Color(0xFF673AB7),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Registro de Red',
                    value: 'Sincronizado',
                    subtitle: 'Hace 2 min',
                    icon: Icons.history,
                    color: const Color(0xFF009688),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tarjeta de Alertas
            _buildMetricCard(
              title: 'Alertas Recientes',
              value: '0 Alertas Críticas',
              subtitle: 'Todos los sistemas operando con normalidad',
              icon: Icons.shield_outlined,
              color: Colors.indigo,
              isFullWidth: true,
            ),
            const SizedBox(height: 24),

            // Gráfico / Estadísticas de Uso
            const Text(
              'Uso de Datos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Ancho de Banda', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('85.4 Mbps', style: TextStyle(color: Color(0xFF673AB7), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: const LinearProgressIndicator(
                      value: 0.65,
                      minHeight: 10,
                      backgroundColor: Color(0xFFEDE7F6),
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF673AB7)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Descarga: 62.1 Mbps', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('Carga: 23.3 Mbps', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Corregido: CrossAxisAlignment
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ],
      ),
    );
  }
}