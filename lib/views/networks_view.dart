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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _service.getRedes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No hay redes registradas.'));

              final redes = snapshot.data!.map((e) => NetworkModel.fromJson(e)).toList();

              return ListView.builder(
                itemCount: redes.length,
                itemBuilder: (context, index) {
                  final r = redes[index];
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.router)),
                    title: Text(r.nombre),
                    subtitle: Text(r.segmento),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _mostrarFormulario(r)),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await _service.deleteRed(r.id);
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () => _mostrarFormulario(),
            icon: const Icon(Icons.add),
            label: const Text('Agregar Red'),
          ),
        )
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al guardar red')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.red == null ? 'Nueva Red' : 'Editar Red'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre (Ej. Administrativa)', border: OutlineInputBorder()),
              validator: Validators.requerido,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _segmentoCtrl,
              decoration: const InputDecoration(labelText: 'Segmento (Ej. 192.168.1.0/24)', border: OutlineInputBorder()),
              validator: Validators.validarRed,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }
}