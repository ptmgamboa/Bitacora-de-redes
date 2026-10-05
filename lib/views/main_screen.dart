import 'package:flutter/material.dart';
import 'dashboard_view.dart';
import 'networks_view.dart';
import 'devices_view.dart';
import 'reports_view.dart'; // 1. IMPORTAR LA VISTA DE REPORTES
import 'profile_view.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardView(),
    NetworksView(),
    DevicesView(),
    ReportsView(), // 2. AGREGAR A LA LISTA DE PANTALLAS
    ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    const purpleColor = Color(0xFF6A1B9A);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: const Color(0xFFE8DEF8),
          backgroundColor: Colors.white,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: purpleColor,
              );
            }
            return const TextStyle(fontSize: 12, color: Colors.grey);
          }),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: purpleColor),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.hub_outlined),
              selectedIcon: Icon(Icons.hub, color: purpleColor),
              label: 'Redes',
            ),
            NavigationDestination(
              icon: Icon(Icons.devices_outlined),
              selectedIcon: Icon(Icons.devices, color: purpleColor),
              label: 'Dispositivos',
            ),
            // 3. AGREGAR LA OPCIÓN EN LA BARRA DE NAVEGACIÓN
            NavigationDestination(
              icon: Icon(Icons.assessment_outlined),
              selectedIcon: Icon(Icons.assessment, color: purpleColor),
              label: 'Reportes',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: purpleColor),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}