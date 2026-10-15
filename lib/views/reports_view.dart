import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../core/app_colors.dart';
import '../services/report_service.dart';
import '../services/supabase_service.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  final _reportService = ReportService();
  final _supabaseService = SupabaseService();

  bool _isLoading = true;
  Map<String, dynamic> _metrics = {};

  @override
  void initState() {
    super.initState();
    _cargarMetricas();
  }

  Future<void> _cargarMetricas() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabaseService.getDatosDashboard();
      final vlans = await _supabaseService.getVlans();

      if (mounted) {
        setState(() {
          _metrics = {
            'totalRedes': data['totalRedes'] ?? 0,
            'totalDispositivos': data['totalDispositivos'] ?? 0,
            'totalVlans': vlans.length,
            'cambiosHoy': data['cambiosHoy'] ?? 0,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BANNER SUPERIOR DE INFORMES EN GRADIENTE
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Centro de Informes & Exportación',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Generación en tiempo real de reportes de red, VLANs y auditoría',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // MÉTRICAS RÁPIDAS
            Row(
              children: [
                _buildMetricTile('Redes', '${_metrics['totalRedes'] ?? 0}', Icons.hub_outlined, AppColors.primary),
                const SizedBox(width: 8),
                _buildMetricTile('Equipos', '${_metrics['totalDispositivos'] ?? 0}', Icons.devices_other, AppColors.secondary),
                const SizedBox(width: 8),
                _buildMetricTile('VLANs', '${_metrics['totalVlans'] ?? 0}', Icons.alt_route, AppColors.switchNet),
                const SizedBox(width: 8),
                _buildMetricTile('Cambios', '${_metrics['cambiosHoy'] ?? 0}', Icons.history, AppColors.statusWarning),
              ],
            ),

            const SizedBox(height: 16),

            // VISUALIZADOR PREVIO DEL PDF
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: PdfPreview(
                    build: (format) => _reportService.generarReportePdfCompleto(),
                    allowPrinting: true,
                    allowSharing: true,
                    canDebug: false,
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    pdfFileName: 'Reporte_Infraestructura_Red.pdf',
                    loadingWidget: const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(count, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
            Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}