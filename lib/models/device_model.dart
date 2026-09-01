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
    required this.id, required this.nombre, required this.mac,
    required this.fabricante, required this.ubicacion, required this.ip,
    required this.redId, this.redNombre,
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
    'nombre': nombre, 'mac': mac, 'fabricante': fabricante,
    'ubicacion': ubicacion, 'ip': ip, 'red_id': redId,
  };
}