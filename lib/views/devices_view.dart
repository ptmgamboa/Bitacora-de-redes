import 'package:flutter/material.dart';

class DevicesView extends StatelessWidget {
  const DevicesView({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> devices = [
      {'nombre': 'Servidor_Supabase_DB', 'ip': '192.168.1.50', 'mac': '70:EE:50:81:85:10', 'tipo': 'Servidor'},
      {'nombre': 'PC_Administrador_01', 'ip': '192.168.1.102', 'mac': '00:1A:2B:3C:4D:5E', 'tipo': 'Desktop'},
      {'nombre': 'Smartphone_Tecnico', 'ip': '192.168.1.115', 'mac': 'A4:C3:F0:12:34:56', 'tipo': 'Mobile'},
      {'nombre': 'Router_Central_Cisco', 'ip': '192.168.1.1', 'mac': 'CC:D2:E1:99:88:77', 'tipo': 'Router'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      appBar: AppBar(
        title: const Text('Dispositivos Conectados'),
        backgroundColor: const Color(0xFF673AB7),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: devices.length,
        itemBuilder: (context, index) {
          final dev = devices[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF009688).withOpacity(0.1),
                child: Icon(
                  dev['tipo'] == 'Mobile' ? Icons.phone_android : Icons.computer,
                  color: const Color(0xFF009688),
                ),
              ),
              title: Text(dev['nombre']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('IP: ${dev['ip']}\nMAC: ${dev['mac']}'),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }
}