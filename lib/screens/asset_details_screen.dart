import 'package:flutter/material.dart';

import '../models/asset.dart';
import '../services/asset_service.dart';
import 'register_movement_screen.dart';

class AssetDetailsScreen extends StatelessWidget {
  final String assetCode;

  const AssetDetailsScreen({
    super.key,
    required this.assetCode,
  });

  @override
  Widget build(BuildContext context) {
    final Asset? asset = AssetService.findByCode(assetCode);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do equipamento'),
      ),
      body:
          asset == null ? _buildNotFound() : _buildAssetDetails(context, asset),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_outlined,
              size: 64,
              color: Color(0xFF68758A),
            ),
            const SizedBox(height: 16),
            const Text(
              'Equipamento não encontrado',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Código recebido: $assetCode',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Verifique o código ou consulte o cadastro '
              'de equipamentos.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetDetails(BuildContext context, Asset asset) {
    return SingleChildScrollView(
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
                  size: 60,
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
                  'Consulta local de demonstração',
                  textAlign: TextAlign.center,
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
          _InfoTile(label: 'Código', value: asset.code),
          _InfoTile(label: 'Equipamento', value: asset.name),
          _InfoTile(label: 'Localização', value: asset.location),
          _InfoTile(label: 'Status', value: asset.status),
          _InfoTile(
            label: 'Manutenção preventiva',
            value: asset.maintenanceDate,
          ),
          _InfoTile(
            label: 'Número de série',
            value: asset.serialNumber,
          ),
          _InfoTile(
            label: 'Descrição',
            value: asset.description,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RegisterMovementScreen(
                      assetCode: asset.code,
                    ),
                  ),
                );

                if (!context.mounted) return;

                if (result == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Movimentação registrada com sucesso.'),
                    ),
                  );
                }
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
        border: Border.all(
          color: const Color(0xFFE5EAF1),
        ),
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
