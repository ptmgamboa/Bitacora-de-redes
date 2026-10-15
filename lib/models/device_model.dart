import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class DeviceModel {
  final String id;
  final String nombre;
  final String ip;
  final String mac;
  final String fabricante;
  final String ubicacion;
  final String? redId;
  final String? redNombre;
  final String tipo;
  final String estado; // 'Activo' o 'Inactivo'
  final Map<String, dynamic> detalles;
  final Map<String, dynamic>? configPuertos;

  DeviceModel({
    required this.id,
    required this.nombre,
    required this.ip,
    required this.mac,
    required this.fabricante,
    required this.ubicacion,
    this.redId,
    this.redNombre,
    this.tipo = 'pc',
    this.estado = 'Activo',
    this.detalles = const {},
    this.configPuertos,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    String? redNom;
    if (json['redes'] != null && json['redes'] is Map) {
      redNom = json['redes']['nombre'];
    }

    final tipoRaw = json['tipo']?.toString().toLowerCase();

    return DeviceModel(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
      ip: json['ip'] ?? '',
      mac: json['mac'] ?? '',
      fabricante: json['fabricante'] ?? '',
      ubicacion: json['ubicacion'] ?? '',
      redId: json['red_id']?.toString(),
      redNombre: redNom,
      tipo: (tipoRaw != null && tipoRaw.isNotEmpty) ? tipoRaw : 'pc',
      estado: json['estado']?.toString() ?? 'Activo',
      detalles: json['detalles'] is Map ? Map<String, dynamic>.from(json['detalles']) : {},
      configPuertos: json['config_puertos'] is Map ? Map<String, dynamic>.from(json['config_puertos']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'ip': ip,
      'mac': mac,
      'fabricante': fabricante,
      'ubicacion': ubicacion,
      'red_id': redId,
      'tipo': tipo,
      'estado': estado,
      'detalles': detalles,
      if (configPuertos != null) 'config_puertos': configPuertos,
    };
  }

  bool get esActivo => estado == 'Activo';
  bool get esSwitch => tipo == 'switch' || nombre.toLowerCase().contains('switch');

  IconData get icono {
    switch (tipo) {
      case 'router':
        return Icons.router_rounded;
      case 'switch':
        return Icons.settings_ethernet_rounded;
      case 'server':
        return Icons.dns_rounded;
      case 'ap':
        return Icons.wifi_tethering_rounded;
      case 'printer':
        return Icons.print_rounded;
      case 'laptop':
        return Icons.laptop_mac_rounded;
      case 'phone':
        return Icons.smartphone_rounded;
      case 'pc':
      default:
        return Icons.desktop_windows_rounded;
    }
  }

  Color get colorTipo {
    if (!esActivo) return AppColors.textSecondary;
    switch (tipo) {
      case 'router':
        return AppColors.router;
      case 'switch':
        return AppColors.switchNet;
      case 'server':
        return AppColors.server;
      case 'ap':
        return AppColors.accessPoint;
      case 'printer':
        return AppColors.printer;
      case 'laptop':
        return AppColors.laptop;
      case 'phone':
        return AppColors.phone;
      case 'pc':
      default:
        return AppColors.pc;
    }
  }

  String get tipoTexto {
    switch (tipo) {
      case 'router':
        return 'Router';
      case 'switch':
        return 'Switch';
      case 'server':
        return 'Servidor';
      case 'ap':
        return 'Access Point';
      case 'printer':
        return 'Impresora';
      case 'laptop':
        return 'Laptop';
      case 'phone':
        return 'Móvil';
      case 'pc':
      default:
        return 'PC Desktop';
    }
  }

  String get resumenDetalles {
    if (detalles.isEmpty) return '';
    if (tipo == 'router') {
      final gw = detalles['gateway'] ?? '';
      return gw.isNotEmpty ? 'Gateway: $gw' : '';
    } else if (tipo == 'ap') {
      final ssid = detalles['ssid'] ?? '';
      return ssid.isNotEmpty ? 'SSID: $ssid' : '';
    } else if (tipo == 'server') {
      final rol = detalles['rol'] ?? '';
      return rol.isNotEmpty ? 'Rol: $rol' : '';
    } else if (tipo == 'printer') {
      final prot = detalles['protocolo'] ?? '';
      return prot.isNotEmpty ? 'Protocolo: $prot' : '';
    } else if (tipo == 'pc' || tipo == 'laptop' || tipo == 'phone') {
      final usr = detalles['usuario_asignado'] ?? '';
      return usr.isNotEmpty ? 'Asignado a: $usr' : '';
    }
    return '';
  }
}