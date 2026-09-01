import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;

  // -- AUTH --
  Future<void> login(String email, String password) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }
  Future<void> logout() async => await _supabase.auth.signOut();

  // -- REDES --
  Future<List<Map<String, dynamic>>> getRedes() async {
    return await _supabase.from('redes').select().order('created_at');
  }
  Future<void> addRed(Map<String, dynamic> data) async => await _supabase.from('redes').insert(data);
  Future<void> updateRed(String id, Map<String, dynamic> data) async => await _supabase.from('redes').update(data).eq('id', id);
  Future<void> deleteRed(String id) async => await _supabase.from('redes').delete().eq('id', id);

  // -- DISPOSITIVOS --
  Future<List<Map<String, dynamic>>> buscarDispositivos(String query) async {
    if (query.isEmpty) {
      return await _supabase.from('dispositivos').select('*, redes(nombre, segmento)').order('created_at');
    }
    return await _supabase.from('dispositivos')
        .select('*, redes(nombre, segmento)')
        .or('nombre.ilike.%$query%,ip.ilike.%$query%,mac.ilike.%$query%,fabricante.ilike.%$query%,ubicacion.ilike.%$query%')
        .order('created_at');
  }
  Future<void> addDispositivo(Map<String, dynamic> data) async => await _supabase.from('dispositivos').insert(data);
  Future<void> updateDispositivo(String id, Map<String, dynamic> data) async => await _supabase.from('dispositivos').update(data).eq('id', id);
  Future<void> deleteDispositivo(String id) async => await _supabase.from('dispositivos').delete().eq('id', id);
}