import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
          SnackBar(content: Text('Red "${_nameController.text}" registrada.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar red: $e'), backgroundColor: Colors.red),
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
        title: const Text('Agregar Nueva Red'),
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
                labelText: 'Nombre de la Red',
                hintText: 'Ej. Red_Sistemas_Uruapan',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lan),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _gatewayController,
              decoration: const InputDecoration(
                labelText: 'Gateway IP',
                hintText: 'Ej. 192.168.10.1',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.dns),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _typeController,
              decoration: const InputDecoration(
                labelText: 'Tipo de Red',
                hintText: 'Ej. Wi-Fi Corporativo / Ethernet LAN',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Estado Inicial',
                border: OutlineInputBorder(),
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
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Icon(Icons.add),
                label: Text(_isLoading ? 'Guardando...' : 'Registrar Red'),
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