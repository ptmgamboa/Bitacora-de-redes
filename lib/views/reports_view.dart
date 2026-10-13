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
  List<DeviceModel> _dispositivos = [];
  String? _generatingCategory;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;

      final resRedes = await supabase.from('redes').select();
      final redes = (resRedes as List).map((e) => NetworkModel.fromJson(e)).toList();

      List resDisp = [];
      try {
        resDisp = await supabase.from('dispositivos').select();
      } catch (_) {
        resDisp = await supabase.from('devices').select();
      }
      final dispositivos = resDisp.map((e) => DeviceModel.fromJson(e)).toList();

      if (mounted) {
        setState(() {
          _redes = redes;
          _dispositivos = dispositivos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- CONFIGURACIÓN DE FILTROS Y GENERACIÓN POR CATEGORÍA ---
  void _abrirFiltrosReporte(String categoria, String titulo, IconData icono) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        DateTimeRange? fechaRange;
        List<String> redesSeleccionadas = _redes.map((r) => r.id).toList();

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icono, color: const Color(0xFF673AB7)),
                      const SizedBox(width: 10),
                      Text('Generar Reporte: $titulo', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filtro por Fecha (para Actividad)
                  if (categoria == 'actividad') ...[
                    const Text('Seleccionar Rango de Fechas:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        fechaRange == null
                            ? 'Todo el historial'
                            : '${fechaRange!.start.day}/${fechaRange!.start.month} - ${fechaRange!.end.day}/${fechaRange!.end.month}',
                      ),
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2025),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setModalState(() => fechaRange = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Filtro Selección de Redes (para Redes)
                  if (categoria == 'redes') ...[
                    const Text('Redes a incluir:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 140,
                      child: ListView(
                        children: _redes.map((r) {
                          final selected = redesSeleccionadas.contains(r.id);
                          return CheckboxListTile(
                            dense: true,
                            title: Text(r.nombre),
                            subtitle: Text(r.segmento),
                            value: selected,
                            onChanged: (val) {
                              setModalState(() {
                                if (val == true) {
                                  redesSeleccionadas.add(r.id);
                                } else {
                                  redesSeleccionadas.remove(r.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Botón Generar PDF
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF673AB7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Generar PDF'),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        _procesarGeneracion(categoria, fechaRange, redesSeleccionadas);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _procesarGeneracion(String cat, DateTimeRange? fechas, List<String> redIds) async {
    setState(() => _generatingCategory = cat);
    try {
      final user = Supabase.instance.client.auth.currentUser;

      switch (cat) {
        case 'redes':
          final filtradas = _redes.where((r) => redIds.contains(r.id)).toList();
          await ReportService.generarReporteRedes(redes: filtradas, dispositivos: _dispositivos);
          break;

        case 'actividad':
          List<Map<String, dynamic>> act = [];
          for (var d in _dispositivos) {
            act.add({
              'titulo': 'Registro de Dispositivo: ${d.nombre}',
              'subtitulo': 'IP: ${d.ip} | MAC: ${d.mac}',
              'tipo': d.tipoTexto,
              'fecha': DateTime.now(),
            });
          }
          final rangoText = fechas == null
              ? 'Histórico Completo'
              : '${fechas.start.day}/${fechas.start.month} al ${fechas.end.day}/${fechas.end.month}';
          await ReportService.generarReporteActividad(actividades: act, rangoFechasText: rangoText);
          break;

        case 'incidencias':
          List<Map<String, String>> inc = [];
          final redesSinEquipos = _redes.where((r) => !_dispositivos.any((d) => d.redId == r.id)).toList();

          if (redesSinEquipos.isNotEmpty) {
            inc.add({
              'nivel': 'Advertencia',
              'titulo': 'Segmentos de red sin dispositivos',
              'detalle': 'Hay ${redesSinEquipos.length} red(es) sin equipos registrados.',
            });
          }
          inc.add({
            'nivel': 'OK',
            'titulo': 'Monitoreo de Infraestructura',
            'detalle': 'Bitácora operando con ${_dispositivos.length} equipos activos.',
          });

          await ReportService.generarReporteIncidencias(incidencias: inc);
          break;

        case 'usuarios':
          await ReportService.generarReporteUsuarios(emailAdmin: user?.email ?? 'admin@itsu.edu.mx');
          break;

        case 'vlans':
          await ReportService.generarReporteVlans(redes: _redes);
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar reporte: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingCategory = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFF673AB7);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryPurple));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      body: RefreshIndicator(
        onRefresh: _cargarDatos,
        color: primaryPurple,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Módulo de Reportes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
              ),
              const SizedBox(height: 4),
              Text(
                'Seleccione una categoría para configurar y exportar la bitácora en formato PDF.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),

              // GRID DE CATEGORÍAS DE REPORTES
              _buildCategoryCard(
                categoria: 'redes',
                titulo: 'Reporte de Redes',
                descripcion: 'Ficha técnica y lista de segmentos CIDR y dispositivos asociados.',
                icono: Icons.lan_outlined,
                color: primaryPurple,
              ),
              _buildCategoryCard(
                categoria: 'actividad',
                titulo: 'Reporte de Actividad',
                descripcion: 'Histórico de cambios y adición de equipos filtrado por fechas.',
                icono: Icons.history_rounded,
                color: Colors.indigo,
              ),
              _buildCategoryCard(
                categoria: 'incidencias',
                titulo: 'Reporte de Incidencias',
                descripcion: 'Alertas activas, redes vacías y estado del sistema.',
                icono: Icons.warning_amber_rounded,
                color: Colors.amber.shade900,
              ),
              _buildCategoryCard(
                categoria: 'usuarios',
                titulo: 'Reporte de Usuarios',
                descripcion: 'Ficha de la cuenta del Administrador y permisos.',
                icono: Icons.admin_panel_settings_outlined,
                color: Colors.teal,
              ),
              _buildCategoryCard(
                categoria: 'vlans',
                titulo: 'Segmentación (VLANs)',
                descripcion: 'Tabla de asignación de VLANs e identificadores de red.',
                icono: Icons.alt_route_rounded,
                color: Colors.deepOrange,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required String categoria,
    required String titulo,
    required String descripcion,
    required IconData icono,
    required Color color,
  }) {
    final isGenerating = _generatingCategory == categoria;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icono, color: color, size: 26),
        ),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            descripcion,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
        trailing: isGenerating
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => _abrirFiltrosReporte(categoria, titulo, icono),
          child: const Text('Exportar'),
        ),
      ),
    );
  }
}