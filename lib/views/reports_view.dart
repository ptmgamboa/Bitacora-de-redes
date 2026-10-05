import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/network_model.dart';
import '../models/device_model.dart';
import '../services/report_service.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  bool _isLoading = true;
  List<NetworkModel> _redes = [];
  Map<String, List<DeviceModel>> _dispositivosPorRed = {};
  String _searchQuery = '';
  String? _generatingReportForId;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;

      // Obtener lista de redes
      final resRedes = await supabase.from('redes').select();
      final List<NetworkModel> redes = (resRedes as List)
          .map((item) => NetworkModel.fromJson(item))
          .toList();

      // Obtener lista de dispositivos
      final resDispositivos = await supabase.from('dispositivos').select();
      final List<DeviceModel> dispositivos = (resDispositivos as List)
          .map((item) => DeviceModel.fromJson(item))
          .toList();

      // Agrupar dispositivos según la red a la que pertenecen
      Map<String, List<DeviceModel>> mapaDispositivos = {};
      for (var red in redes) {
        mapaDispositivos[red.id] = dispositivos
            .where((d) => d.redId == red.id)
            .toList();
      }

      if (mounted) {
        setState(() {
          _redes = redes;
          _dispositivosPorRed = mapaDispositivos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al obtener datos: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _generarReporte(NetworkModel red) async {
    setState(() => _generatingReportForId = red.id);
    try {
      final dispositivos = _dispositivosPorRed[red.id] ?? [];

      // Llama al servicio PDF que abre la vista previa / descarga
      await ReportService.generarReporteRed(
        red: red,
        dispositivos: dispositivos,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar el PDF: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingReportForId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFF673AB7);

    final redesFiltradas = _redes.where((red) {
      final query = _searchQuery.toLowerCase();
      return red.nombre.toLowerCase().contains(query) ||
          red.segmento.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: primaryPurple),
      )
          : RefreshIndicator(
        onRefresh: _cargarDatos,
        color: primaryPurple,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Módulo de Reportes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: primaryPurple),
                    onPressed: _cargarDatos,
                    tooltip: 'Actualizar redes',
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Genera la ficha técnica y bitácora en PDF de cada red registrada.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),

              // Buscador de redes
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Buscar red por nombre o segmento...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tarjetas de redes con botón para exportar
              Expanded(
                child: redesFiltradas.isEmpty
                    ? Center(
                  child: Text(
                    _searchQuery.isEmpty
                        ? 'No hay redes para generar reportes.'
                        : 'No se encontraron resultados.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
                    : ListView.builder(
                  itemCount: redesFiltradas.length,
                  itemBuilder: (context, index) {
                    final red = redesFiltradas[index];
                    final dispositivos = _dispositivosPorRed[red.id] ?? [];
                    final isGenerating = _generatingReportForId == red.id;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        red.nombre,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Segmento: ${red.segmento}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryPurple.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${dispositivos.length} disp.',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: primaryPurple,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'VLAN: ${red.vlan ?? 'N/A'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: isGenerating
                                      ? null
                                      : () => _generarReporte(red),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryPurple,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    minimumSize: Size.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: isGenerating
                                      ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                      : const Icon(Icons.picture_as_pdf, size: 16),
                                  label: Text(
                                    isGenerating ? 'Generando...' : 'Generar PDF',
                                    style: const TextStyle(fontSize: 13),
                                  ),
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
        ),
      ),
    );
  }
}