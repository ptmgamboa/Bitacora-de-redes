import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_colors.dart';
import 'dashboard_view.dart';
import 'networks_view.dart';
import 'devices_view.dart';
import 'vlans_view.dart';
import 'reports_view.dart';
import 'profile_view.dart';
import 'notifications_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _selectedIndex = 0;
  int _unreadNotifCount = 0;

  static const List<String> _titulos = <String>[
    'Inicio',
    'Bitácora de Redes',
    'Dispositivos',
    'Segmentación VLAN',
    'Reportes',
    'Perfil',
  ];

  @override
  void initState() {
    super.initState();
    _cargarNotificacionesNoLeidas();
  }

  Future<void> _cargarNotificacionesNoLeidas() async {
    try {
      final res = await Supabase.instance.client
          .from('notificaciones')
          .select('id')
          .eq('leida', false);

      if (mounted) {
        setState(() {
          _unreadNotifCount = (res as List).length;
        });
      }
    } catch (_) {
      // Si no existe la tabla o falla la consulta, mantenemos en 0
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _cargarNotificacionesNoLeidas();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgetOptions = <Widget>[
      DashboardView(
        onNavigateTab: (index) => _onItemTapped(index),
      ),
      const NetworksView(),
      const DevicesView(),
      const VlansView(),
      const ReportsView(),
      const ProfileView(),
    ];

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          _titulos[_selectedIndex],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                tooltip: 'Ver Notificaciones',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsView()),
                  ).then((_) => _cargarNotificacionesNoLeidas());
                },
              ),
              if (_unreadNotifCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.statusCritical,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_unreadNotifCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        elevation: 8,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lan_outlined),
            activeIcon: Icon(Icons.lan_rounded),
            label: 'Redes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.devices_other_outlined),
            activeIcon: Icon(Icons.devices_other_rounded),
            label: 'Dispositivos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.alt_route_outlined),
            activeIcon: Icon(Icons.alt_route_rounded),
            label: 'VLANs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment_outlined),
            activeIcon: Icon(Icons.assessment_rounded),
            label: 'Reportes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}