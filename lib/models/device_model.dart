import 'package:flutter/material.dart';

class DeviceModel {
  final String id;
  final String nombre;
  final String mac;
  final String fabricante;
  final String ubicacion;
  final String ip;
  final String redId;
  final String? redNombre; // Para mostrar en la UI sin hacer otra consulta

  DeviceModel({
    required this.id,
    required this.nombre,
    required this.mac,
    required this.fabricante,
    required this.ubicacion,
    required this.ip,
    required this.redId,
    this.redNombre,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      mac: json['mac'] as String,
      fabricante: json['fabricante'] as String,
      ubicacion: json['ubicacion'] as String,
      ip: json['ip'] as String,
      redId: json['red_id'] as String,
      redNombre: json['redes'] != null ? json['redes']['nombre'] : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'mac': mac,
    'fabricante': fabricante,
    'ubicacion': ubicacion,
    'ip': ip,
    'red_id': redId,
  };

  // --- LÓGICA DE CLASIFICACIÓN DINÁMICA ---
  String get tipoTexto {
    final lower = '$nombre $fabricante'.toLowerCase();
    if (lower.contains('switch') || lower.contains('sw') || lower.contains('cisco') || lower.contains('tp-link')) {
      return 'Switch';
    } else if (lower.contains('servidor') || lower.contains('server') || lower.contains('srv')) {
      return 'Servidor';
    } else if (lower.contains('celular') || lower.contains('cel') || lower.contains('phone') || lower.contains('movil') || lower.contains('móvil') || lower.contains('iphone') || lower.contains('android')) {
      return 'Celular';
    } else if (lower.contains('router') || lower.contains('gateway') || lower.contains('módem')) {
      return 'Router';
    } else if (lower.contains('impresora') || lower.contains('printer') || lower.contains('epson') || lower.contains('hp')) {
      return 'Impresora';
    } else if (lower.contains('pc') || lower.contains('lap') || lower.contains('laptop') || lower.contains('comp') || lower.contains('desktop')) {
      return 'Computadora';
    }
    return 'Dispositivo';
  }

  IconData get icono {
    switch (tipoTexto) {
      case 'Switch':
        return Icons.alt_route_rounded;
      case 'Servidor':
        return Icons.dns_rounded;
      case 'Celular':
        return Icons.smartphone_rounded;
      case 'Router':
        return Icons.router_rounded;
      case 'Impresora':
        return Icons.print_rounded;
      case 'Computadora':
        return Icons.computer_rounded;
      default:
        return Icons.devices_other_rounded;
    }
  }

  Color get colorTipo {
    switch (tipoTexto) {
      case 'Switch':
        return Colors.indigo;
      case 'Servidor':
        return Colors.deepOrange;
      case 'Celular':
        return Colors.teal;
      case 'Router':
        return const Color(0xFF673AB7);
      case 'Impresora':
        return Colors.amber.shade900;
      case 'Computadora':
        return Colors.blue;
      default:
        return Colors.grey.shade700;
    }
  }

  bool get esSwitch => tipoTexto == 'Switch';
}