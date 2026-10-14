import 'package:flutter/material.dart';
import '../models/network_model.dart';
import '../models/device_model.dart';
import '../services/supabase_service.dart';

class VlansView extends StatefulWidget {
  const VlansView({super.key});

  @override
  State<VlansView> createState() => _VlansViewState();
}

class _VlansViewState extends State<VlansView> {
  final _service = SupabaseService();
  final TextEditingController _searchCtrl = TextEditingController();

  bool _isLoading = true;
  List<NetworkModel> _redesDisponibles = [];
  List<DeviceModel> _dispositivosDisponibles = [];
  List<Map<String, dynamic>> _vlans = [];
  String _searchQuery = '';

  final Set<String> _expandedVlanIds = {};

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.toLowerCase().trim();
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
      final redesList = redesData.map((e) => NetworkModel.fromJson(e)).toList();

      final dispositivosData = await _service.buscarDispositivos('');
      final dispList = dispositivosData.map((e) => DeviceModel.fromJson(e)).toList();

      final vlansData = await _service.getVlans();

      setState(() {
        _redesDisponibles = redesList;
        _dispositivosDisponibles = dispList;
        _vlans = vlansData;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar VLANs: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<NetworkModel> _obtenerRedesDeVlan(Map<String, dynamic> vlan) {
    List<String> ids = [];

    if (vlan['red_ids'] != null && vlan['red_ids'] is List) {
      ids = List<String>.from((vlan['red_ids'] as List).map((e) => e.toString()));
    }

    if (ids.isNotEmpty) {
      return _redesDisponibles.where((r) => ids.contains(r.id)).toList();
    }

    final desc = (vlan['descripcion'] ?? '').toString().toLowerCase();
    final nombre = (vlan['nombre'] ?? '').toString().toLowerCase();

    return _redesDisponibles.where((r) {
      final rNom = r.nombre.toLowerCase();
      return desc.contains(rNom) || nombre.contains(rNom);
    }).toList();
  }

  Future<void> _toggleEstadoVlan(Map<String, dynamic> vlan) async {
    final estadoActual = vlan['estado']?.toString() ?? 'Activa';
    final nuevoEstado = (estadoActual == 'Activa') ? 'Inactiva' : 'Activa';
    try {
      await _service.updateVlan(vlan['id'].toString(), {'estado': nuevoEstado});
      _cargarDatos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('VLAN "${vlan['nombre']}" marcada como $nuevoEstado'),
            backgroundColor: nuevoEstado == 'Activa' ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cambiar estado de VLAN: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _abrirFormularioVlan([Map<String, dynamic>? vlanTarget]) async {
    final redesData = await _service.getRedes();
    final redesList = redesData.map((e) => NetworkModel.fromJson(e)).toList();
    setState(() => _redesDisponibles = redesList);

    final isEditing = vlanTarget != null;

    final vlanIdCtrl = TextEditingController(
      text: isEditing ? '${vlanTarget['vlan_id'] ?? ''}' : '${(_vlans.length + 1) * 10}',
    );
    final nombreCtrl = TextEditingController(
      text: isEditing ? '${vlanTarget['nombre'] ?? ''}' : '',
    );
    final descCtrl = TextEditingController(
      text: isEditing ? '${vlanTarget['descripcion'] ?? ''}' : '',
    );

    List<String> selectedRedIds = [];
    if (isEditing) {
      if (vlanTarget['red_ids'] != null && vlanTarget['red_ids'] is List) {
        selectedRedIds = List<String>.from((vlanTarget['red_ids'] as List).map((e) => e.toString()));
      } else {
        selectedRedIds = _obtenerRedesDeVlan(vlanTarget).map((r) => r.id).toList();
      }
    } else if (_redesDisponibles.isNotEmpty) {
      selectedRedIds = [_redesDisponibles.first.id];
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
            title: Row(
              children: [
                const Icon(Icons.alt_route_rounded, color: Color(0xFF673AB7)),
                const SizedBox(width: 8),
                Text(isEditing ? 'Editar VLAN' : 'Nueva VLAN'),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    TextField(
                      controller: vlanIdCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'ID de VLAN (Ej. 10, 20, 30)',
                        prefixIcon: Icon(Icons.tag_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nombreCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la VLAN',
                        hintText: 'Ej. VLAN_ADMIN',
                        prefixIcon: Icon(Icons.label_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Agregue la red o redes que desea asociar:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1F2937)),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      constraints: const BoxConstraints(maxHeight: 160),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _redesDisponibles.isEmpty
                          ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text(
                          'No hay redes registradas para seleccionar.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      )
                          : ListView(
                        shrinkWrap: true,
                        children: _redesDisponibles.map((r) {
                          final isSelected = selectedRedIds.contains(r.id);
                          return CheckboxListTile(
                            dense: true,
                            activeColor: const Color(0xFF673AB7),
                            title: Text(r.nombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            subtitle: Text(r.segmento, style: const TextStyle(fontSize: 11)),
                            value: isSelected,
                            onChanged: (bool? checked) {
                              setDialogState(() {
                                if (checked == true) {
                                  if (!selectedRedIds.contains(r.id)) {
                                    selectedRedIds.add(r.id);
                                  }
                                } else {
                                  selectedRedIds.remove(r.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 14),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Descripción / Propósito',
                        prefixIcon: Icon(Icons.description_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF673AB7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                ),
                onPressed: () async {
                  if (nombreCtrl.text.trim().isEmpty) return;
                  if (selectedRedIds.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor, agregue al menos una red'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  final redesSeleccionadas = _redesDisponibles
                      .where((r) => selectedRedIds.contains(r.id))
                      .toList();

                  final nombresRedes = redesSeleccionadas.map((r) => r.nombre).join(', ');
                  final segmentosRedes = redesSeleccionadas.map((r) => r.segmento).join(' | ');

                  final vlanNombre = nombreCtrl.text.trim().toUpperCase();
                  final vlanId = int.tryParse(vlanIdCtrl.text) ?? 100;

                  final userDesc = descCtrl.text.trim();
                  final descripcionFinal = userDesc.isEmpty
                      ? 'Redes: $nombresRedes ($segmentosRedes)'
                      : '$userDesc | Redes: $nombresRedes ($segmentosRedes)';

                  final vlanData = {
                    'vlan_id': vlanId,
                    'nombre': vlanNombre,
                    'descripcion': descripcionFinal,
                    'estado': 'Activa',
                    'red_ids': selectedRedIds,
                  };

                  try {
                    if (isEditing) {
                      await _service.updateVlan(vlanTarget['id'].toString(), vlanData);
                    } else {
                      await _service.addVlan(vlanData);
                    }

                    _cargarDatos();

                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEditing
                              ? 'VLAN actualizada correctamente'
                              : 'Segmentación VLAN agregada correctamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al guardar VLAN: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: Text(isEditing ? 'Actualizar' : 'Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _eliminarVlan(Map<String, dynamic> vlan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar VLAN'),
        content: Text('¿Deseas eliminar la segmentación "${vlan['nombre']}" (ID ${vlan['vlan_id']})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteVlan(
          vlan['id'].toString(),
          vlan['nombre'].toString(),
          int.tryParse(vlan['vlan_id'].toString()) ?? 0,
        );
        _cargarDatos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('VLAN eliminada correctamente'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar VLAN: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF673AB7);

    final vlansFiltradas = _vlans.where((v) {
      final nombre = v['nombre'].toString().toLowerCase();
      final desc = v['descripcion'].toString().toLowerCase();
      final id = v['vlan_id'].toString();
      return nombre.contains(_searchQuery) || desc.contains(_searchQuery) || id.contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por ID, Nombre de VLAN o Descripción...',
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
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryColor))
                : vlansFiltradas.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.alt_route_rounded, size: 70, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    _searchQuery.isEmpty
                        ? 'No hay segmentaciones de VLAN registradas.'
                        : 'No se encontraron coincidencias.',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _cargarDatos,
              color: primaryColor,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                itemCount: vlansFiltradas.length,
                itemBuilder: (context, index) {
                  final vlan = vlansFiltradas[index];
                  final vlanKey = (vlan['id'] ?? vlan['vlan_id']).toString();
                  final isExpanded = _expandedVlanIds.contains(vlanKey);
                  final redesAsignadas = _obtenerRedesDeVlan(vlan);
                  final estadoVlan = vlan['estado']?.toString() ?? 'Activa';
                  final esActiva = estadoVlan == 'Activa';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    decoration: BoxDecoration(
                      color: esActiva ? Colors.white : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              if (isExpanded) {
                                _expandedVlanIds.remove(vlanKey);
                              } else {
                                _expandedVlanIds.add(vlanKey);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: (esActiva ? primaryColor : Colors.grey).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'VLAN',
                                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: esActiva ? primaryColor : Colors.grey),
                                      ),
                                      Text(
                                        '${vlan['vlan_id'] ?? ''}',
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: esActiva ? primaryColor : Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        vlan['nombre'] ?? 'S/N',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: esActiva ? Colors.black87 : Colors.grey.shade600,
                                          decoration: esActiva ? null : TextDecoration.lineThrough,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${redesAsignadas.length} Red(es) vinculada(s)',
                                        style: TextStyle(fontSize: 11, color: esActiva ? primaryColor : Colors.grey, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: () => _toggleEstadoVlan(vlan),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: esActiva ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          estadoVlan,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: esActiva ? Colors.green.shade800 : Colors.orange.shade900,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(4),
                                      icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 20),
                                      onPressed: () => _abrirFormularioVlan(vlan),
                                    ),
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(4),
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                      onPressed: () => _eliminarVlan(vlan),
                                    ),
                                    Icon(
                                      isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                      color: Colors.grey.shade600,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (isExpanded) ...[
                          const Divider(height: 1),
                          Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFAF9FC),
                              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Redes asignadas a esta VLAN:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (redesAsignadas.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Text(
                                      'No hay redes asociadas a esta VLAN.',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                                    ),
                                  )
                                else
                                  Column(
                                    children: redesAsignadas.map((red) {
                                      final numEquipos = _dispositivosDisponibles.where((d) => d.redId == red.id).length;

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 6.0),
                                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.grey.shade200),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.hub_outlined, color: primaryColor, size: 18),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    red.nombre,
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                  ),
                                                  Text(
                                                    red.segmento,
                                                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.grey),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: primaryColor.withOpacity(0.08),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '$numEquipos equipos',
                                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor),
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
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'btn_vlans_view_fab',
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        onPressed: () => _abrirFormularioVlan(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva VLAN', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}