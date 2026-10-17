import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class DeviceDetailView extends StatefulWidget {
  final Map<String, dynamic> device;

  const DeviceDetailView({
    super.key,
    required this.device,
  });

  @override
  State<DeviceDetailView> createState() => _DeviceDetailViewState();
}

class _DeviceDetailViewState extends State<DeviceDetailView> {
  late Map<String, dynamic> _deviceData;

  @override
  void initState() {
    super.initState();
    _deviceData = Map<String, dynamic>.from(widget.device);
  }

  @override
  Widget build(BuildContext context) {
    final String nombre = _deviceData['nombre'] ?? _deviceData['name'] ?? 'Dispositivo sin nombre';
    final String ip = _deviceData['ip'] ?? _deviceData['ip_address'] ?? 'No asignada';
    final String mac = _deviceData['mac'] ?? _deviceData['mac_address'] ?? 'No registrada';
    final String tipo = _deviceData['tipo'] ?? _deviceData['type'] ?? 'General';
    final String estado = _deviceData['estado'] ?? _deviceData['status'] ?? 'Activo';
    final String ubicacion = _deviceData['ubicacion'] ?? _deviceData['location'] ?? 'No especificada';
    final String notas = _deviceData['notas'] ?? _deviceData['notes'] ?? 'Sin observaciones adicionales.';

    final bool isActivo = estado.toString().toLowerCase() != 'inactivo';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(nombre),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta Principal
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primary.withOpacity(0.12),
                      child: Icon(
                        _getDeviceIcon(tipo),
                        size: 30,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombre,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActivo ? AppColors.statusActiveBg : AppColors.statusCriticalBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isActivo ? 'Activo' : 'Inactivo',
                              style: TextStyle(
                                color: isActivo ? AppColors.statusActive : AppColors.statusCritical,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tarjeta de Detalle Técnico
            const Text(
              'Información de Red',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildDetailTile(
                    icon: Icons.numbers,
                    title: 'Dirección IP',
                    value: ip,
                  ),
                  const Divider(height: 1, indent: 56, color: AppColors.border),
                  _buildDetailTile(
                    icon: Icons.qr_code,
                    title: 'Dirección MAC',
                    value: mac,
                  ),
                  const Divider(height: 1, indent: 56, color: AppColors.border),
                  _buildDetailTile(
                    icon: Icons.category,
                    title: 'Tipo de Dispositivo',
                    value: tipo,
                  ),
                  const Divider(height: 1, indent: 56, color: AppColors.border),
                  _buildDetailTile(
                    icon: Icons.place,
                    title: 'Ubicación / Área',
                    value: ubicacion,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tarjeta de Notas u Observaciones
            const Text(
              'Notas u Observaciones',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.note_alt_outlined, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        notas,
                        style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      ),
    );
  }

  IconData _getDeviceIcon(String tipo) {
    final t = tipo.toLowerCase();
    if (t.contains('router') || t.contains('módem')) return Icons.router;
    if (t.contains('switch')) return Icons.developer_board;
    if (t.contains('server') || t.contains('servidor')) return Icons.dns;
    if (t.contains('printer') || t.contains('impresora')) return Icons.print;
    if (t.contains('laptop') || t.contains('pc') || t.contains('computadora')) return Icons.computer;
    return Icons.devices;
  }
}