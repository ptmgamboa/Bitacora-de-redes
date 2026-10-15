import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'dashboard_view.dart';
import 'networks_view.dart';
import 'devices_view.dart';
import 'vlans_view.dart';
import 'reports_view.dart';
import 'profile_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _selectedIndex = 0;

  static const List<String> _titulos = <String>[
    'Inicio',
    'Bitácora de Redes',
    'Dispositivos',
    'Segmentación VLAN',
    'Reportes',
    'Perfil',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 1,
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
            activeIcon: Icon(Icons.dashboard),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lan_outlined),
            activeIcon: Icon(Icons.lan),
            label: 'Redes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.devices_other_outlined),
            activeIcon: Icon(Icons.devices_other),
            label: 'Dispositivos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.alt_route_outlined),
            activeIcon: Icon(Icons.alt_route_rounded),
            label: 'VLANs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment_outlined),
            activeIcon: Icon(Icons.assessment),
            label: 'Reportes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}