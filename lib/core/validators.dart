class Validators {
  static String? validarIPv4(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'La IP es obligatoria';
    final regex = RegExp(r'^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$');
    if (!regex.hasMatch(valor.trim())) return 'Formato IPv4 inválido (Ej. 192.168.1.15)';
    return null;
  }

  static String? validarMAC(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'La MAC es obligatoria';
    final regex = RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$');
    if (!regex.hasMatch(valor.trim())) return 'Formato MAC inválido (XX:XX:XX:XX:XX:XX)';
    return null;
  }

  static String? validarRed(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'El segmento es obligatorio';
    final regex = RegExp(r'^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\/([0-9]|[1-2][0-9]|3[0-2])$');
    if (!regex.hasMatch(valor.trim())) return 'Formato inválido (Ej: 192.168.1.0/24)';
    return null;
  }

  static String? requerido(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Este campo es obligatorio';
    return null;
  }
}