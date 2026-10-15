import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu perfil'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 44,
            backgroundColor: Color(0xFFE7EEFA),
            child: Icon(
              Icons.person_outline,
              size: 48,
              color: Color(0xFF2457A7),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Usuário do LabControl',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Perfil demonstrativo',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          const ListTile(
            leading: Icon(Icons.badge_outlined),
            title: Text('Tipo de acesso'),
            subtitle: Text('Ainda não autenticado'),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.security_outlined),
            title: Text('Segurança'),
            subtitle: Text('Configurações de acesso serão integradas'),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Sobre o aplicativo'),
            subtitle: Text('LabControl • Projeto Integrador IV'),
          ),
        ],
      ),
    );
  }
}