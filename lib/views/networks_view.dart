import 'package:flutter/material.dart';
import '../models/network_model.dart';
import '../services/supabase_service.dart';
import '../core/validators.dart';

class NetworksView extends StatefulWidget {
  const NetworksView({super.key});

  @override
  State<NetworksView> createState() => _NetworksViewState();
}

class _NetworksViewState extends State<NetworksView> {
  final _service = SupabaseService();

  void _mostrarFormulario([NetworkModel? red]) {
    showDialog(
      context: context,
      builder: (context) => _NetworkFormDialog(red: red, onSaved: () => setState(() {})),
    );
  }

  void _confirmarEliminar(NetworkModel r) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Eliminar Red'),
          ],
        ),
        content: Text('¿Deseas eliminar la red "${r.nombre}" (${r.segmento})? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _service.deleteRed(r.id);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Red eliminada correctamente'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1565C0);

    return Column(
      children: [
        // Lista de redes
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _service.getRedes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.router_outlined, size: 48, color: Colors.grey.shade400),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No hay redes registradas.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              final redes = snapshot.data!.map((e) => NetworkModel.fromJson(e)).toList();

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: redes.length,
                itemBuilder: (context, index) {
                  final r = redes[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          // Icono de red estilizado
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: primaryBlue.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.router_rounded, color: primaryBlue, size: 24),
                          ),
                          const SizedBox(width: 14),

                          // Información de la red
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: primaryBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    r.segmento,
                                    style: const TextStyle(
                                      color: primaryBlue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Acciones
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: primaryBlue, size: 20),
                                tooltip: 'Editar',
                                onPressed: () => _mostrarFormulario(r),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                tooltip: 'Eliminar',
                                onPressed: () => _confirmarEliminar(r),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Botón inferior para agregar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () => _mostrarFormulario(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Agregar Red'),
          ),
        ),
      ],
    );
  }
}

// --- FORMULARIO EMERGENTE PARA REDES ---
class _NetworkFormDialog extends StatefulWidget {
  final NetworkModel? red;
  final VoidCallback onSaved;

  const _NetworkFormDialog({this.red, required this.onSaved});

  @override
  State<_NetworkFormDialog> createState() => _NetworkFormDialogState();
}

class _NetworkFormDialogState extends State<_NetworkFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _segmentoCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.red != null) {
      _nombreCtrl.text = widget.red!.nombre;
      _segmentoCtrl.text = widget.red!.segmento;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _segmentoCtrl.dispose();
    super.dispose();
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = {
      'nombre': _nombreCtrl.text.trim(),
      'segmento': _segmentoCtrl.text.trim(),
    };

    try {
      if (widget.red == null) {
        await SupabaseService().addRed(data);
      } else {
        await SupabaseService().updateRed(widget.red!.id, data);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar la red'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1565C0);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Row(
        children: [
          Icon(
            widget.red == null ? Icons.add_rounded : Icons.edit_note_rounded,
            color: primaryBlue,
          ),
          const SizedBox(width: 8),
          Text(
            widget.red == null ? 'Nueva Red' : 'Editar Red',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Red',
                  hintText: 'Ej. Administrativa, Docentes',
                ),
                validator: Validators.requerido,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _segmentoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Segmento (CIDR)',
                  hintText: 'Ej. 192.168.1.0/24',
                ),
                validator: Validators.validarRed,
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.all(16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        SizedBox(
          width: 110,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _guardar,
            child: _isLoading
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Text('Guardar'),
          ),
        ),
      ],
    );
  }
}