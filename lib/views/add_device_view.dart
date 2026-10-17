import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_colors.dart';
import '../widgets/responsive_body.dart';

class AddDeviceView extends StatefulWidget {
  const AddDeviceView({super.key});

  @override
  State<AddDeviceView> createState() => _AddDeviceViewState();
}

class _AddDeviceViewState extends State<AddDeviceView> {
  final _nameController = TextEditingController();
  final _ipController = TextEditingController();
  final _macController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _saveDevice() async {
    if (_nameController.text.isEmpty || _ipController.text.isEmpty) {
      setState(() => _errorMessage = 'Nombre e IP son obligatorios');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final payload = {
      'name': _nameController.text.trim(),
      'ip': _ipController.text.trim(),
      'mac': _macController.text.trim(),
    };

    try {
      try {
        await Supabase.instance.client.from('dispositivos').insert(payload);
      } catch (_) {
        await Supabase.instance.client.from('devices').insert(payload);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Error al registrar: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Agregar Nuevo Dispositivo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: ResponsiveBody(
          maxWidth: 600,
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Equipo / Servidor',
                    prefixIcon: Icon(Icons.badge_outlined, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _ipController,
                  decoration: const InputDecoration(
                    labelText: 'Dirección IP',
                    prefixIcon: Icon(Icons.wifi, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _macController,
                  decoration: const InputDecoration(
                    labelText: 'Dirección MAC',
                    prefixIcon: Icon(Icons.lan_outlined, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isLoading ? null : _saveDevice,
                  icon: const Icon(Icons.save_rounded),
                  label: Text(_isLoading ? 'Guardando...' : 'Guardar Dispositivo'),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(_errorMessage!, style: const TextStyle(color: AppColors.statusCritical)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}