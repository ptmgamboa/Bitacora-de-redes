class NetworkModel {
  final String id;
  final String nombre;
  final String segmento;

  NetworkModel({required this.id, required this.nombre, required this.segmento});

  factory NetworkModel.fromJson(Map<String, dynamic> json) {
    return NetworkModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      segmento: json['segmento'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'nombre': nombre, 'segmento': segmento};
}