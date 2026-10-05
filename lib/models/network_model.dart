class NetworkModel {
  final String id;
  final String nombre;
  final String segmento;
  final String? vlan;
  final String? mascara;
  final String? gateway;

  NetworkModel({
    required this.id,
    required this.nombre,
    required this.segmento,
    this.vlan,
    this.mascara,
    this.gateway,
  });

  factory NetworkModel.fromJson(Map<String, dynamic> json) {
    return NetworkModel(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      segmento: json['segmento']?.toString() ?? '',
      // .toString() convierte números (ej. 10) o texto ("10") a String sin dar error
      vlan: json['vlan']?.toString(),
      mascara: json['mascara']?.toString(),
      gateway: json['gateway']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'segmento': segmento,
    if (vlan != null) 'vlan': vlan,
    if (mascara != null) 'mascara': mascara,
    if (gateway != null) 'gateway': gateway,
  };
}