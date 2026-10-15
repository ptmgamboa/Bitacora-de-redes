import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_colors.dart';
import '../models/device_model.dart';
import '../models/network_model.dart';
import '../services/supabase_service.dart';
import '../core/validators.dart';

class DevicesView extends StatefulWidget {
  const DevicesView({super.key});

  @override
  State<DevicesView> createState() => _DevicesViewState();
}

class _DevicesViewState extends State<DevicesView> {
  final _service = SupabaseService();
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleEstadoDispositivo(DeviceModel d) async {
    final nuevoEstado = d.esActivo ? 'Inactivo' : 'Activo';
    try {
      await Supabase.instance.client
          .from('dispositivos')
          .update({'estado': nuevoEstado})
          .eq('id', d.id);

      await _service.registrarCambio(
        tipo: 'dispositivo',
        accion: 'editar',
        titulo: 'Estado Cambiado: ${d.nombre}',
        detalle: 'El dispositivo cambió de ${d.estado} a $nuevoEstado',
        nivel: nuevoEstado == 'Inactivo' ? 'advertencia' : 'info',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dispositivo marcado como $nuevoEstado'),
            backgroundColor: nuevoEstado == 'Activo' ? AppColors.statusActive : AppColors.statusWarning,
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cambiar estado: $e'), backgroundColor: AppColors.statusCritical),
        );
      }
    }
  }

  Future<void> _eliminarDispositivo(dynamic id, String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Dispositivo'),
        content: Text('¿Estás seguro de que deseas eliminar "$nombre"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusCritical,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteDispositivo(id.toString());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dispositivo eliminado correctamente'),
              backgroundColor: AppColors.statusActive,
            ),
          );
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar dispositivo: $e'),
              backgroundColor: AppColors.statusCritical,
            ),
          );
        }
      }
    }
  }

  void _abrirFormulario([DeviceModel? d]) {
    showDialog(
      context: context,
      builder: (context) => _DeviceFormDialog(
        dispositivo: d,
        onSaved: () => setState(() {}),
      ),
    );
  }

  void _abrirConfiguracionPuertos(DeviceModel d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PortConfigModal(dispositivo: d),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por IP, MAC, Nombre, Fabricante o Tipo...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                  onPressed: () => _searchCtrl.clear(),
                )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.0),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.0),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),

          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _service.buscarDispositivos(_searchQuery),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Error al cargar dispositivos: ${snapshot.error}',
                        style: const TextStyle(color: AppColors.statusCritical),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.devices_other, size: 70, color: AppColors.textSecondary.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No hay dispositivos registrados.'
                              : 'No se encontraron coincidencias.',
                          style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                final dispositivos = snapshot.data!.map((e) => DeviceModel.fromJson(e)).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  itemCount: dispositivos.length,
                  itemBuilder: (context, index) {
                    final d = dispositivos[index];
                    final redNombre = (d.redNombre != null && d.redNombre!.isNotEmpty)
                        ? d.redNombre!
                        : 'Sin Red';
                    final resumen = d.resumenDetalles;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      decoration: BoxDecoration(
                        color: d.esActivo ? AppColors.surface : AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: d.colorTipo.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                d.icono,
                                color: d.colorTipo,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          d.nombre,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: d.esActivo ? AppColors.textPrimary : AppColors.textSecondary,
                                            decoration: d.esActivo ? null : TextDecoration.lineThrough,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => _toggleEstadoDispositivo(d),
                                        borderRadius: BorderRadius.circular(8),
                                        child: _buildBadge(
                                          icon: d.esActivo ? Icons.check_circle_rounded : Icons.pause_circle_filled_rounded,
                                          text: d.esActivo ? 'ACTIVE' : 'CRITICAL',
                                          bgColor: d.esActivo ? AppColors.statusActiveBg : AppColors.statusCriticalBg,
                                          textColor: d.esActivo ? AppColors.statusActive : AppColors.statusCritical,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _buildBadge(
                                        icon: d.icono,
                                        text: d.tipoTexto,
                                        bgColor: d.colorTipo.withOpacity(0.12),
                                        textColor: d.colorTipo,
                                      ),
                                      _buildBadge(
                                        icon: Icons.wifi,
                                        text: d.ip,
                                        bgColor: AppColors.primary.withOpacity(0.08),
                                        textColor: AppColors.primary,
                                      ),
                                      _buildBadge(
                                        icon: Icons.alt_route,
                                        text: redNombre,
                                        bgColor: AppColors.secondary.withOpacity(0.12),
                                        textColor: AppColors.secondary,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  Text(
                                    'MAC: ${d.mac}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  if (d.fabricante.isNotEmpty || d.ubicacion.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        '${d.fabricante}${d.fabricante.isNotEmpty && d.ubicacion.isNotEmpty ? ' • ' : ''}${d.ubicacion}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  if (resumen.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        resumen,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            Column(
                              children: [
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(6),
                                  icon: Icon(
                                    Icons.settings_ethernet_rounded,
                                    color: d.esSwitch ? AppColors.primary : AppColors.textSecondary,
                                    size: 22,
                                  ),
                                  tooltip: 'Configuración de Puertos / VLANs',
                                  onPressed: () => _abrirConfiguracionPuertos(d),
                                ),
                                const SizedBox(height: 4),
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(6),
                                  icon: const Icon(Icons.edit_outlined,
                                      color: AppColors.secondary, size: 22),
                                  onPressed: () => _abrirFormulario(d),
                                ),
                                const SizedBox(height: 4),
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(6),
                                  icon: const Icon(Icons.delete_outline,
                                      color: AppColors.statusCritical, size: 22),
                                  onPressed: () => _eliminarDispositivo(d.id, d.nombre),
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
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'btn_devices_view_fab',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Agregar Dispositivo', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String text,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// --- MODAL DE CONFIGURACIÓN DE PUERTOS Y VLANS ---
class _PortConfigModal extends StatefulWidget {
  final DeviceModel dispositivo;

  const _PortConfigModal({required this.dispositivo});

  @override
  State<_PortConfigModal> createState() => _PortConfigModalState();
}

class _PortConfigModalState extends State<_PortConfigModal> {
  final _service = SupabaseService();
  int _totalPuertos = 24;
  int _puertoSeleccionado = 1;
  bool _isLoading = true;
  bool _isSaving = false;
  Map<int, Map<String, dynamic>> _configPuertos = {};

  @override
  void initState() {
    super.initState();
    _cargarConfiguracionSupabase();
  }

  Future<void> _cargarConfiguracionSupabase() async {
    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client
          .from('dispositivos')
          .select('config_puertos')
          .eq('id', widget.dispositivo.id)
          .maybeSingle();

      if (res != null && res['config_puertos'] != null) {
        final cfgMap = res['config_puertos'] as Map<String, dynamic>;
        final total = (cfgMap['totalPuertos'] as num?)?.toInt() ?? 24;
        final puertosRaw = cfgMap['puertos'] as Map<String, dynamic>?;

        Map<int, Map<String, dynamic>> parsedPuertos = {};
        if (puertosRaw != null) {
          puertosRaw.forEach((key, value) {
            final pInt = int.tryParse(key);
            if (pInt != null && value is Map) {
              parsedPuertos[pInt] = Map<String, dynamic>.from(value);
            }
          });
        }

        if (mounted) {
          setState(() {
            _totalPuertos = total;
            if (parsedPuertos.isNotEmpty) {
              _configPuertos = parsedPuertos;
            } else {
              _inicializarPuertos(total);
            }
          });
        }
      } else {
        _inicializarPuertos(24);
      }
    } catch (e) {
      debugPrint('Error al cargar config_puertos: $e');
      _inicializarPuertos(24);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _inicializarPuertos(int cantidad) {
    _totalPuertos = cantidad;
    _configPuertos = {};
    for (int i = 1; i <= _totalPuertos; i++) {
      _configPuertos[i] = {
        'vlan': (i % 2 == 0) ? 10 : 20,
        'modo': (i == 1) ? 'Trunk' : 'Acceso',
        'activo': true,
      };
    }
    if (_puertoSeleccionado > _totalPuertos) {
      _puertoSeleccionado = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfgActual = _configPuertos[_puertoSeleccionado] ?? {'vlan': 10, 'modo': 'Acceso'};
    final isTrunkActual = cfgActual['modo'] == 'Trunk';

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20.0),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.settings_ethernet, color: AppColors.primary, size: 26),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Puertos & VLANs - ${widget.dispositivo.nombre}',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      'Gestión de puertos física y asignación VLAN',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Capacidad del Switch:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButton<int>(
                  value: _totalPuertos,
                  underline: const SizedBox(),
                  isDense: true,
                  items: const [8, 16, 24, 48].map((n) {
                    return DropdownMenuItem(value: n, child: Text('$n Puertos', style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _inicializarPuertos(val);
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.25,
              ),
              itemCount: _totalPuertos,
              itemBuilder: (context, index) {
                final puerto = index + 1;
                final cfg = _configPuertos[puerto] ?? {'vlan': 10, 'modo': 'Acceso'};
                final isTrunk = cfg['modo'] == 'Trunk';
                final isSelected = puerto == _puertoSeleccionado;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _puertoSeleccionado = puerto;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.12)
                          : (isTrunk ? AppColors.statusWarningBg : AppColors.background),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : (isTrunk ? AppColors.statusWarning : AppColors.border),
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.settings_input_component_rounded,
                          size: 16,
                          color: isSelected
                              ? AppColors.primary
                              : (isTrunk ? AppColors.statusWarning : AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'P$puerto',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          isTrunk ? 'TRUNK' : 'VLAN ${cfg['vlan']}',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isTrunk ? AppColors.statusWarning : AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Configuración del Puerto P$_puertoSeleccionado',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isTrunkActual ? AppColors.statusWarningBg : AppColors.statusActiveBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isTrunkActual ? 'Modo Troncal (Trunk)' : 'Modo Acceso',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isTrunkActual ? AppColors.statusWarning : AppColors.statusActive,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: BorderSide(color: isTrunkActual ? AppColors.primary : AppColors.border),
                        ),
                        icon: Icon(
                          isTrunkActual ? Icons.check_circle : Icons.swap_horiz,
                          size: 16,
                          color: isTrunkActual ? AppColors.primary : AppColors.textSecondary,
                        ),
                        label: Text(
                          isTrunkActual ? 'Cambiar a Acceso' : 'Cambiar a Trunk',
                          style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                        ),
                        onPressed: () {
                          setState(() {
                            cfgActual['modo'] = isTrunkActual ? 'Acceso' : 'Trunk';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Row(
                        children: [
                          const Text('VLAN ID:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: DropdownButton<int>(
                                value: cfgActual['vlan'] as int,
                                isExpanded: true,
                                underline: const SizedBox(),
                                isDense: true,
                                items: [10, 20, 30, 40, 50, 100].map((vlanId) {
                                  return DropdownMenuItem(
                                    value: vlanId,
                                    child: Text('VLAN $vlanId', style: const TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                                  );
                                }).toList(),
                                onChanged: isTrunkActual
                                    ? null
                                    : (val) {
                                  if (val != null) {
                                    setState(() {
                                      cfgActual['vlan'] = val;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: _isSaving
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                setState(() => _isSaving = true);
                try {
                  final portsJson = {};
                  _configPuertos.forEach((key, value) {
                    portsJson[key.toString()] = value;
                  });

                  final payload = {
                    'totalPuertos': _totalPuertos,
                    'puertos': portsJson,
                  };

                  await Supabase.instance.client
                      .from('dispositivos')
                      .update({'config_puertos': payload})
                      .eq('id', widget.dispositivo.id);

                  await _service.registrarCambio(
                    tipo: 'dispositivo',
                    accion: 'editar',
                    titulo: 'Puertos Configurados: ${widget.dispositivo.nombre}',
                    detalle: 'Switch fijado a $_totalPuertos puertos. Puerto P$_puertoSeleccionado en VLAN ${cfgActual['vlan']} (${cfgActual['modo']}).',
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Configuración de $_totalPuertos puertos guardada'),
                        backgroundColor: AppColors.statusActive,
                      ),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al guardar configuración: $e'),
                        backgroundColor: AppColors.statusCritical,
                      ),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isSaving = false);
                }
              },
              child: const Text('Guardar Configuración'),
            ),
          ),
        ],
      ),
    );
  }
}

// --- FORMULARIO EMERGENTE DINÁMICO ---
class _DeviceFormDialog extends StatefulWidget {
  final DeviceModel? dispositivo;
  final VoidCallback onSaved;

  const _DeviceFormDialog({this.dispositivo, required this.onSaved});

  @override
  State<_DeviceFormDialog> createState() => _DeviceFormDialogState();
}

class _DeviceFormDialogState extends State<_DeviceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _macCtrl = TextEditingController();
  final _fabCtrl = TextEditingController();
  final _ubicaCtrl = TextEditingController();
  final _ipCtrl = TextEditingController();

  final _gatewayCtrl = TextEditingController();
  final _wanCtrl = TextEditingController();
  final _ssidCtrl = TextEditingController();
  final _soCtrl = TextEditingController();
  final _protocoloPrintCtrl = TextEditingController();
  final _usuarioCtrl = TextEditingController();

  String _frecuenciaVal = 'Dual Band (2.4/5 GHz)';
  String _rolServerVal = 'General / Aplicaciones';

  String? _selectedRedId;
  String _selectedTipo = 'pc';
  String _selectedEstado = 'Activo';
  List<NetworkModel> _redesDisponibles = [];
  bool _isLoading = true;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _tiposOpciones = [
    {'value': 'pc', 'label': 'PC Desktop', 'icon': Icons.desktop_windows_rounded},
    {'value': 'laptop', 'label': 'Laptop', 'icon': Icons.laptop_mac_rounded},
    {'value': 'router', 'label': 'Router', 'icon': Icons.router_rounded},
    {'value': 'switch', 'label': 'Switch', 'icon': Icons.settings_ethernet_rounded},
    {'value': 'server', 'label': 'Servidor', 'icon': Icons.dns_rounded},
    {'value': 'ap', 'label': 'Access Point (Wi-Fi)', 'icon': Icons.wifi_tethering_rounded},
    {'value': 'printer', 'label': 'Impresora de Red', 'icon': Icons.print_rounded},
    {'value': 'phone', 'label': 'Smartphone / Tablet', 'icon': Icons.smartphone_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _cargarRedes();
    if (widget.dispositivo != null) {
      final d = widget.dispositivo!;
      _nombreCtrl.text = d.nombre;
      _macCtrl.text = d.mac;
      _fabCtrl.text = d.fabricante;
      _ubicaCtrl.text = d.ubicacion;
      _ipCtrl.text = d.ip;
      _selectedRedId = d.redId;
      _selectedTipo = d.tipo;
      _selectedEstado = d.estado;

      _gatewayCtrl.text = d.detalles['gateway'] ?? '';
      _wanCtrl.text = d.detalles['wan_interface'] ?? '';
      _ssidCtrl.text = d.detalles['ssid'] ?? '';
      _soCtrl.text = d.detalles['so'] ?? '';
      _protocoloPrintCtrl.text = d.detalles['protocolo'] ?? '';
      _usuarioCtrl.text = d.detalles['usuario_asignado'] ?? '';
      if (d.detalles['frecuencia'] != null) _frecuenciaVal = d.detalles['frecuencia'];
      if (d.detalles['rol'] != null) _rolServerVal = d.detalles['rol'];
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _macCtrl.dispose();
    _fabCtrl.dispose();
    _ubicaCtrl.dispose();
    _ipCtrl.dispose();
    _gatewayCtrl.dispose();
    _wanCtrl.dispose();
    _ssidCtrl.dispose();
    _soCtrl.dispose();
    _protocoloPrintCtrl.dispose();
    _usuarioCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarRedes() async {
    try {
      final res = await SupabaseService().getRedes();
      if (mounted) {
        setState(() {
          _redesDisponibles = res.map((e) => NetworkModel.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate() || _selectedRedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, completa todos los campos requeridos'),
          backgroundColor: AppColors.statusWarning,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    Map<String, dynamic> detallesMap = {};
    if (_selectedTipo == 'router') {
      detallesMap = {
        'gateway': _gatewayCtrl.text.trim(),
        'wan_interface': _wanCtrl.text.trim(),
      };
    } else if (_selectedTipo == 'ap') {
      detallesMap = {
        'ssid': _ssidCtrl.text.trim(),
        'frecuencia': _frecuenciaVal,
      };
    } else if (_selectedTipo == 'server') {
      detallesMap = {
        'rol': _rolServerVal,
        'so': _soCtrl.text.trim(),
      };
    } else if (_selectedTipo == 'printer') {
      detallesMap = {
        'protocolo': _protocoloPrintCtrl.text.trim(),
      };
    } else if (_selectedTipo == 'pc' || _selectedTipo == 'laptop' || _selectedTipo == 'phone') {
      detallesMap = {
        'usuario_asignado': _usuarioCtrl.text.trim(),
      };
    }

    final data = {
      'nombre': _nombreCtrl.text.trim(),
      'mac': _macCtrl.text.trim().toUpperCase(),
      'fabricante': _fabCtrl.text.trim(),
      'ubicacion': _ubicaCtrl.text.trim(),
      'ip': _ipCtrl.text.trim(),
      'red_id': _selectedRedId,
      'tipo': _selectedTipo,
      'estado': _selectedEstado,
      'detalles': detallesMap,
    };

    try {
      if (widget.dispositivo == null) {
        await SupabaseService().addDispositivo(data);
      } else {
        await SupabaseService().updateDispositivo(widget.dispositivo!.id, data);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: AppColors.statusCritical,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildCamposEspeciales() {
    switch (_selectedTipo) {
      case 'router':
        return Column(
          children: [
            const SizedBox(height: 12),
            TextFormField(
              controller: _gatewayCtrl,
              decoration: const InputDecoration(
                labelText: 'IP Gateway por Defecto',
                prefixIcon: Icon(Icons.alt_route, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _wanCtrl,
              decoration: const InputDecoration(
                labelText: 'Interfaz WAN / ISP',
                prefixIcon: Icon(Icons.public_rounded, color: AppColors.primary),
              ),
            ),
          ],
        );

      case 'ap':
        return Column(
          children: [
            const SizedBox(height: 12),
            TextFormField(
              controller: _ssidCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre de Red Wi-Fi (SSID)',
                prefixIcon: Icon(Icons.wifi_lock_rounded, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _frecuenciaVal,
              decoration: const InputDecoration(
                labelText: 'Banda / Frecuencia Wi-Fi',
                prefixIcon: Icon(Icons.cell_tower_rounded, color: AppColors.primary),
              ),
              items: const [
                DropdownMenuItem(value: '2.4 GHz', child: Text('2.4 GHz')),
                DropdownMenuItem(value: '5 GHz', child: Text('5 GHz')),
                DropdownMenuItem(value: 'Dual Band (2.4/5 GHz)', child: Text('Dual Band (2.4/5 GHz)')),
                DropdownMenuItem(value: 'Wi-Fi 6 / 6E', child: Text('Wi-Fi 6 / 6E')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _frecuenciaVal = val);
              },
            ),
          ],
        );

      case 'server':
        return Column(
          children: [
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _rolServerVal,
              decoration: const InputDecoration(
                labelText: 'Rol Principal del Servidor',
                prefixIcon: Icon(Icons.dns_outlined, color: AppColors.primary),
              ),
              items: const [
                DropdownMenuItem(value: 'Active Directory / Dominios', child: Text('Active Directory / Dominios')),
                DropdownMenuItem(value: 'Base de Datos (SQL)', child: Text('Base de Datos (SQL)')),
                DropdownMenuItem(value: 'Servidor Web / API', child: Text('Servidor Web / API')),
                DropdownMenuItem(value: 'Almacenamiento / NAS', child: Text('Almacenamiento / NAS')),
                DropdownMenuItem(value: 'DHCP / DNS Principal', child: Text('DHCP / DNS Principal')),
                DropdownMenuItem(value: 'General / Aplicaciones', child: Text('General / Aplicaciones')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _rolServerVal = val);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _soCtrl,
              decoration: const InputDecoration(
                labelText: 'Sistema Operativo',
                prefixIcon: Icon(Icons.computer_rounded, color: AppColors.primary),
              ),
            ),
          ],
        );

      case 'printer':
        return Column(
          children: [
            const SizedBox(height: 12),
            TextFormField(
              controller: _protocoloPrintCtrl,
              decoration: const InputDecoration(
                labelText: 'Protocolo / Cola de Impresión',
                prefixIcon: Icon(Icons.print_outlined, color: AppColors.primary),
              ),
            ),
          ],
        );

      case 'pc':
      case 'laptop':
      case 'phone':
        return Column(
          children: [
            const SizedBox(height: 12),
            TextFormField(
              controller: _usuarioCtrl,
              decoration: const InputDecoration(
                labelText: 'Usuario / Departamento Asignado',
                prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primary),
              ),
            ),
          ],
        );

      case 'switch':
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AlertDialog(
        backgroundColor: AppColors.surface,
        content: SizedBox(
          height: 120,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    }

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      title: Row(
        children: [
          const Icon(Icons.devices, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            widget.dispositivo == null ? 'Nuevo Dispositivo' : 'Editar Dispositivo',
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.65,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedTipo,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Dispositivo',
                      prefixIcon: Icon(Icons.category_outlined, color: AppColors.primary),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: _tiposOpciones.map((item) {
                      return DropdownMenuItem<String>(
                        value: item['value'] as String,
                        child: Row(
                          children: [
                            Icon(item['icon'] as IconData, size: 20, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item['label'] as String,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedTipo = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedEstado,
                    decoration: const InputDecoration(
                      labelText: 'Estado Operativo',
                      prefixIcon: Icon(Icons.toggle_on_outlined, color: AppColors.primary),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Activo', child: Text('Activo (En Producción)', style: TextStyle(color: AppColors.textPrimary))),
                      DropdownMenuItem(value: 'Inactivo', child: Text('Inactivo / Mantenimiento', style: TextStyle(color: AppColors.textPrimary))),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedEstado = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _nombreCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre (Ej. Router-Borde, SW-Core, PC-Admin)',
                      prefixIcon: Icon(Icons.badge_outlined, color: AppColors.primary),
                    ),
                    validator: Validators.requerido,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _ipCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Dirección IPv4',
                      prefixIcon: Icon(Icons.numbers, color: AppColors.primary),
                    ),
                    validator: Validators.validarIPv4,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _macCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Dirección MAC (XX:XX:XX:XX:XX:XX)',
                      prefixIcon: Icon(Icons.lan_outlined, color: AppColors.primary),
                    ),
                    validator: Validators.validarMAC,
                    inputFormatters: [
                      MacAddressFormatter(),
                      LengthLimitingTextInputFormatter(17),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _fabCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Fabricante (Ej. Cisco, Mikrotik, HP, Dell, TP-Link)',
                      prefixIcon: Icon(Icons.precision_manufacturing_outlined, color: AppColors.primary),
                    ),
                    validator: Validators.requerido,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _ubicaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ubicación / Rack / Oficina',
                      prefixIcon: Icon(Icons.place_outlined, color: AppColors.primary),
                    ),
                    validator: Validators.requerido,
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedRedId,
                    decoration: const InputDecoration(
                      labelText: 'Red Asociada',
                      prefixIcon: Icon(Icons.router_outlined, color: AppColors.primary),
                    ),
                    items: _redesDisponibles.map((red) {
                      return DropdownMenuItem(
                        value: red.id,
                        child: Text(
                          '${red.nombre} (${red.segmento})',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedRedId = val),
                    validator: (val) => val == null || val.isEmpty ? 'Seleccione una red' : null,
                  ),

                  _buildCamposEspeciales(),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
        ),
        _isSaving
            ? const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
        )
            : ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          ),
          onPressed: _guardar,
          child: Text(widget.dispositivo == null ? 'Guardar' : 'Actualizar'),
        ),
      ],
    );
  }
}

class MacAddressFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (oldValue.text.length >= newValue.text.length) {
      return newValue.copyWith(text: newValue.text.toUpperCase());
    }

    var text = newValue.text.replaceAll(':', '').toUpperCase();
    var buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 2 == 0 && nonZeroIndex != 12) {
        buffer.write(':');
      }
    }

    var string = buffer.toString();

    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}