import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'login_view.dart';
import 'networks_view.dart';
import 'devices_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;
  final List<Widget> _pantallas = [const DevicesView(), const NetworksView()];

  void _cerrarSesion() async {
    await SupabaseService().logout();
    if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginView()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bitácora Móvil'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _cerrarSesion, tooltip: 'Cerrar Sesión')
        ],
      ),
      body: _pantallas[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.devices), label: 'Dispositivos'),
          BottomNavigationBarItem(icon: Icon(Icons.router), label: 'Redes'),
        ],
      ),
    );
  }
}