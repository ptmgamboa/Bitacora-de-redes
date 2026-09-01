import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../services/supabase_service.dart';
import '../models/network_model.dart';
import '../core/validators.dart';
import 'package:flutter/services.dart';

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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Buscar (IP, MAC, Nombre, Fabricante)',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 16.0),
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
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.devices_other, size: 64, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No hay dispositivos registrados.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }
              final dispositivos = snapshot.data!.map((e) => DeviceModel.fromJson(e)).toList();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: dispositivos.length,
                itemBuilder: (context, index) {
                  final d = dispositivos[index];
                  return Card(
                    elevation: 1.5,
                    margin: const EdgeInsets.only(bottom: 10.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(Icons.computer, color: Theme.of(context).colorScheme.onPrimaryContainer),
                      ),
                      title: Text(
                        d.nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          '${d.ip} • ${d.redNombre ?? "Sin Red"}\nMAC: ${d.mac}',
                          style: const TextStyle(height: 1.3),
                        ),
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () async {
                          await _service.deleteDispositivo(d.id);
                          setState(() {}); // Refrescar vista
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => _DeviceFormDialog(
                    dispositivo: null, // Soluciona la advertencia del parámetro opcional
                    onSaved: () => setState(() {}),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Agregar Dispositivo', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete todos los campos correctamente')),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar (¿MAC duplicada?)')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AlertDialog(
        content: SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
      );
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      title: Text(widget.dispositivo == null ? 'Nuevo Dispositivo' : 'Editar Dispositivo'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                validator: Validators.requerido,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ipCtrl,
                decoration: const InputDecoration(labelText: 'Dirección IPv4', border: OutlineInputBorder()),
                validator: Validators.validarIPv4,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _macCtrl,
                decoration: const InputDecoration(labelText: 'MAC (XX:XX:XX:XX:XX:XX)', border: OutlineInputBorder()),
                validator: Validators.validarMAC,
                inputFormatters: [
                  MacAddressFormatter(),
                  LengthLimitingTextInputFormatter(17), // Limita exactamente a 17 caracteres
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fabCtrl,
                decoration: const InputDecoration(labelText: 'Fabricante', border: OutlineInputBorder()),
                validator: Validators.requerido,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ubicaCtrl,
                decoration: const InputDecoration(labelText: 'Ubicación', border: OutlineInputBorder()),
                validator: Validators.requerido,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true, // Obliga al menú a respetar el ancho de la pantalla
                value: _selectedRedId,
                decoration: const InputDecoration(labelText: 'Red Asociada', border: OutlineInputBorder()),
                items: _redesDisponibles.map((red) {
                  return DropdownMenuItem(
                    value: red.id ?? '',
                    child: Text(
                      '${red.nombre ?? "Sin nombre"} (${red.segmento ?? "Sin segmento"})',
                      overflow: TextOverflow.ellipsis, // Agrega "..." si el texto es muy largo
                    ),
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
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
          onPressed: _guardar,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
class MacAddressFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {

    // 1. Si el usuario está borrando, permitimos que lo haga normalmente
    if (oldValue.text.length >= newValue.text.length) {
      return newValue.copyWith(text: newValue.text.toUpperCase());
    }

    // 2. Limpiamos los dos puntos previos y forzamos mayúsculas
    var text = newValue.text.replaceAll(':', '').toUpperCase();
    var buffer = StringBuffer();

    // 3. Reconstruimos el texto agregando ':' cada 2 caracteres
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      // Agregamos ':' si es par y no hemos llegado al límite (12 caracteres)
      if (nonZeroIndex % 2 == 0 && nonZeroIndex != 12) {
        buffer.write(':');
      }
    }

    var string = buffer.toString();

    return newValue.copyWith(
      text: string,
      // Mueve el cursor automáticamente al final
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}