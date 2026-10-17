import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_colors.dart';
import '../widgets/responsive_body.dart';

class AddNetworkView extends StatefulWidget {
  const AddNetworkView({super.key});

  @override
  State<AddNetworkView> createState() => _AddNetworkViewState();
}

class _AddNetworkViewState extends State<AddNetworkView> {
  final _nameController = TextEditingController();
  final _gatewayController = TextEditingController();
  final _typeController = TextEditingController();
  String _status = 'Activa';
  bool _isLoading = false;

  Future<void> _addNetwork() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.from('networks').insert({
        'name': _nameController.text.trim(),
        'gateway': _gatewayController.text.trim(),
        'type': _typeController.text.trim(),
        'status': _status,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Red "${_nameController.text}" registrada.'),
            backgroundColor: AppColors.statusActive,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar red: $e'),
            backgroundColor: AppColors.statusCritical,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Agregar Nueva Red'),
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
                    labelText: 'Nombre de la Red',
                    hintText: 'Ej. Red_Sistemas_Uruapan',
                    prefixIcon: Icon(Icons.lan, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _gatewayController,
                  decoration: const InputDecoration(
                    labelText: 'Gateway IP',
                    hintText: 'Ej. 192.168.10.1',
                    prefixIcon: Icon(Icons.dns, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _typeController,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Red',
                    hintText: 'Ej. Wi-Fi Corporativo / Ethernet LAN',
                    prefixIcon: Icon(Icons.category, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(
                    labelText: 'Estado Inicial',
                    prefixIcon: Icon(Icons.bar_chart, color: AppColors.primary),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Activa', child: Text('Activa')),
                    DropdownMenuItem(value: 'Inactiva', child: Text('Inactiva')),
                    DropdownMenuItem(value: 'Mantenimiento', child: Text('Mantenimiento')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _status = val);
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _addNetwork,
                    icon: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                        : const Icon(Icons.add_rounded),
                    label: Text(_isLoading ? 'Guardando...' : 'Registrar Red'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}