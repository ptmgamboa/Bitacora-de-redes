import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      appBar: AppBar(
        title: const Text('Agregar Nuevo Dispositivo'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre del Equipo / Servidor', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(labelText: 'Dirección IP', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _macController,
              decoration: const InputDecoration(labelText: 'Dirección MAC', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: _isLoading ? null : _saveDevice,
              icon: const Icon(Icons.save),
              label: Text(_isLoading ? 'Guardando...' : 'Guardar Dispositivo'),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}