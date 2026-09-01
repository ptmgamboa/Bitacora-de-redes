import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../services/supabase_service.dart';
import '../models/network_model.dart';
import '../core/validators.dart';

class DevicesView extends StatefulWidget {
  const DevicesView({super.key});

  @override
  State<DevicesView> createState() => _DevicesViewState();
}

class _DevicesViewState extends State<DevicesView> {
  final _service = SupabaseService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Buscar (IP, MAC, Nombre, Fabricante)',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _service.buscarDispositivos(_searchQuery),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No hay dispositivos.'));
              }
              final dispositivos = snapshot.data!.map((e) => DeviceModel.fromJson(e)).toList();

              return ListView.builder(
                itemCount: dispositivos.length,
                itemBuilder: (context, index) {
                  final d = dispositivos[index];
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.computer)),
                    title: Text(d.nombre),
                    subtitle: Text('${d.ip} - ${d.redNombre ?? "Sin Red"}\nMAC: ${d.mac}'),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await _service.deleteDispositivo(d.id);
                        setState(() {}); // Refrescar vista
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => _DeviceFormDialog(
                      dispositivo: null, // Soluciona la advertencia del parámetro opcional
                      onSaved: () => setState(() {})
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Agregar Dispositivo')
          ),
        )
      ],
    );
  }
}

// --- FORMULARIO EMERGENTE PARA DISPOSITIVOS ---
class _DeviceFormDialog extends StatefulWidget {
  final DeviceModel? dispositivo;
  final VoidCallback onSaved;

  const _DeviceFormDialog({this.dispositivo, required this.onSaved});

  @override
  State<_DeviceFormDialog> createState() => _DeviceFormDialogState();
}

class _DeviceFormDialogState extends State<_DeviceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _macCtrl = TextEditingController();
  final _fabCtrl = TextEditingController();
  final _ubicaCtrl = TextEditingController();
  final _ipCtrl = TextEditingController();

  String? _selectedRedId;
  List<NetworkModel> _redesDisponibles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarRedes();
    if (widget.dispositivo != null) {
      _nombreCtrl.text = widget.dispositivo!.nombre;
      _macCtrl.text = widget.dispositivo!.mac;
      _fabCtrl.text = widget.dispositivo!.fabricante;
      _ubicaCtrl.text = widget.dispositivo!.ubicacion;
      _ipCtrl.text = widget.dispositivo!.ip;
      _selectedRedId = widget.dispositivo!.redId;
    }
  }

  void _cargarRedes() async {
    final res = await SupabaseService().getRedes();
    setState(() {
      _redesDisponibles = res.map((e) => NetworkModel.fromJson(e)).toList();
      _isLoading = false;
    });
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate() || _selectedRedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complete todos los campos correctamente')));
      return;
    }
    setState(() => _isLoading = true);

    final data = {
      'nombre': _nombreCtrl.text.trim(),
      'mac': _macCtrl.text.trim().toUpperCase(),
      'fabricante': _fabCtrl.text.trim(),
      'ubicacion': _ubicaCtrl.text.trim(),
      'ip': _ipCtrl.text.trim(),
      'red_id': _selectedRedId,
    };

    try {
      if (widget.dispositivo == null) {
        await SupabaseService().addDispositivo(data);
      } else {
        await SupabaseService().updateDispositivo(widget.dispositivo!.id, data);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // Corrección del BuildContext asíncrono
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al guardar (¿MAC duplicada?)')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const AlertDialog(content: SizedBox(height: 100, child: Center(child: CircularProgressIndicator())));

    return AlertDialog(
      title: Text(widget.dispositivo == null ? 'Nuevo Dispositivo' : 'Editar Dispositivo'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: _nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre'), validator: Validators.requerido),
              TextFormField(
                controller: _ipCtrl,
                decoration: const InputDecoration(labelText: 'Dirección IPv4'),
                validator: Validators.validarIPv4,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              TextFormField(controller: _macCtrl, decoration: const InputDecoration(labelText: 'MAC (XX:XX:XX:XX:XX:XX)'), validator: Validators.validarMAC),
              TextFormField(controller: _fabCtrl, decoration: const InputDecoration(labelText: 'Fabricante'), validator: Validators.requerido),
              TextFormField(controller: _ubicaCtrl, decoration: const InputDecoration(labelText: 'Ubicación'), validator: Validators.requerido),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRedId,
                decoration: const InputDecoration(labelText: 'Red Asociada', border: OutlineInputBorder()),
                items: _redesDisponibles.map((red) {
                  // Corrección de propiedades anulables
                  return DropdownMenuItem(
                      value: red.id ?? '',
                      child: Text('${red.nombre ?? "Sin nombre"} (${red.segmento ?? "Sin segmento"})')
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedRedId = val),
                validator: (val) => val == null || val.isEmpty ? 'Seleccione una red' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }
}