import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'dashboard_view.dart';
import 'networks_view.dart';
import 'devices_view.dart';
import 'reports_view.dart';
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
    ReportsView(),
    ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: AppColors.primary.withOpacity(0.12),
          backgroundColor: AppColors.surface,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              );
            }
            return const TextStyle(fontSize: 11, color: AppColors.textSecondary);
          }),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          elevation: 8,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.hub_outlined),
              selectedIcon: Icon(Icons.hub_rounded, color: AppColors.primary),
              label: 'Redes',
            ),
            NavigationDestination(
              icon: Icon(Icons.devices_outlined),
              selectedIcon: Icon(Icons.devices_rounded, color: AppColors.primary),
              label: 'Dispositivos',
            ),
            NavigationDestination(
              icon: Icon(Icons.assessment_outlined),
              selectedIcon: Icon(Icons.assessment_rounded, color: AppColors.primary),
              label: 'Reportes',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}