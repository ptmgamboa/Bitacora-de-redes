import 'package:flutter/material.dart';
import '../models/network_model.dart';
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

  // Cargar redes desde Supabase
  Future<void> _cargarRedes() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getRedes();
      final redes = data.map((e) => NetworkModel.fromJson(e)).toList();
      setState(() {
        _allNetworks = redes;
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
      // Se eliminó el appBar interno para que no se duplique el título
      body: Column(
        children: [
          // --- BARRA DE BÚSQUEDA ---
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

          // --- LISTA DE REDES O ESTADOS ---
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
                : ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: 4.0),
              itemCount: _filteredNetworks.length,
              itemBuilder: (context, index) {
                final r = _filteredNetworks[index];

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
                      children: [
                        // Ícono Principal de Red
                        Container(
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
                        const SizedBox(width: 14),

                        // Información de la Red
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.nombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Badge con el Segmento de Red
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDF2F7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.lan_outlined,
                                      size: 14,
                                      color: Color(0xFF4A5568),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          r.segmento,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'monospace',
                                            color: Color(0xFF2D3748),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Acciones (Editar / Eliminar)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
                              icon: const Icon(Icons.edit_outlined,
                                  color: Colors.blueAccent, size: 22),
                              onPressed: () => _mostrarFormulario(r),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
                              icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                  size: 22),
                              onPressed: () =>
                                  _eliminarRed(r.id, r.nombre),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // --- BOTÓN FLOTANTE ---
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

// --- FORMULARIO EMERGENTE PARA REDES ---
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