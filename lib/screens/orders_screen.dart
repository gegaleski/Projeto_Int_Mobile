import 'package:flutter/material.dart';
import '../models/movement.dart';
import '../services/api_service.dart';
import 'service_orders_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ordens e movimentações'),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.swap_horiz),
                text: 'Movimentações',
              ),
              Tab(
                icon: Icon(Icons.assignment_outlined),
                text: 'Ordens de Serviço',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _MovementsTab(),
            ServiceOrdersScreen(),
          ],
        ),
      ),
    );
  }
}

class _MovementsTab extends StatefulWidget {
  const _MovementsTab();

  @override
  State<_MovementsTab> createState() => _MovementsTabState();
}

class _MovementsTabState extends State<_MovementsTab> {
  late Future<List<Movement>> _movementsFuture;

  @override
  void initState() {
    super.initState();
    _loadMovements();
  }

  void _loadMovements() {
    _movementsFuture = ApiService.getMovimentacoes();
  }

  Future<void> _refresh() async {
    setState(_loadMovements);
    await _movementsFuture;
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

  IconData _movementIcon(String type) {
    if (type == 'Transferência') {
      return Icons.swap_horiz;
    }
    if (type == 'Envio para manutenção') {
      return Icons.build_outlined;
    }
    if (type == 'Retorno de manutenção') {
      return Icons.assignment_turned_in_outlined;
    }
    return Icons.history;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Movement>>(
      future: _movementsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    size: 48,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Não foi possível carregar as movimentações.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      setState(_loadMovements);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          );
        }

        final movements = snapshot.data ?? [];

        if (movements.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 130),
                Icon(
                  Icons.history,
                  size: 56,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Center(
                  child: Text('Nenhuma movimentação registrada.'),
                ),
                SizedBox(height: 8),
                Center(
                  child: Text('Puxe a tela para atualizar.'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: movements.length,
            itemBuilder: (context, index) {
              final movement = movements[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            child: Icon(
                              _movementIcon(movement.type),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  movement.type,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  movement.assetCode,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _MovementInfo(
                        label: 'Origem',
                        value: movement.origin,
                      ),
                      _MovementInfo(
                        label: 'Destino',
                        value: movement.destination,
                      ),
                      _MovementInfo(
                        label: 'Responsável',
                        value: movement.responsible,
                      ),
                      if (movement.description.trim().isNotEmpty)
                        _MovementInfo(
                          label: 'Descrição',
                          value: movement.description,
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _formatDate(movement.date),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _MovementInfo extends StatelessWidget {
  final String label;
  final String value;

  const _MovementInfo({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
