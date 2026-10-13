import 'package:flutter/material.dart';
import '../models/network_model.dart';
import '../models/device_model.dart';
import '../services/supabase_service.dart';
import '../core/validators.dart';

class NetworksView extends StatefulWidget {
  const NetworksView({super.key});

  @override
  State<NetworksView> createState() => _NetworksViewState();
}

class _NetworksViewState extends State<NetworksView> {
  final _service = SupabaseService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  List<NetworkModel> _allNetworks = [];
  List<NetworkModel> _filteredNetworks = [];
  Map<String, List<DeviceModel>> _networkDevices = {};

  @override
  void initState() {
    super.initState();
    _cargarRedes();
    _searchController.addListener(_filtrarRedes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Cargar redes y dispositivos asociados desde Supabase
  Future<void> _cargarRedes() async {
    setState(() => _isLoading = true);
    try {
      final redesData = await _service.getRedes();
      final redes = redesData.map((e) => NetworkModel.fromJson(e)).toList();

      final dispData = await _service.buscarDispositivos('');
      final dispositivos = dispData.map((e) => DeviceModel.fromJson(e)).toList();

      Map<String, List<DeviceModel>> mapaDispositivos = {};
      for (var d in dispositivos) {
        if (!mapaDispositivos.containsKey(d.redId)) {
          mapaDispositivos[d.redId] = [];
        }
        mapaDispositivos[d.redId]!.add(d);
      }

      setState(() {
        _allNetworks = redes;
        _networkDevices = mapaDispositivos;
        _filtrarRedes();
      });
    } catch (e) {
      _mostrarSnackBar('Error al cargar redes: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Filtrado dinámico en tiempo real
  void _filtrarRedes() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredNetworks = List.from(_allNetworks);
      } else {
        _filteredNetworks = _allNetworks.where((red) {
          final nombre = red.nombre.toLowerCase();
          final segmento = red.segmento.toLowerCase();
          return nombre.contains(query) || segmento.contains(query);
        }).toList();
      }
    });
  }

  void _mostrarFormulario([NetworkModel? red]) {
    showDialog(
      context: context,
      builder: (context) => _NetworkFormDialog(
        red: red,
        onSaved: _cargarRedes,
      ),
    );
  }

  Future<void> _eliminarRed(dynamic id, String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Red'),
        content: Text('¿Estás seguro de que deseas eliminar la red "$nombre"?'),
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
      setState(() => _isLoading = true);
      try {
        await _service.deleteRed(id);
        _mostrarSnackBar('Red eliminada correctamente');
        _cargarRedes();
      } catch (e) {
        _mostrarSnackBar('Error al eliminar: $e', isError: true);
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarSnackBar(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF673AB7);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      body: Column(
        children: [
          // BARRA DE BÚSQUEDA
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o segmento...',
                prefixIcon: const Icon(Icons.search, color: primaryColor),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () => _searchController.clear(),
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

          // LISTA DE REDES CON DISPOSITIVOS DESPLEGABLES
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(color: primaryColor),
            )
                : _filteredNetworks.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off_rounded,
                      size: 70, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    _searchController.text.isEmpty
                        ? 'No hay redes registradas.'
                        : 'No se encontraron resultados.',
                    style: TextStyle(
                        fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  if (_searchController.text.isEmpty)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      onPressed: () => _mostrarFormulario(),
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar primera red'),
                    )
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _cargarRedes,
              color: primaryColor,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 4.0),
                itemCount: _filteredNetworks.length,
                itemBuilder: (context, index) {
                  final r = _filteredNetworks[index];
                  final dispositivos = _networkDevices[r.id] ?? [];

                  // Detección del Switch Principal
                  DeviceModel? switchPrincipal;
                  try {
                    switchPrincipal = dispositivos.firstWhere((d) => d.esSwitch);
                  } catch (_) {
                    switchPrincipal = null;
                  }

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
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.all(16.0),
                        childrenPadding: const EdgeInsets.only(
                            left: 16.0, right: 16.0, bottom: 16.0),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.router_outlined,
                            color: primaryColor,
                            size: 28,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                r.nombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            // Contador de dispositivos
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${dispositivos.length} disp.',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Badge de Segmento CIDR
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDF2F7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.lan_outlined,
                                      size: 13,
                                      color: Color(0xFF4A5568),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      r.segmento,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'monospace',
                                        color: Color(0xFF2D3748),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Muestra el Switch Principal si existe
                              if (switchPrincipal != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.alt_route_rounded,
                                      size: 14,
                                      color: Colors.indigo,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Switch Core: ${switchPrincipal.nombre} (${switchPrincipal.ip})',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.indigo,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(4),
                              icon: const Icon(Icons.edit_outlined,
                                  color: Colors.blueAccent, size: 20),
                              onPressed: () => _mostrarFormulario(r),
                            ),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(4),
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.redAccent, size: 20),
                              onPressed: () => _eliminarRed(r.id, r.nombre),
                            ),
                          ],
                        ),
                        children: [
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Dispositivos Conectados (${dispositivos.length})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (dispositivos.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'No hay dispositivos asociados a esta red.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            )
                          else
                            Column(
                              children: dispositivos.map((d) {
                                final isSwitch = d.esSwitch;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isSwitch
                                        ? Colors.indigo.withOpacity(0.05)
                                        : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSwitch
                                          ? Colors.indigo.withOpacity(0.3)
                                          : Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        d.icono,
                                        size: 20,
                                        color: d.colorTipo,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  d.nombre,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                if (isSwitch) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: Colors.indigo,
                                                      borderRadius:
                                                      BorderRadius.circular(6),
                                                    ),
                                                    child: const Text(
                                                      'SWITCH PRINCIPAL',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 9,
                                                        fontWeight:
                                                        FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            Text(
                                              'IP: ${d.ip}  •  MAC: ${d.mac}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade700,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'btn_networks_view_fab',
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        onPressed: () => _mostrarFormulario(),
        icon: const Icon(Icons.add),
        label: const Text(
          'Nueva Red',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// FORMULARIO EMERGENTE PARA REDES
class _NetworkFormDialog extends StatefulWidget {
  final NetworkModel? red;
  final VoidCallback onSaved;

  const _NetworkFormDialog({this.red, required this.onSaved});

  @override
  State<_NetworkFormDialog> createState() => _NetworkFormDialogState();
}

class _NetworkFormDialogState extends State<_NetworkFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _segmentoCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.red != null) {
      _nombreCtrl.text = widget.red!.nombre;
      _segmentoCtrl.text = widget.red!.segmento;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _segmentoCtrl.dispose();
    super.dispose();
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = {
      'nombre': _nombreCtrl.text.trim(),
      'segmento': _segmentoCtrl.text.trim(),
    };

    try {
      if (widget.red == null) {
        await SupabaseService().addRed(data);
      } else {
        await SupabaseService().updateRed(widget.red!.id, data);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar red: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF673AB7);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      title: Row(
        children: [
          const Icon(Icons.hub_outlined, color: primaryColor),
          const SizedBox(width: 8),
          Text(widget.red == null ? 'Nueva Red' : 'Editar Red'),
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
                    labelText: 'Nombre de la Red',
                    hintText: 'Ej. Administrativa, Visitantes',
                    prefixIcon: Icon(Icons.label_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  validator: Validators.requerido,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _segmentoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Segmento CIDR',
                    hintText: 'Ej. 192.168.1.0/24',
                    prefixIcon: Icon(Icons.lan_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  validator: Validators.validarRed,
                  keyboardType: TextInputType.datetime,
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
        _isLoading
            ? const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: primaryColor),
          ),
        )
            : ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          onPressed: _guardar,
          child: Text(widget.red == null ? 'Guardar' : 'Actualizar'),
        ),
      ],
    );
  }
}