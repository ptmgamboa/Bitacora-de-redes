import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/network_model.dart';
import '../models/device_model.dart';

class ReportService {
  /// Genera y abre el visor de impresión / descarga en PDF para una Red y sus Dispositivos
  static Future<void> generarReporteRed({
    required NetworkModel red,
    required List<DeviceModel> dispositivos,
  }) async {
    final pdf = pw.Document();

    const primaryColor = PdfColor.fromInt(0xFF673AB7);
    const primaryLightColor = PdfColor.fromInt(0xFFEDE7F6);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // --- ENCABEZADO DE RED ---
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: primaryColor,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'REPORTE DE RED',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        red.nombre,
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Segmento: ${red.segmento}',
                        style: pw.TextStyle(color: PdfColors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 16),

            // --- TARJETA DE RESUMEN ---
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: primaryLightColor,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildStat('Total Dispositivos', '${dispositivos.length}'),
                  _buildStat('VLAN', red.vlan ?? 'N/A'),
                  _buildStat('Máscara', red.mascara ?? 'N/A'),
                ],
              ),
            ),

            pw.SizedBox(height: 20),
            pw.Text(
              'Dispositivos Conectados',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
            pw.SizedBox(height: 10),

            // --- TABLA DE DISPOSITIVOS ---
            if (dispositivos.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 20),
                child: pw.Center(
                  child: pw.Text(
                    'No hay dispositivos registrados en esta red.',
                    style: const pw.TextStyle(color: PdfColors.grey700),
                  ),
                ),
              )
            else
              pw.Table.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(color: primaryColor),
                cellHeight: 28,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerLeft,
                  4: pw.Alignment.centerLeft,
                },
                headers: ['Nombre', 'IP', 'MAC', 'Fabricante', 'Ubicación'],
                data: dispositivos.map((d) {
                  return [
                    d.nombre,
                    d.ip,
                    d.mac,
                    d.fabricante.isEmpty ? '-' : d.fabricante,
                    d.ubicacion.isEmpty ? '-' : d.ubicacion,
                  ];
                }).toList(),
              ),

            pw.SizedBox(height: 20),
            pw.Divider(color: PdfColors.grey400),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Generado el ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ),
          ];
        },
      ),
    );

    // Muestra la vista previa, opción de guardar en PDF o imprimir
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Reporte_Red_${red.nombre.replaceAll(' ', '_')}.pdf',
    );
  }

  static pw.Widget _buildStat(String title, String value) {
    return pw.Column(
      children: [
        pw.Text(
          title,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: const PdfColor.fromInt(0xFF673AB7),
          ),
        ),
      ],
    );
  }
}