import 'package:flutter/material.dart';

import '../models/movement.dart';
import '../services/movement_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {});
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year às $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final movements = MovementService.getAll().reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ordens e movimentações'),
      ),
      body: movements.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history,
                      size: 64,
                      color: Color(0xFF68758A),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Nenhuma movimentação registrada',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Os registros dos equipamentos aparecerão aqui.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: movements.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final Movement movement = movements[index];

                return Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(
                      color: Color(0xFFE5EAF1),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movement.type,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('Ativo: ${movement.assetCode}'),
                        Text('Origem: ${movement.origin}'),
                        Text('Destino: ${movement.destination}'),
                        Text('Responsável: ${movement.responsible}'),
                        if (movement.description.isNotEmpty)
                          Text('Observações: ${movement.description}'),
                        const SizedBox(height: 10),
                        Text(
                          _formatDate(movement.date),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF68758A),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}