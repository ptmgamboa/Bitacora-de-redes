import 'package:flutter/material.dart';

class NetworksView extends StatelessWidget {
  const NetworksView({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> networks = [
      {'ssid': 'Red_Principal_Uruapan', 'ip': '192.168.1.1', 'tipo': 'Wi-Fi Corporativo', 'estado': 'Activa'},
      {'ssid': 'Lan_Administracion', 'ip': '10.0.0.1', 'tipo': 'Ethernet LAN', 'estado': 'Activa'},
      {'ssid': 'Red_Invitados', 'ip': '172.16.0.1', 'tipo': 'Wi-Fi Visitantes', 'estado': 'Inactiva'},
      {'ssid': 'Servidores_Backend', 'ip': '10.0.10.1', 'tipo': 'Fibra Óptica', 'estado': 'Activa'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      appBar: AppBar(
        title: const Text('Bitácora de Redes'),
        backgroundColor: const Color(0xFF673AB7),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar red o IP...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF673AB7)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Lista de redes
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: networks.length,
              itemBuilder: (context, index) {
                final net = networks[index];
                final isActiva = net['estado'] == 'Activa';
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF673AB7).withOpacity(0.1),
                      child: const Icon(Icons.lan, color: Color(0xFF673AB7)),
                    ),
                    title: Text(
                      net['ssid']!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, // Corregido: CrossAxisAlignment
                      children: [
                        const SizedBox(height: 4),
                        Text('Gateway: ${net['ip']}'),
                        Text('Tipo: ${net['tipo']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActiva ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        net['estado']!,
                        style: TextStyle(
                          color: isActiva ? Colors.green[700] : Colors.red[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}