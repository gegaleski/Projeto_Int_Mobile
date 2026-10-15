import 'package:flutter/material.dart';

class AssetDetailsScreen extends StatelessWidget {
  final String assetCode;

  const AssetDetailsScreen({
    super.key,
    required this.assetCode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do equipamento'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFE7EEFA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.desktop_windows_outlined,
                    size: 64,
                    color: Color(0xFF2457A7),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Equipamento identificado',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF172B4D),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Consulta demonstrativa',
                    style: TextStyle(color: Color(0xFF68758A)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Informações do ativo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _InfoTile(
              label: 'Código do ativo',
              value: assetCode,
            ),
            const _InfoTile(
              label: 'Equipamento',
              value: 'Dell OptiPlex 7010',
            ),
            const _InfoTile(
              label: 'Localização',
              value: 'Posto 04',
            ),
            const _InfoTile(
              label: 'Status',
              value: 'Em uso',
            ),
            const _InfoTile(
              label: 'Manutenção preventiva',
              value: 'Consultar registro',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'O registro de movimentações será implementado '
                        'na próxima etapa.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.assignment_outlined),
                label: const Text('Registrar movimentação'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2457A7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5EAF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF68758A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF172B4D),
            ),
          ),
        ],
      ),
    );
  }
}