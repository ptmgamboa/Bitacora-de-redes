import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;

  // -- AUTH --
  Future<void> login(String email, String password) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> logout() async => await _supabase.auth.signOut();

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // -- REDES --
  Future<List<Map<String, dynamic>>> getRedes() async {
    return await _supabase.from('redes').select().order('created_at', ascending: false);
  }

  Future<void> addRed(Map<String, dynamic> data) async =>
      await _supabase.from('redes').insert(data);

  Future<void> updateRed(String id, Map<String, dynamic> data) async =>
      await _supabase.from('redes').update(data).eq('id', id);

  Future<void> deleteRed(String id) async =>
      await _supabase.from('redes').delete().eq('id', id);

  // -- DISPOSITIVOS --
  Future<List<Map<String, dynamic>>> buscarDispositivos(String query) async {
    if (query.isEmpty) {
      return await _supabase
          .from('dispositivos')
          .select('*, redes(nombre, segmento)')
          .order('created_at', ascending: false);
    }
    return await _supabase
        .from('dispositivos')
        .select('*, redes(nombre, segmento)')
        .or(
        'nombre.ilike.%$query%,ip.ilike.%$query%,mac.ilike.%$query%,fabricante.ilike.%$query%,ubicacion.ilike.%$query%')
        .order('created_at', ascending: false);
  }

  Future<void> addDispositivo(Map<String, dynamic> data) async =>
      await _supabase.from('dispositivos').insert(data);

  Future<void> updateDispositivo(String id, Map<String, dynamic> data) async =>
      await _supabase.from('dispositivos').update(data).eq('id', id);

  Future<void> deleteDispositivo(String id) async =>
      await _supabase.from('dispositivos').delete().eq('id', id);

  // -- CONSULTAS DINÁMICAS PARA DASHBOARD --
  Future<Map<String, dynamic>> getDatosDashboard() async {
    final redes = await _supabase.from('redes').select('id, nombre, segmento, created_at');
    final dispositivos = await _supabase.from('dispositivos').select('id, nombre, ip, red_id, created_at');

    final now = DateTime.now();
    final inicioHoy = DateTime(now.year, now.month, now.day);

    // Calcular cambios recientes (registros creados hoy)
    int cambiosHoy = 0;
    List<Map<String, dynamic>> ultimosCambios = [];

    for (var r in redes) {
      final fecha = DateTime.tryParse(r['created_at'] ?? '');
      if (fecha != null) {
        if (fecha.isAfter(inicioHoy)) cambiosHoy++;
        ultimosCambios.add({
          'titulo': 'Red creada: ${r['nombre']}',
          'subtitulo': 'Segmento: ${r['segmento']}',
          'fecha': fecha,
          'tipo': 'red',
        });
      }
    }

    for (var d in dispositivos) {
      final fecha = DateTime.tryParse(d['created_at'] ?? '');
      if (fecha != null) {
        if (fecha.isAfter(inicioHoy)) cambiosHoy++;
        ultimosCambios.add({
          'titulo': 'Dispositivo añadido: ${d['nombre']}',
          'subtitulo': 'IP: ${d['ip']}',
          'fecha': fecha,
          'tipo': 'dispositivo',
        });
      }
    }

    // Ordenar los últimos cambios cronológicamente
    ultimosCambios.sort((a, b) => (b['fecha'] as DateTime).compareTo(a['fecha'] as DateTime));

    // Generación dinámica de Notificaciones según el estado real de la BD
    List<Map<String, String>> notificaciones = [];

    final redesSinEquipos = redes.where((r) {
      return !dispositivos.any((d) => d['red_id'] == r['id']);
    }).toList();

    if (redesSinEquipos.isNotEmpty) {
      notificaciones.add({
        'titulo': 'Redes sin dispositivos asignados',
        'detalle': 'Hay ${redesSinEquipos.length} red(es) sin equipos registrados.',
        'nivel': 'advertencia',
      });
    }

    if (dispositivos.isEmpty) {
      notificaciones.add({
        'titulo': 'Sin dispositivos registrados',
        'detalle': 'Aún no has registrado ningún equipo en la bitácora.',
        'nivel': 'info',
      });
    } else {
      notificaciones.add({
        'titulo': 'Infraestructura activa',
        'detalle': 'Se están monitoreando ${dispositivos.length} dispositivos en ${redes.length} redes.',
        'nivel': 'ok',
      });
    }

    return {
      'totalRedes': redes.length,
      'totalDispositivos': dispositivos.length,
      'cambiosHoy': cambiosHoy,
      'notificaciones': notificaciones,
      'ultimosCambios': ultimosCambios.take(5).toList(),
      'redesLista': redes,
    };
  }
}