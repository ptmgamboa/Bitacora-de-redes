import 'package:flutter/material.dart';
import '../models/network_model.dart';
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
  List<NetworkModel> _redes = [];
  List<Map<String, dynamic>> _vlans = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _cargarVlans();
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

  Future<void> _cargarVlans() async {
    setState(() => _isLoading = true);
    try {
      final redesData = await _service.getRedes();
      final redesList = redesData.map((e) => NetworkModel.fromJson(e)).toList();

      // Generación de la segmentación VLAN vinculada a las redes
      List<Map<String, dynamic>> vlansCalculadas = [];
      int vlanIdCounter = 10;

      for (var red in redesList) {
        vlansCalculadas.add({
          'vlan_id': vlanIdCounter,
          'nombre': 'VLAN_${red.nombre.replaceAll(' ', '_').toUpperCase()}',
          'red_asociada': red.nombre,
          'segmento': red.segmento,
          'estado': 'Activa',
          'descripcion': 'Segmentación asignada a la red ${red.nombre}',
        });
        vlanIdCounter += 10;
      }

      setState(() {
        _redes = redesList;
        _vlans = vlansCalculadas;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar VLANs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _abrirFormularioCrearVlan() {
    final vlanIdCtrl = TextEditingController(text: '${(_vlans.length + 1) * 10}');
    final nombreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? selectedRedId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
            title: const Row(
              children: [
                Icon(Icons.alt_route_rounded, color: Color(0xFF673AB7)),
                SizedBox(width: 8),
                Text('Nueva VLAN'),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: selectedRedId,
                      decoration: const InputDecoration(
                        labelText: 'Red / Segmento Asociado',
                        prefixIcon: Icon(Icons.lan_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      items: _redes.map((r) {
                        return DropdownMenuItem(
                          value: r.id,
                          child: Text('${r.nombre} (${r.segmento})'),
                        );
                      }).toList(),
                      onChanged: (val) => setDialogState(() => selectedRedId = val),
                    ),
                    const SizedBox(height: 12),
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
                onPressed: () {
                  if (nombreCtrl.text.trim().isEmpty) return;

                  final redEncontrada = _redes.firstWhere(
                        (r) => r.id == selectedRedId,
                    orElse: () => NetworkModel(id: '', nombre: 'General', segmento: '192.168.0.0/24'),
                  );

                  setState(() {
                    _vlans.add({
                      'vlan_id': int.tryParse(vlanIdCtrl.text) ?? 100,
                      'nombre': nombreCtrl.text.trim().toUpperCase(),
                      'red_asociada': redEncontrada.nombre,
                      'segmento': redEncontrada.segmento,
                      'estado': 'Activa',
                      'descripcion': descCtrl.text.trim().isEmpty
                          ? 'Segmentación de red personalizada'
                          : descCtrl.text.trim(),
                    });
                  });

                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Segmentación de VLAN agregada correctamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF673AB7);

    final vlansFiltradas = _vlans.where((v) {
      final nombre = v['nombre'].toString().toLowerCase();
      final red = v['red_asociada'].toString().toLowerCase();
      final id = v['vlan_id'].toString();
      return nombre.contains(_searchQuery) || red.contains(_searchQuery) || id.contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      body: Column(
        children: [
          // BARRA DE BÚSQUEDA
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por ID, Nombre de VLAN o Red...',
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

          // LISTA DE VLANS
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
              onRefresh: _cargarVlans,
              color: primaryColor,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                itemCount: vlansFiltradas.length,
                itemBuilder: (context, index) {
                  final vlan = vlansFiltradas[index];

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
                          // Ícono con ID de VLAN
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'VLAN',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                Text(
                                  '${vlan['vlan_id']}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Información de la VLAN
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vlan['nombre'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Red: ${vlan['red_asociada']} • ${vlan['segmento']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  vlan['descripcion'],
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Badge Estado
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              vlan['estado'],
                              style: TextStyle(
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
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
        heroTag: 'btn_vlans_view_fab',
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        onPressed: _abrirFormularioCrearVlan,
        icon: const Icon(Icons.add),
        label: const Text('Nueva VLAN', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}