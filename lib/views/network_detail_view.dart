import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NetworkDetailView extends StatefulWidget {
  final dynamic id;
  final String initialName;
  final String initialGateway;
  final String initialType;
  final String initialStatus;

  const NetworkDetailView({
    super.key,
    required this.id,
    required this.initialName,
    required this.initialGateway,
    required this.initialType,
    required this.initialStatus,
  });

  @override
  State<NetworkDetailView> createState() => _NetworkDetailViewState();
}

class _NetworkDetailViewState extends State<NetworkDetailView> {
  late TextEditingController _nameController;
  late TextEditingController _gatewayController;
  late TextEditingController _typeController;
  late String _status;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _gatewayController = TextEditingController(text: widget.initialGateway);
    _typeController = TextEditingController(text: widget.initialType);
    _status = widget.initialStatus;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gatewayController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  Future<void> _updateNetwork() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.from('networks').update({
        'name': _nameController.text.trim(),
        'gateway': _gatewayController.text.trim(),
        'type': _typeController.text.trim(),
        'status': _status,
      }).eq('id', widget.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Red actualizada en Supabase.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configurar: ${widget.initialName}'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la Red / SSID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.wifi),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _gatewayController,
              decoration: const InputDecoration(
                labelText: 'Puerta de Enlace (Gateway)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.router),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _typeController,
              decoration: const InputDecoration(
                labelText: 'Tipo de Red',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.merge_type),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Estado de la Red',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.bar_chart),
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
                onPressed: _isLoading ? null : _updateNetwork,
                icon: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Icon(Icons.save),
                label: Text(_isLoading ? 'Guardando...' : 'Guardar Cambios'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}