import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/network_model.dart';
import '../models/device_model.dart';
import '../services/supabase_service.dart';

class NetworksView extends StatefulWidget {
  const NetworksView({super.key});

  @override
  State<NetworksView> createState() => _NetworksViewState();
}

class _NetworksViewState extends State<NetworksView> {
  final _service = SupabaseService();
  final TextEditingController _searchCtrl = TextEditingController();

  bool _isLoading = true;
  List<NetworkModel> _todasLasRedes = [];
  List<NetworkModel> _redesFiltradas = [];
  Map<String, List<DeviceModel>> _mapaDispositivos = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.toLowerCase().trim();
        _filtrarRedes();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final redesData = await _service.getRedes();
      final redes = redesData.map((e) => NetworkModel.fromJson(e)).toList();

      final dispData = await _service.buscarDispositivos('');
      final dispositivos = dispData.map((e) => DeviceModel.fromJson(e)).toList();

      Map<String, List<DeviceModel>> mapa = {};
      for (var d in dispositivos) {
        if (d.redId != null) {
          mapa.putIfAbsent(d.redId!, () => []).add(d);
        }
      }

      setState(() {
        _todasLasRedes = redes;
        _mapaDispositivos = mapa;
        _filtrarRedes();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar redes: $e'),
            backgroundColor: AppColors.statusCritical,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filtrarRedes() {
    if (_searchQuery.isEmpty) {
      _redesFiltradas = List.from(_todasLasRedes);
    } else {
      _redesFiltradas = _todasLasRedes.where((r) {
        return r.nombre.toLowerCase().contains(_searchQuery) ||
            r.segmento.toLowerCase().contains(_searchQuery) ||
            r.vlan.toLowerCase().contains(_searchQuery);
      }).toList();
    }
  }

  Future<void> _toggleEstadoRed(NetworkModel red) async {
    final nuevoEstado = (red.estado == 'Activa') ? 'Inactiva' : 'Activa';
    try {
      await _service.updateRed(red.id, {'estado': nuevoEstado});
      _cargarDatos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Red "${red.nombre}" marcada como $nuevoEstado'),
            backgroundColor: nuevoEstado == 'Activa' ? AppColors.statusActive : AppColors.statusWarning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar estado: $e'),
            backgroundColor: AppColors.statusCritical,
          ),
        );
      }
    }
  }

  Future<void> _eliminarRed(NetworkModel red) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Red'),
        content: Text('¿Deseas eliminar la red "${red.nombre}" (${red.segmento})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusCritical,
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
        await _service.deleteRed(red.id);
        _cargarDatos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Red eliminada correctamente'),
              backgroundColor: AppColors.statusActive,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar red: $e'),
              backgroundColor: AppColors.statusCritical,
            ),
          );
        }
      }
    }
  }

  // --- ABRIR FORMULARIO CREAR / EDITAR RED ---
  void _abrirFormulario([NetworkModel? red]) {
    showDialog(
      context: context,
      builder: (context) => _NetworkFormDialog(
        red: red,
        onSaved: () => _cargarDatos(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // --- BARRA DE BÚSQUEDA ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por Nombre, Segmento CIDR o VLAN...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                  onPressed: () => _searchCtrl.clear(),
                )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.0),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.0),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),

          // --- LISTADO DE REDES ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _redesFiltradas.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hub_outlined, size: 70, color: AppColors.textSecondary.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  Text(
                    _searchQuery.isEmpty ? 'No hay redes registradas.' : 'No se encontraron coincidencias.',
                    style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _abrirFormulario(),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Primera Red'),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _cargarDatos,
              color: AppColors.primary,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                itemCount: _redesFiltradas.length,
                itemBuilder: (context, index) {
                  final red = _redesFiltradas[index];
                  final esActiva = red.estado == 'Activa';
                  final equipos = _mapaDispositivos[red.id] ?? [];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    decoration: BoxDecoration(
                      color: esActiva ? AppColors.surface : AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.hub_rounded,
                                color: esActiva ? AppColors.secondary : AppColors.textSecondary,
                                size: 24,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  red.nombre,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: esActiva ? AppColors.textPrimary : AppColors.textSecondary,
                                    decoration: esActiva ? null : TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () => _toggleEstadoRed(red),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: esActiva ? AppColors.statusActiveBg : AppColors.statusCriticalBg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        esActiva ? Icons.check_circle : Icons.pause_circle_filled,
                                        size: 13,
                                        color: esActiva ? AppColors.statusActive : AppColors.statusCritical,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        red.estado,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: esActiva ? AppColors.statusActive : AppColors.statusCritical,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                                icon: const Icon(Icons.edit_outlined, color: AppColors.secondary, size: 20),
                                onPressed: () => _abrirFormulario(red),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                                icon: const Icon(Icons.delete_outline, color: AppColors.statusCritical, size: 20),
                                onPressed: () => _eliminarRed(red),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Chip(
                                avatar: const Icon(Icons.numbers, size: 14, color: AppColors.primary),
                                label: Text(red.segmento, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                                backgroundColor: AppColors.primary.withOpacity(0.08),
                                side: BorderSide.none,
                                visualDensity: VisualDensity.compact,
                              ),
                              Chip(
                                avatar: const Icon(Icons.alt_route, size: 14, color: AppColors.secondary),
                                label: Text('VLAN ${red.vlan}', style: const TextStyle(fontSize: 12)),
                                backgroundColor: AppColors.secondary.withOpacity(0.08),
                                side: BorderSide.none,
                                visualDensity: VisualDensity.compact,
                              ),
                              Chip(
                                avatar: const Icon(Icons.devices, size: 14, color: AppColors.switchNet),
                                label: Text('${equipos.length} Equipos', style: const TextStyle(fontSize: 12)),
                                backgroundColor: AppColors.switchNet.withOpacity(0.08),
                                side: BorderSide.none,
                                visualDensity: VisualDensity.compact,
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
          ),
        ],
      ),

      // --- BOTÓN FLOTANTE PARA AGREGAR RED ---
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'btn_networks_view_fab',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Agregar Red', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// --- FORMULARIO CREAR / EDITAR RED ---
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
  final _vlanCtrl = TextEditingController();
  String _selectedEstado = 'Activa';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.red != null) {
      _nombreCtrl.text = widget.red!.nombre;
      _segmentoCtrl.text = widget.red!.segmento;
      _vlanCtrl.text = widget.red!.vlan;
      _selectedEstado = widget.red!.estado;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _segmentoCtrl.dispose();
    _vlanCtrl.dispose();
    super.dispose();
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final data = {
      'nombre': _nombreCtrl.text.trim(),
      'segmento': _segmentoCtrl.text.trim(),
      'vlan': _vlanCtrl.text.trim(),
      'estado': _selectedEstado,
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
            content: Text('Error al guardar la red: $e'),
            backgroundColor: AppColors.statusCritical,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      title: Row(
        children: [
          const Icon(Icons.hub, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            widget.red == null ? 'Nueva Red' : 'Editar Red',
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Red (Ej. Red Administrativa)',
                  prefixIcon: Icon(Icons.badge_outlined, color: AppColors.primary),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Ingrese un nombre' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _segmentoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Segmento CIDR (Ej. 192.168.1.0/24)',
                  prefixIcon: Icon(Icons.alt_route_rounded, color: AppColors.primary),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Ingrese el segmento CIDR' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _vlanCtrl,
                decoration: const InputDecoration(
                  labelText: 'VLAN ID (Ej. 10)',
                  prefixIcon: Icon(Icons.numbers, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                isExpanded: true,
                value: _selectedEstado,
                decoration: const InputDecoration(
                  labelText: 'Estado Operativo',
                  prefixIcon: Icon(Icons.toggle_on_outlined, color: AppColors.primary),
                ),
                items: const [
                  DropdownMenuItem(value: 'Activa', child: Text('Activa (En Producción)')),
                  DropdownMenuItem(value: 'Inactiva', child: Text('Inactiva / Mantenimiento')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedEstado = val);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
        ),
        _isSaving
            ? const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
        )
            : ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          ),
          onPressed: _guardar,
          child: Text(widget.red == null ? 'Guardar' : 'Actualizar'),
        ),
      ],
    );
  }
}