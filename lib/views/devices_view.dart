import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _confirmarEliminar(DeviceModel d) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Eliminar Dispositivo'),
          ],
        ),
        content: Text('¿Deseas eliminar el dispositivo "${d.nombre}" (${d.ip})? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _service.deleteDispositivo(d.id);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dispositivo eliminado correctamente'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1565C0);

    return Column(
      children: [
        // Buscador superior estilizado
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Buscar por IP, MAC, Nombre o Fabricante',
              prefixIcon: const Icon(Icons.search_rounded, color: primaryBlue),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 20),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() => _searchQuery = '');
                },
              )
                  : null,
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),

        // Listado de dispositivos
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _service.buscarDispositivos(_searchQuery),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.devices_other_rounded, size: 48, color: Colors.grey.shade400),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isEmpty
                            ? 'No hay dispositivos registrados.'
                            : 'No se encontraron resultados.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              final dispositivos = snapshot.data!.map((e) => DeviceModel.fromJson(e)).toList();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                itemCount: dispositivos.length,
                itemBuilder: (context, index) {
                  final d = dispositivos[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Icono distintivo tipo tarjeta
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: primaryBlue.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.computer_rounded, color: primaryBlue, size: 24),
                          ),
                          const SizedBox(width: 14),

                          // Información del dispositivo
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: primaryBlue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        d.ip,
                                        style: const TextStyle(
                                          color: primaryBlue,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        d.redNombre ?? "Sin Red",
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'MAC: ${d.mac}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Botones de acción
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: primaryBlue, size: 20),
                                tooltip: 'Editar',
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => _DeviceFormDialog(
                                      dispositivo: d,
                                      onSaved: () => setState(() {}),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                tooltip: 'Eliminar',
                                onPressed: () => _confirmarEliminar(d),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Botón inferior para agregar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => _DeviceFormDialog(
                  dispositivo: null,
                  onSaved: () => setState(() {}),
                ),
              );
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Agregar Dispositivo'),
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

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _macCtrl.dispose();
    _fabCtrl.dispose();
    _ubicaCtrl.dispose();
    _ipCtrl.dispose();
    super.dispose();
  }

  void _cargarRedes() async {
    final res = await SupabaseService().getRedes();
    if (mounted) {
      setState(() {
        _redesDisponibles = res.map((e) => NetworkModel.fromJson(e)).toList();
        _isLoading = false;
      });
    }
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate() || _selectedRedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete todos los campos requeridos'),
          behavior: SnackBarBehavior.floating,
        ),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar (¿MAC o IP duplicada?)'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1565C0);

    if (_isLoading) {
      return const AlertDialog(
        content: SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
      );
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Row(
        children: [
          Icon(
            widget.dispositivo == null ? Icons.add_to_queue_rounded : Icons.edit_note_rounded,
            color: primaryBlue,
          ),
          const SizedBox(width: 8),
          Text(
            widget.dispositivo == null ? 'Nuevo Dispositivo' : 'Editar Dispositivo',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre del Dispositivo'),
                validator: Validators.requerido,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ipCtrl,
                decoration: const InputDecoration(labelText: 'Dirección IPv4'),
                validator: Validators.validarIPv4,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _macCtrl,
                decoration: const InputDecoration(labelText: 'MAC (XX:XX:XX:XX:XX:XX)'),
                validator: Validators.validarMAC,
                inputFormatters: [
                  MacAddressFormatter(),
                  LengthLimitingTextInputFormatter(17),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fabCtrl,
                decoration: const InputDecoration(labelText: 'Fabricante'),
                validator: Validators.requerido,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ubicaCtrl,
                decoration: const InputDecoration(labelText: 'Ubicación'),
                validator: Validators.requerido,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: _selectedRedId,
                decoration: const InputDecoration(labelText: 'Red Asociada'),
                items: _redesDisponibles.map((red) {
                  return DropdownMenuItem(
                    value: red.id ?? '',
                    child: Text(
                      '${red.nombre ?? "Sin nombre"} (${red.segmento ?? "Sin segmento"})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedRedId = val),
                validator: (val) => val == null || val.isEmpty ? 'Seleccione una red' : null,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.all(16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        SizedBox(
          width: 110,
          child: ElevatedButton(
            onPressed: _guardar,
            child: const Text('Guardar'),
          ),
        ),
      ],
    );
  }
}

class MacAddressFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (oldValue.text.length >= newValue.text.length) {
      return newValue.copyWith(text: newValue.text.toUpperCase());
    }

    var text = newValue.text.replaceAll(':', '').toUpperCase();
    var buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 2 == 0 && nonZeroIndex != 12) {
        buffer.write(':');
      }
    }

    var string = buffer.toString();

    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}