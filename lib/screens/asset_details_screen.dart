import 'package:flutter/material.dart';

import '../models/asset.dart';
import '../models/movement.dart';
import '../services/api_service.dart';
import 'register_movement_screen.dart';

class AssetDetailsScreen extends StatefulWidget {
  final String assetCode;

  const AssetDetailsScreen({
    super.key,
    required this.assetCode,
  });

  @override
  State<AssetDetailsScreen> createState() => _AssetDetailsScreenState();
}

class _AssetDetailsScreenState extends State<AssetDetailsScreen> {
  late Future<Asset?> _assetFuture;
  late Future<List<Movement>> _movementsFuture;

  @override
  void initState() {
    super.initState();
    _assetFuture = _findAsset();
    _movementsFuture = ApiService.getMovimentacoes();
  }

  Future<Asset?> _findAsset() async {
    final equipamentos = await ApiService.getEquipamentos();

    for (final item in equipamentos) {
      if (item is! Map) continue;

      final code =
          (item['codigo_patrimonial'] ?? '').toString().trim();

      if (code.toLowerCase() == widget.assetCode.trim().toLowerCase()) {
        return Asset(
          code: code,
          name: (item['nome'] ?? 'Não informado').toString(),
          location: (item['localizacao'] ?? 'Não informado').toString(),
          status: _formatStatus(item['status']?.toString() ?? ''),
          maintenanceDate: 'Não informada',
          serialNumber:
              (item['numero_serie'] ?? 'Não informado').toString(),
          description:
              (item['descricao'] ?? 'Sem descrição').toString(),
        );
      }
    }

    return null;
  }

  String _formatStatus(String status) {
    switch (status.toUpperCase()) {
      case 'DISPONIVEL':
        return 'Disponível';
      case 'EM_USO':
        return 'Em uso';
      case 'EM_MANUTENCAO':
        return 'Em manutenção';
      case 'INATIVO':
        return 'Inativo';
      default:
        return status.isEmpty ? 'Não informado' : status;
    }
  }

  void _retry() {
    setState(() {
      _assetFuture = _findAsset();
      _movementsFuture = ApiService.getMovimentacoes();
    });
  }

  Future<void> _refreshMovements() async {
    final future = ApiService.getMovimentacoes();

    setState(() {
      _movementsFuture = future;
    });

    await future;
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();

    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year.toString();
    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');

    return '$day/$month/$year às $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do equipamento'),
        actions: [
          IconButton(
            tooltip: 'Atualizar informações',
            onPressed: _retry,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<Asset?>(
        future: _assetFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Consultando equipamento na API...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return _buildError();
          }

          final asset = snapshot.data;

          if (asset == null) {
            return _buildNotFound();
          }

          return _buildAssetDetails(context, asset);
        },
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 64,
              color: Color(0xFF68758A),
            ),
            const SizedBox(height: 16),
            const Text(
              'Não foi possível consultar a API',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Verifique se o servidor Django está rodando '
              'e tente novamente.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
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
              'Código recebido: ${widget.assetCode}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Verifique se o equipamento está cadastrado no Django.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Consultar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetDetails(BuildContext context, Asset asset) {
    return RefreshIndicator(
      onRefresh: _refreshMovements,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                    'Dados consultados no servidor Django',
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
            const SizedBox(height: 12),
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
                    setState(() {
                      _movementsFuture = ApiService.getMovimentacoes();
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Movimentação registrada com sucesso.',
                        ),
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
            const SizedBox(height: 28),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Histórico de movimentações',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Atualizar histórico',
                  onPressed: () {
                    setState(() {
                      _movementsFuture = ApiService.getMovimentacoes();
                    });
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Movement>>(
              future: _movementsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _HistoryMessage(
                    icon: Icons.cloud_off_outlined,
                    message: 'Não foi possível carregar o histórico.',
                    detail: 'Verifique a API e tente atualizar.',
                    onRetry: () {
                      setState(() {
                        _movementsFuture = ApiService.getMovimentacoes();
                      });
                    },
                  );
                }

                final code = asset.code.trim().toLowerCase();

                final movements = (snapshot.data ?? [])
                    .where(
                      (movement) =>
                          movement.assetCode.trim().toLowerCase() == code,
                    )
                    .toList()
                  ..sort((a, b) => b.date.compareTo(a.date));

                if (movements.isEmpty) {
                  return const _HistoryMessage(
                    icon: Icons.history,
                    message: 'Nenhuma movimentação registrada',
                    detail:
                        'As movimentações deste equipamento aparecerão aqui.',
                  );
                }

                return Column(
                  children: movements
                      .map((movement) => _MovementCard(
                            movement: movement,
                            formattedDate: _formatDate(movement.date),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MovementCard extends StatelessWidget {
  final Movement movement;
  final String formattedDate;

  const _MovementCard({
    required this.movement,
    required this.formattedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color.fromARGB(255, 255, 255, 255)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFE7EEFA),
                child: Icon(
                  Icons.swap_horiz,
                  color: Color(0xFF2457A7),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movement.type,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF172B4D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF68758A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _MovementDetail(
            label: 'Origem',
            value: movement.origin,
          ),
          _MovementDetail(
            label: 'Destino',
            value: movement.destination,
          ),
          _MovementDetail(
            label: 'Responsável',
            value: movement.responsible,
          ),
          if (movement.description.trim().isNotEmpty)
            _MovementDetail(
              label: 'Descrição',
              value: movement.description,
            ),
        ],
      ),
    );
  }
}

class _MovementDetail extends StatelessWidget {
  final String label;
  final String value;

  const _MovementDetail({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF68758A),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? 'Não informado' : value,
              style: const TextStyle(
                color: Color(0xFF172B4D),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? detail;
  final VoidCallback? onRetry;

  const _HistoryMessage({
    required this.icon,
    required this.message,
    this.detail,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5EAF1)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 36,
            color: const Color(0xFF68758A),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (detail != null) ...[
            const SizedBox(height: 6),
            Text(
              detail!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF68758A),
                fontSize: 13,
              ),
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
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
