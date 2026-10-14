import 'package:flutter/material.dart';
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
          SnackBar(content: Text('Error al cargar redes: $e'), backgroundColor: Colors.red),
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
            backgroundColor: nuevoEstado == 'Activa' ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cambiar estado: $e'), backgroundColor: Colors.red),
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
        await _service.deleteRed(red.id);
        _cargarDatos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Red eliminada correctamente'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar red: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF673AB7);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por Nombre, Segmento CIDR o VLAN...',
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
                : _redesFiltradas.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hub_outlined, size: 70, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    _searchQuery.isEmpty ? 'No hay redes registradas.' : 'No se encontraron coincidencias.',
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
                itemCount: _redesFiltradas.length,
                itemBuilder: (context, index) {
                  final red = _redesFiltradas[index];
                  final esActiva = red.estado == 'Activa';
                  final equipos = _mapaDispositivos[red.id] ?? [];

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
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.hub_rounded, color: esActiva ? primaryColor : Colors.grey, size: 24),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  red.nombre,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: esActiva ? Colors.black87 : Colors.grey.shade600,
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
                                    color: esActiva ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        esActiva ? Icons.check_circle : Icons.pause_circle_filled,
                                        size: 13,
                                        color: esActiva ? Colors.green.shade800 : Colors.orange.shade900,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        red.estado,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: esActiva ? Colors.green.shade800 : Colors.orange.shade900,
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
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                onPressed: () => _eliminarRed(red),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              Chip(
                                avatar: const Icon(Icons.numbers, size: 14),
                                label: Text(red.segmento),
                                visualDensity: VisualDensity.compact,
                              ),
                              Chip(
                                avatar: const Icon(Icons.alt_route, size: 14),
                                label: Text('VLAN ${red.vlan}'),
                                visualDensity: VisualDensity.compact,
                              ),
                              Chip(
                                avatar: const Icon(Icons.devices, size: 14),
                                label: Text('${equipos.length} Equipos'),
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
    );
  }
}