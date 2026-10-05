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
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Diálogo de confirmación para eliminar
  Future<void> _eliminarDispositivo(dynamic id, String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Dispositivo'),
        content: Text('¿Estás seguro de que deseas eliminar "$nombre"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteDispositivo(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dispositivo eliminado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {}); // Refresca la lista
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar dispositivo: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _abrirFormulario([DeviceModel? d]) {
    showDialog(
      context: context,
      builder: (context) => _DeviceFormDialog(
        dispositivo: d,
        onSaved: () => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF673AB7);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      // Se eliminó el appBar interno para que no se duplique el título
      body: Column(
        children: [
          // --- BARRA DE BÚSQUEDA ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por IP, MAC, Nombre o Fabricante...',
                prefixIcon: const Icon(Icons.search, color: primaryColor),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () => _searchCtrl.clear(),
                )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // --- LISTA DE DISPOSITIVOS ---
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _service.buscarDispositivos(_searchQuery),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Error al cargar dispositivos: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.devices_other, size: 70, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No hay dispositivos registrados.'
                              : 'No se encontraron coincidencias.',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                final dispositivos =
                snapshot.data!.map((e) => DeviceModel.fromJson(e)).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  itemCount: dispositivos.length,
                  itemBuilder: (context, index) {
                    final d = dispositivos[index];
                    final redNombre = (d.redNombre != null && d.redNombre!.isNotEmpty)
                        ? d.redNombre!
                        : 'Sin Red';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Ícono principal
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.computer,
                                color: primaryColor,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Detalles del dispositivo
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Nombre del dispositivo
                                  Text(
                                    d.nombre,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // IP y Red
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _buildBadge(
                                        icon: Icons.wifi,
                                        text: d.ip,
                                        bgColor: primaryColor.withOpacity(0.08),
                                        textColor: primaryColor,
                                      ),
                                      _buildBadge(
                                        icon: Icons.alt_route,
                                        text: redNombre,
                                        bgColor: Colors.blue.withOpacity(0.1),
                                        textColor: Colors.blue.shade800,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // MAC, Fabricante y Ubicación
                                  Text(
                                    'MAC: ${d.mac}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  if (d.fabricante.isNotEmpty || d.ubicacion.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        '${d.fabricante} • ${d.ubicacion}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Botones de acción (Editar / Eliminar)
                            Column(
                              children: [
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(6),
                                  icon: const Icon(Icons.edit_outlined,
                                      color: Colors.blueAccent, size: 22),
                                  onPressed: () => _abrirFormulario(d),
                                ),
                                const SizedBox(height: 4),
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(6),
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.redAccent, size: 22),
                                  onPressed: () => _eliminarDispositivo(d.id, d.nombre),
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
        ],
      ),

      // --- BOTÓN FLOTANTE ---
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'btn_devices_view_fab',
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Agregar Dispositivo', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  // Widget auxiliar para crear pequeñas etiquetas visuales
  Widget _buildBadge({
    required IconData icon,
    required String text,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
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
  bool _isSaving = false;

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

  Future<void> _cargarRedes() async {
    try {
      final res = await SupabaseService().getRedes();
      if (mounted) {
        setState(() {
          _redesDisponibles = res.map((e) => NetworkModel.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate() || _selectedRedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, completa todos los campos requeridos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

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
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF673AB7);

    if (_isLoading) {
      return const AlertDialog(
        content: SizedBox(
          height: 120,
          child: Center(
            child: CircularProgressIndicator(color: primaryColor),
          ),
        ),
      );
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      title: Row(
        children: [
          const Icon(Icons.devices, color: primaryColor),
          const SizedBox(width: 8),
          Text(widget.dispositivo == null ? 'Nuevo Dispositivo' : 'Editar Dispositivo'),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del dispositivo',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: Validators.requerido,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ipCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dirección IPv4',
                    prefixIcon: Icon(Icons.numbers),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: Validators.validarIPv4,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _macCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dirección MAC (XX:XX:XX:XX:XX:XX)',
                    prefixIcon: Icon(Icons.lan_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: Validators.validarMAC,
                  inputFormatters: [
                    MacAddressFormatter(),
                    LengthLimitingTextInputFormatter(17),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fabCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Fabricante',
                    prefixIcon: Icon(Icons.precision_manufacturing_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: Validators.requerido,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ubicaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ubicación / Oficina',
                    prefixIcon: Icon(Icons.place_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: Validators.requerido,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _selectedRedId,
                  decoration: const InputDecoration(
                    labelText: 'Red Asociada',
                    prefixIcon: Icon(Icons.router_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  items: _redesDisponibles.map((red) {
                    return DropdownMenuItem(
                      value: red.id,
                      child: Text(
                        '${red.nombre} (${red.segmento})',
                        overflow: TextOverflow.ellipsis,
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        _isSaving
            ? const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
          ),
        )
            : ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          ),
          onPressed: _guardar,
          child: Text(widget.dispositivo == null ? 'Guardar' : 'Actualizar'),
        ),
      ],
    );
  }
}

// Formateador automático para direcciones MAC
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