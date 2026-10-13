import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/network_model.dart';
import '../models/device_model.dart';

class ReportService {
  static const primaryColor = PdfColor.fromInt(0xFF673AB7);
  static const primaryLightColor = PdfColor.fromInt(0xFFEDE7F6);

  // 1. REPORTE DE REDES
  static Future<void> generarReporteRedes({
    required List<NetworkModel> redes,
    required List<DeviceModel> dispositivos,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader('REPORTE GENERAL DE REDES', 'Infraestructura de Red - Bitacora.Net'),
          pw.SizedBox(height: 16),
          _buildStatRow([
            _buildStat('Total Redes', '${redes.length}'),
            _buildStat('Total Dispositivos', '${dispositivos.length}'),
          ]),
          pw.SizedBox(height: 20),
          pw.Text('Listado de Redes Registradas', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryColor)),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headerDecoration: const pw.BoxDecoration(color: primaryColor),
            headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
            headers: ['Nombre de Red', 'Segmento CIDR', 'Dispositivos Asignados'],
            data: redes.map((r) {
              final cant = dispositivos.where((d) => d.redId == r.id).length;
              return [r.nombre, r.segmento, '$cant equipos'];
            }).toList(),
          ),
          _buildFooter(),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Reporte_Redes_BitacoraNet.pdf',
    );
  }

  // 2. REPORTE DE ACTIVIDAD
  static Future<void> generarReporteActividad({
    required List<Map<String, dynamic>> actividades,
    required String rangoFechasText,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader('REPORTE DE ACTIVIDAD Y CAMBIOS', 'Rango: $rangoFechasText'),
          pw.SizedBox(height: 16),
          _buildStatRow([
            _buildStat('Eventos Registrados', '${actividades.length}'),
            _buildStat('Perfil Ejecutor', 'Administrador'),
          ]),
          pw.SizedBox(height: 20),
          pw.Text('Registro de Eventos', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryColor)),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headerDecoration: const pw.BoxDecoration(color: primaryColor),
            headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
            headers: ['Acción / Evento', 'Detalle / IP', 'Tipo', 'Fecha'],
            data: actividades.map((a) {
              final fecha = a['fecha'] as DateTime?;
              final fechaStr = fecha != null ? '${fecha.day}/${fecha.month}/${fecha.year}' : 'Hoy';
              return [a['titulo'] ?? '', a['subtitulo'] ?? '', a['tipo'] ?? 'General', fechaStr];
            }).toList(),
          ),
          _buildFooter(),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Reporte_Actividad.pdf',
    );
  }

  // 3. REPORTE DE INCIDENCIAS
  static Future<void> generarReporteIncidencias({
    required List<Map<String, String>> incidencias,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader('REPORTE DE INCIDENCIAS Y ALERTAS', 'Auditoría de Infraestructura'),
          pw.SizedBox(height: 16),
          pw.Text('Alertas Detectadas en el Sistema', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryColor)),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headerDecoration: const pw.BoxDecoration(color: primaryColor),
            headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
            headers: ['Prioridad / Nivel', 'Incidencia', 'Detalle del Estado'],
            data: incidencias.map((i) {
              return [(i['nivel'] ?? 'Info').toUpperCase(), i['titulo'] ?? '', i['detalle'] ?? ''];
            }).toList(),
          ),
          _buildFooter(),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Reporte_Incidencias.pdf',
    );
  }

  // 4. REPORTE DE USUARIOS
  static Future<void> generarReporteUsuarios({
    required String emailAdmin,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader('REPORTE DE CUENTA DE ADMINISTRACIÓN', 'Control de Accesos'),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headerDecoration: const pw.BoxDecoration(color: primaryColor),
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
              headers: ['Usuario / Correo', 'Rol Asignado', 'Estado de Cuenta'],
              data: [
                [emailAdmin, 'Administrador General', 'Activo / Autenticado'],
              ],
            ),
            pw.Spacer(),
            _buildFooter(),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Reporte_Usuarios.pdf',
    );
  }

  // 5. REPORTE DE SEGMENTACIÓN (VLAN)
  static Future<void> generarReporteVlans({
    required List<NetworkModel> redes,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader('REPORTE DE SEGMENTACIÓN Y VLANS', 'Tabla de Virtual LANs'),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headerDecoration: const pw.BoxDecoration(color: primaryColor),
            headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
            headers: ['ID VLAN', 'Nombre Segmento', 'Red Asociada', 'Segmento CIDR'],
            data: redes.asMap().entries.map((entry) {
              final idx = entry.key;
              final r = entry.value;
              return ['VLAN ${(idx + 1) * 10}', 'VLAN_${r.nombre.replaceAll(' ', '_').toUpperCase()}', r.nombre, r.segmento];
            }).toList(),
          ),
          _buildFooter(),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Reporte_VLANs.pdf',
    );
  }

  // --- COMPONENTES AUXILIARES DE DISEÑO DE PDF ---
  static pw.Widget _buildHeader(String title, String subtitle) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(color: primaryColor, borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('ITSU - BITACORA.NET', style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
          pw.SizedBox(height: 4),
          pw.Text(title, style: pw.TextStyle(color: PdfColors.white, fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Text(subtitle, style: const pw.TextStyle(color: PdfColors.white, fontSize: 11)),
        ],
      ),
    );
  }

  static pw.Widget _buildStatRow(List<pw.Widget> stats) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(color: primaryLightColor, borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceAround, children: stats),
    );
  }

  static pw.Widget _buildStat(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryColor)),
      ],
    );
  }

  static pw.Widget _buildFooter() {
    final now = DateTime.now();
    return pw.Column(
      children: [
        pw.SizedBox(height: 20),
        pw.Divider(color: PdfColors.grey300),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Generado el ${now.day}/${now.month}/${now.year} a las ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
      ],
    );
  }
}