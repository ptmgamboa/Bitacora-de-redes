import 'package:flutter/material.dart';
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

  // -- HISTORIAL DE AUDITORÍA Y CAMBIOS EN SUPABASE --
  Future<void> registrarCambio({
    required String tipo,      // 'red', 'dispositivo', 'vlan'
    required String accion,    // 'crear', 'editar', 'eliminar'
    required String titulo,
    required String detalle,
    String? nivel,
  }) async {
    try {
      await _supabase.from('historial_cambios').insert({
        'tipo': tipo,
        'accion': accion,
        'titulo': titulo,
        'detalle': detalle,
        'nivel': nivel ?? 'info',
        'usuario': _supabase.auth.currentUser?.email?.split('@').first ?? 'Administrador',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error al registrar cambio en BD: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getHistorialCambiosHoy() async {
    try {
      final res = await _supabase
          .from('historial_cambios')
          .select()
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> lista = List<Map<String, dynamic>>.from(res as List);

      for (var item in lista) {
        final dt = DateTime.tryParse(item['created_at']?.toString() ?? '')?.toLocal();
        if (dt != null) {
          final dia = dt.day.toString().padLeft(2, '0');
          final mes = dt.month.toString().padLeft(2, '0');
          final anio = dt.year;
          final hora = dt.hour.toString().padLeft(2, '0');
          final min = dt.minute.toString().padLeft(2, '0');

          item['fecha_formateada'] = '$dia/$mes/$anio $hora:$min';
          item['fecha'] = '$dia/$mes/$anio';
          item['hora'] = '$hora:$min';
        } else {
          item['fecha_formateada'] = '--/--/---- --:--';
        }
      }

      return lista;
    } catch (e) {
      debugPrint('Error al consultar historial: $e');
      return [];
    }
  }

  // -- REDES --
  Future<List<Map<String, dynamic>>> getRedes() async {
    return await _supabase.from('redes').select().order('created_at', ascending: false);
  }

  Future<void> addRed(Map<String, dynamic> data) async {
    // Solamente enviamos columnas existentes en la tabla 'redes'
    final payload = <String, dynamic>{
      'nombre': data['nombre'],
      'segmento': data['segmento'],
      'estado': data['estado'] ?? 'Activa',
    };

    await _supabase.from('redes').insert(payload);

    final nombre = payload['nombre'] ?? 'Red';
    final segmento = payload['segmento'] ?? '';

    await registrarCambio(
      tipo: 'red',
      accion: 'crear',
      titulo: 'Red Creada: $nombre',
      detalle: 'Segmento CIDR: $segmento',
    );
  }

  Future<void> updateRed(String id, Map<String, dynamic> data) async {
    Map<String, dynamic>? redAnterior;
    try {
      redAnterior = await _supabase.from('redes').select().eq('id', id).maybeSingle();
    } catch (_) {}

    final payload = <String, dynamic>{};
    if (data.containsKey('nombre')) payload['nombre'] = data['nombre'];
    if (data.containsKey('segmento')) payload['segmento'] = data['segmento'];
    if (data.containsKey('estado')) payload['estado'] = data['estado'];

    await _supabase.from('redes').update(payload).eq('id', id);

    final nombreNuevo = payload['nombre'] ?? redAnterior?['nombre'] ?? 'Red';
    List<String> cambios = [];

    if (redAnterior != null) {
      if (payload.containsKey('segmento') && payload['segmento'] != redAnterior['segmento']) {
        cambios.add('Segmento: ${redAnterior['segmento']} ➔ ${payload['segmento']}');
      }
      if (payload.containsKey('nombre') && payload['nombre'] != redAnterior['nombre']) {
        cambios.add('Nombre: "${redAnterior['nombre']}" ➔ "${payload['nombre']}"');
      }
      if (payload.containsKey('estado') && payload['estado'] != redAnterior['estado']) {
        cambios.add('Estado: ${redAnterior['estado']} ➔ ${payload['estado']}');
      }
    }

    final detalleTxt = cambios.isNotEmpty ? cambios.join(' | ') : 'Parámetros de la red actualizados.';

    await registrarCambio(
      tipo: 'red',
      accion: 'editar',
      titulo: 'Red Modificada: $nombreNuevo',
      detalle: detalleTxt,
    );
  }

  Future<void> deleteRed(String id) async {
    Map<String, dynamic>? redAnterior;
    try {
      redAnterior = await _supabase.from('redes').select().eq('id', id).maybeSingle();
    } catch (_) {}

    await _supabase.from('redes').delete().eq('id', id);

    final nombre = redAnterior?['nombre'] ?? 'Red';
    final segmento = redAnterior?['segmento'] ?? '';

    await registrarCambio(
      tipo: 'red',
      accion: 'eliminar',
      titulo: 'Red Eliminada: $nombre',
      detalle: 'Se dio de baja el segmento $segmento.',
      nivel: 'advertencia',
    );
  }

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

  Future<void> addDispositivo(Map<String, dynamic> data) async {
    await _supabase.from('dispositivos').insert(data);

    final nombre = data['nombre'] ?? 'Equipo';
    final ip = data['ip'] ?? '-';
    final mac = data['mac'] ?? '-';

    await registrarCambio(
      tipo: 'dispositivo',
      accion: 'crear',
      titulo: 'Dispositivo Agregado: $nombre',
      detalle: 'IP: $ip | MAC: $mac',
    );
  }

  Future<void> updateDispositivo(String id, Map<String, dynamic> data) async {
    Map<String, dynamic>? dispAnterior;
    try {
      dispAnterior = await _supabase.from('dispositivos').select().eq('id', id).maybeSingle();
    } catch (_) {}

    await _supabase.from('dispositivos').update(data).eq('id', id);

    final nombre = data['nombre'] ?? dispAnterior?['nombre'] ?? 'Equipo';
    List<String> cambios = [];

    if (dispAnterior != null) {
      if (data.containsKey('red_id') && data['red_id'] != dispAnterior['red_id']) {
        cambios.add('Movido de segmento de red');
      }
      if (data.containsKey('ip') && data['ip'] != dispAnterior['ip']) {
        cambios.add('IP cambiada: ${dispAnterior['ip']} ➔ ${data['ip']}');
      }
      if (data.containsKey('estado') && data['estado'] != dispAnterior['estado']) {
        cambios.add('Estado: ${dispAnterior['estado']} ➔ ${data['estado']}');
      }
      if (data.containsKey('ubicacion') && data['ubicacion'] != dispAnterior['ubicacion']) {
        cambios.add('Ubicación: ${data['ubicacion']}');
      }
    }

    final detalleTxt = cambios.isNotEmpty ? cambios.join(' | ') : 'Información general del dispositivo actualizada.';

    await registrarCambio(
      tipo: 'dispositivo',
      accion: 'editar',
      titulo: 'Dispositivo Actualizado: $nombre',
      detalle: detalleTxt,
    );
  }

  Future<void> deleteDispositivo(String id) async {
    Map<String, dynamic>? dispAnterior;
    try {
      dispAnterior = await _supabase.from('dispositivos').select().eq('id', id).maybeSingle();
    } catch (_) {}

    await _supabase.from('dispositivos').delete().eq('id', id);

    final nombre = dispAnterior?['nombre'] ?? 'Equipo';
    final ip = dispAnterior?['ip'] ?? '-';

    await registrarCambio(
      tipo: 'dispositivo',
      accion: 'eliminar',
      titulo: 'Dispositivo Eliminado: $nombre',
      detalle: 'Se eliminó el equipo con IP $ip.',
      nivel: 'advertencia',
    );
  }

  // -- VLANS PERSISTENTES EN SUPABASE --
  Future<List<Map<String, dynamic>>> getVlans() async {
    try {
      return await _supabase.from('vlans').select().order('vlan_id', ascending: true);
    } catch (_) {
      return [];
    }
  }

  Future<void> addVlan(Map<String, dynamic> data) async {
    await _supabase.from('vlans').insert(data);
    await registrarCambio(
      tipo: 'vlan',
      accion: 'crear',
      titulo: 'VLAN Creada: ${data['nombre']}',
      detalle: 'ID: ${data['vlan_id']} | ${data['descripcion'] ?? ''}',
    );
  }

  Future<void> updateVlan(String id, Map<String, dynamic> data) async {
    await _supabase.from('vlans').update(data).eq('id', id);
    await registrarCambio(
      tipo: 'vlan',
      accion: 'editar',
      titulo: 'VLAN Modificada: ${data['nombre']}',
      detalle: 'ID: ${data['vlan_id']} | Configuración actualizada',
    );
  }

  Future<void> deleteVlan(String id, String nombre, int vlanId) async {
    await _supabase.from('vlans').delete().eq('id', id);
    await registrarCambio(
      tipo: 'vlan',
      accion: 'eliminar',
      titulo: 'VLAN Eliminada: $nombre',
      detalle: 'Se eliminó la segmentación VLAN ID $vlanId.',
      nivel: 'advertencia',
    );
  }

  // -- CONSULTAS DINÁMICAS PARA DASHBOARD --
  Future<Map<String, dynamic>> getDatosDashboard() async {
    final redes = await _supabase.from('redes').select('id, nombre, segmento, created_at');
    final dispositivos = await _supabase.from('dispositivos').select('id, nombre, ip, red_id, created_at');

    final historialHoy = await getHistorialCambiosHoy();

    final now = DateTime.now();
    final hoyStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final cambiosHoyCount = historialHoy.where((h) {
      final ca = h['created_at']?.toString() ?? '';
      return ca.startsWith(hoyStr);
    }).length;

    List<Map<String, String>> notificaciones = [];

    final redesSinEquipos = redes.where((r) {
      return !dispositivos.any((d) => d['red_id'] == r['id']);
    }).toList();

    if (redesSinEquipos.isNotEmpty) {
      notificaciones.add({
        'titulo': 'Redes sin equipos asignados',
        'detalle': 'Hay ${redesSinEquipos.length} red(es) configurada(s) sin dispositivos vinculados.',
        'nivel': 'advertencia',
      });
    }

    if (dispositivos.isEmpty) {
      notificaciones.add({
        'titulo': 'Sin dispositivos en bitácora',
        'detalle': 'Aún no se han registrado equipos en la infraestructura.',
        'nivel': 'info',
      });
    } else {
      notificaciones.add({
        'titulo': 'Estado de Infraestructura',
        'detalle': 'Operando ${dispositivos.length} dispositivo(s) en ${redes.length} red(es).',
        'nivel': 'ok',
      });
    }

    return {
      'totalRedes': redes.length,
      'totalDispositivos': dispositivos.length,
      'cambiosHoy': cambiosHoyCount > 0 ? cambiosHoyCount : historialHoy.length,
      'notificaciones': notificaciones,
      'ultimosCambios': historialHoy,
    };
  }
}