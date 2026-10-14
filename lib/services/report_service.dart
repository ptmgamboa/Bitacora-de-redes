import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/device_model.dart';
import '../models/network_model.dart';
import '../services/supabase_service.dart';

class ReportService {
  final SupabaseService _service = SupabaseService();

  static const PdfColor primaryColor = PdfColor.fromInt(0xFF673AB7);
  static const PdfColor activeGreen = PdfColor.fromInt(0xFF2E7D32);
  static const PdfColor inactiveOrange = PdfColor.fromInt(0xFFE65100);
  static const PdfColor lightBg = PdfColor.fromInt(0xFFF5F5FA);

  Future<Uint8List> generarReportePdfCompleto() async {
    final pdf = pw.Document();

    final redesData = await _service.getRedes();
    final redes = redesData.map((e) => NetworkModel.fromJson(e)).toList();

    final dispData = await _service.buscarDispositivos('');
    final dispositivos = dispData.map((e) => DeviceModel.fromJson(e)).toList();

    final vlans = await _service.getVlans();
    final historial = await _service.getHistorialCambiosHoy();

    final totalDispositivos = dispositivos.length;
    final activos = dispositivos.where((d) => d.esActivo).length;
    final inactivos = totalDispositivos - activos;
    final fechaGeneracion = DateTime.now();

    final fechaStr =
        '${fechaGeneracion.day.toString().padLeft(2, '0')}/${fechaGeneracion.month.toString().padLeft(2, '0')}/${fechaGeneracion.year} ${fechaGeneracion.hour.toString().padLeft(2, '0')}:${fechaGeneracion.minute.toString().padLeft(2, '0')}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) => _buildHeader(fechaStr),
        footer: (pw.Context context) => _buildFooter(context),
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 12),

            // --- RESUMEN EJECUTIVO (KPIs) ---
            _buildSectionTitle('Resumen Ejecutivo de Infraestructura'),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildKpiCard('Total Redes', '${redes.length}', PdfColors.purple800),
                _buildKpiCard('Total VLANs', '${vlans.length}', PdfColors.indigo800),
                _buildKpiCard('Equipos Activos', '$activos', activeGreen),
                _buildKpiCard('Equipos Inactivos', '$inactivos', inactiveOrange),
              ],
            ),
            pw.SizedBox(height: 20),

            // --- TABLA DE SEGMENTOS DE RED ---
            _buildSectionTitle('Segmentación de Redes (CIDR)'),
            pw.SizedBox(height: 8),
            _buildRedesTable(redes, dispositivos),
            pw.SizedBox(height: 20),

            // --- TABLA DE INVENTARIO DE DISPOSITIVOS ---
            _buildSectionTitle('Inventario Detallado de Dispositivos'),
            pw.SizedBox(height: 8),
            _buildDispositivosTable(dispositivos),
            pw.SizedBox(height: 20),

            // --- TABLA DE VLANS Y ASIGNACIONES ---
            _buildSectionTitle('Mapeo de VLANs y Cobertura'),
            pw.SizedBox(height: 8),
            _buildVlansTable(vlans, redes),
            pw.SizedBox(height: 20),

            // --- AUDITORÍA DE CAMBIOS RECIENTES ---
            _buildSectionTitle('Bitácora de Auditoría y Cambios'),
            pw.SizedBox(height: 8),
            _buildHistorialTable(historial),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // --- ENCABEZADO ---
  pw.Widget _buildHeader(String fecha) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: primaryColor, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'BITÁCORA DE INFRAESTRUCTURA DE RED',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              pw.Text(
                'Informe Técnico de Estado, Inventario & VLANs',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Generado: $fecha',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
              ),
              pw.Text(
                'Estado: Sincronizado Supabase',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: activeGreen),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- PIE DE PÁGINA ---
  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Documento Confidencial - Uso Interno TI', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          pw.Text('Página ${context.pageNumber} de ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  // --- TÍTULOS DE SECCIÓN ---
  pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const pw.BoxDecoration(
        color: lightBg,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor),
      ),
    );
  }

  // --- TARJETAS KPI ---
  pw.Widget _buildKpiCard(String label, String value, PdfColor color) {
    return pw.Container(
      width: 115,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        children: [
          pw.Text(value, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: color)),
          pw.SizedBox(height: 2),
          pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800), textAlign: pw.TextAlign.center),
        ],
      ),
    );
  }

  // --- TABLA REDES ---
  pw.Widget _buildRedesTable(List<NetworkModel> redes, List<DeviceModel> dispositivos) {
    if (redes.isEmpty) {
      return pw.Text('No hay redes registradas.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600));
    }

    final headers = ['Nombre de Red', 'Segmento CIDR', 'VLAN ID', 'Estado', 'Equipos'];
    final data = redes.map((r) {
      final numEquipos = dispositivos.where((d) => d.redId == r.id).length;
      return [
        r.nombre,
        r.segmento,
        r.vlan.isEmpty ? 'N/A' : r.vlan,
        r.estado,
        '$numEquipos equipos',
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: primaryColor),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(6),
    );
  }

  // --- TABLA DISPOSITIVOS ---
  pw.Widget _buildDispositivosTable(List<DeviceModel> dispositivos) {
    if (dispositivos.isEmpty) {
      return pw.Text('No hay dispositivos registrados.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600));
    }

    final headers = ['Nombre / Host', 'Tipo', 'Dirección IPv4', 'Dirección MAC', 'Fabricante', 'Ubicación', 'Estado'];
    final data = dispositivos.map((d) {
      return [
        d.nombre,
        d.tipoTexto,
        d.ip,
        d.mac,
        d.fabricante,
        d.ubicacion,
        d.estado,
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
      headerDecoration: const pw.BoxDecoration(color: primaryColor),
      cellStyle: const pw.TextStyle(fontSize: 7.5),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(5),
    );
  }

  // --- TABLA VLANS ---
  pw.Widget _buildVlansTable(List<Map<String, dynamic>> vlans, List<NetworkModel> redes) {
    if (vlans.isEmpty) {
      return pw.Text('No hay VLANs registradas.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600));
    }

    final headers = ['ID VLAN', 'Nombre Segmento', 'Descripción / Cobertura', 'Estado'];
    final data = vlans.map((v) {
      return [
        'VLAN ${v['vlan_id'] ?? ''}',
        v['nombre'] ?? '',
        v['descripcion'] ?? 'Segmentación activa',
        v['estado'] ?? 'Activa',
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: primaryColor),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(6),
    );
  }

  // --- TABLA HISTORIAL AUDITORÍA ---
  pw.Widget _buildHistorialTable(List<Map<String, dynamic>> historial) {
    if (historial.isEmpty) {
      return pw.Text('No se registraron cambios el día de hoy.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600));
    }

    final headers = ['Hora', 'Evento / Título', 'Usuario', 'Detalles'];
    final data = historial.map((h) {
      final dt = DateTime.tryParse(h['created_at']?.toString() ?? '');
      final horaStr = dt != null
          ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
          : '--:--';

      return [
        horaStr,
        h['titulo'] ?? 'Cambio',
        h['usuario'] ?? 'Admin',
        h['detalle'] ?? '',
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
      headerDecoration: const pw.BoxDecoration(color: primaryColor),
      cellStyle: const pw.TextStyle(fontSize: 7.5),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(5),
    );
  }

  Future<void> exportarOImprimirReporte() async {
    final pdfBytes = await generarReportePdfCompleto();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Reporte_Red_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }
}