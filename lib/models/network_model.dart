class NetworkModel {
  final String id;
  final String nombre;
  final String segmento;
  final String vlan;
  final String estado;
  final String? mascara;

  NetworkModel({
    required this.id,
    required this.nombre,
    required this.segmento,
    required this.vlan,
    this.estado = 'Activa',
    this.mascara,
  });

  factory NetworkModel.fromJson(Map<String, dynamic> json) {
    return NetworkModel(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
      segmento: json['segmento'] ?? '',
      vlan: json['vlan']?.toString() ?? '',
      estado: json['estado']?.toString() ?? 'Activa',
      mascara: json['mascara']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'segmento': segmento,
      'vlan': vlan,
      'estado': estado,
      if (mascara != null) 'mascara': mascara,
    };
  }
}