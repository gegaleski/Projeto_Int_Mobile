
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'create_service_order_screen.dart';

class ServiceOrdersScreen extends StatefulWidget {
  const ServiceOrdersScreen({super.key});

  @override
  State<ServiceOrdersScreen> createState() =>
      _ServiceOrdersScreenState();
}

class _ServiceOrdersScreenState extends State<ServiceOrdersScreen> {
  late Future<List<dynamic>> _ordersFuture;

  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';
  String _selectedStatus = 'TODOS';
  String _selectedPriority = 'TODAS';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadOrders() {
    _ordersFuture = ApiService.getOrdensServico();
  }

  Future<void> _refreshOrders() async {
    setState(_loadOrders);

    try {
      await _ordersFuture;
    } catch (_) {
      // O FutureBuilder apresenta a mensagem de erro.
    }
  }

  Future<void> _openCreateOrder() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const CreateServiceOrderScreen(),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      setState(_loadOrders);
    }
  }

  String _priorityLabel(String value) {
    const labels = {
      'BAIXA': 'Baixa',
      'MEDIA': 'Média',
      'ALTA': 'Alta',
      'URGENTE': 'Urgente',
    };

    return labels[value] ?? value;
  }

  String _statusLabel(String value) {
    const labels = {
      'ABERTA': 'Aberta',
      'EM_ANDAMENTO': 'Em andamento',
      'CONCLUIDA': 'Concluída',
      'CANCELADA': 'Cancelada',
    };

    return labels[value] ?? value;
  }

  String _formatDate(String? value) {
    if (value == null) {
      return 'Data não disponível';
    }

    final date = DateTime.tryParse(value)?.toLocal();

    if (date == null) {
      return 'Data não disponível';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year às $hour:$minute';
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'URGENTE':
        return Colors.red;
      case 'ALTA':
        return Colors.deepOrange;
      case 'MEDIA':
        return Colors.orange.shade800;
      default:
        return Colors.green.shade700;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'CONCLUIDA':
        return Colors.green.shade700;
      case 'CANCELADA':
        return Colors.red.shade700;
      case 'EM_ANDAMENTO':
        return Colors.orange.shade800;
      default:
        return const Color(0xFF2457A7);
    }
  }

  String _equipmentDescription(Map<String, dynamic> order) {
    final equipment = order['equipamento_detalhes'];

    if (equipment is Map) {
      final code =
          equipment['codigo_patrimonial']?.toString() ?? '';
      final name = equipment['nome']?.toString() ?? '';

      if (code.isNotEmpty && name.isNotEmpty) {
        return '$code — $name';
      }

      if (code.isNotEmpty) {
        return code;
      }

      if (name.isNotEmpty) {
        return name;
      }
    }

    final equipmentId = order['equipamento'];

    if (equipmentId != null) {
      return 'ID: $equipmentId';
    }

    return 'Não informado';
  }

  List<dynamic> _filterOrders(List<dynamic> orders) {
    final query = _searchQuery.trim().toLowerCase();

    return orders.where((rawOrder) {
      if (rawOrder is! Map) {
        return false;
      }

      final order = Map<String, dynamic>.from(rawOrder);

      final status = order['status']?.toString() ?? 'ABERTA';
      final priority =
          order['prioridade']?.toString() ?? 'MEDIA';

      final title = order['titulo']?.toString() ?? '';
      final description = order['descricao']?.toString() ?? '';
      final responsible = order['responsavel']?.toString() ?? '';
      final equipment = _equipmentDescription(order);

      final matchesSearch = query.isEmpty ||
          title.toLowerCase().contains(query) ||
          description.toLowerCase().contains(query) ||
          responsible.toLowerCase().contains(query) ||
          equipment.toLowerCase().contains(query) ||
          (order['id']?.toString() ?? '').contains(query);

      final matchesStatus = _selectedStatus == 'TODOS' ||
          status == _selectedStatus;

      final matchesPriority = _selectedPriority == 'TODAS' ||
          priority == _selectedPriority;

      return matchesSearch && matchesStatus && matchesPriority;
    }).toList();
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _selectedStatus = 'TODOS';
      _selectedPriority = 'TODAS';
    });
  }

  Future<void> _updateStatus(
    int orderId,
    String status,
  ) async {
    try {
      await ApiService.atualizarStatusOrdemServico(
        ordemId: orderId,
        status: status,
      );

      if (!mounted) return;

      setState(_loadOrders);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status da ordem atualizado!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar ordem: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showStatusOptions(
    int orderId,
    String currentStatus,
  ) async {
    const statuses = {
      'ABERTA': 'Aberta',
      'EM_ANDAMENTO': 'Em andamento',
      'CONCLUIDA': 'Concluída',
      'CANCELADA': 'Cancelada',
    };

    final selectedStatus = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text(
                  'Atualizar status',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Selecione o novo status da ordem.',
                ),
              ),
              ...statuses.entries.map((entry) {
                return ListTile(
                  leading: Icon(
                    entry.key == currentStatus
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: const Color(0xFF2457A7),
                  ),
                  title: Text(entry.value),
                  onTap: () {
                    Navigator.pop(context, entry.key);
                  },
                );
              }),
            ],
          ),
        );
      },
    );

    if (selectedStatus != null &&
        selectedStatus != currentStatus &&
        mounted) {
      await _updateStatus(orderId, selectedStatus);
    }
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Pesquisar ordem ou equipamento...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      tooltip: 'Limpar pesquisa',
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                      icon: const Icon(Icons.close),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFE5EAF1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFE5EAF1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2457A7),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'TODOS',
                      child: Text('Todos'),
                    ),
                    DropdownMenuItem(
                      value: 'ABERTA',
                      child: Text('Aberta'),
                    ),
                    DropdownMenuItem(
                      value: 'EM_ANDAMENTO',
                      child: Text('Em andamento'),
                    ),
                    DropdownMenuItem(
                      value: 'CONCLUIDA',
                      child: Text('Concluída'),
                    ),
                    DropdownMenuItem(
                      value: 'CANCELADA',
                      child: Text('Cancelada'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _selectedStatus = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedPriority,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Prioridade',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'TODAS',
                      child: Text('Todas'),
                    ),
                    DropdownMenuItem(
                      value: 'BAIXA',
                      child: Text('Baixa'),
                    ),
                    DropdownMenuItem(
                      value: 'MEDIA',
                      child: Text('Média'),
                    ),
                    DropdownMenuItem(
                      value: 'ALTA',
                      child: Text('Alta'),
                    ),
                    DropdownMenuItem(
                      value: 'URGENTE',
                      child: Text('Urgente'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _selectedPriority = value;
                    });
                  },
                ),
              ),
            ],
          ),
          if (_searchQuery.isNotEmpty ||
              _selectedStatus != 'TODOS' ||
              _selectedPriority != 'TODAS')
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Limpar filtros'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    return FutureBuilder<List<dynamic>>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF2457A7),
            ),
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
                    size: 56,
                    color: Color(0xFF68758A),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Não foi possível carregar as ordens.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(_loadOrders);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          );
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refreshOrders,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 70),
                Icon(
                  Icons.assignment_outlined,
                  size: 64,
                  color: Color(0xFF68758A),
                ),
                SizedBox(height: 16),
                Center(
                  child: Text(
                    'Nenhuma ordem de serviço',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'As ordens cadastradas no Django aparecerão aqui.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Center(
                  child: Text(
                    'Puxe a tela para atualizar.',
                  ),
                ),
              ],
            ),
          );
        }

        final filteredOrders = _filterOrders(orders);

        if (filteredOrders.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 35),
              const Icon(
                Icons.search_off_outlined,
                size: 56,
                color: Color(0xFF68758A),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Nenhuma ordem encontrada',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Tente alterar a pesquisa ou os filtros selecionados.',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.filter_alt_off_outlined),
                  label: const Text('Limpar filtros'),
                ),
              ),
            ],
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshOrders,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: filteredOrders.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final rawOrder = filteredOrders[index];

              if (rawOrder is! Map) {
                return const SizedBox.shrink();
              }

              final order = Map<String, dynamic>.from(rawOrder);

              final orderId = int.tryParse(
                order['id'].toString(),
              );

              final status =
                  order['status']?.toString() ?? 'ABERTA';

              final priority =
                  order['prioridade']?.toString() ?? 'MEDIA';

              final title =
                  order['titulo']?.toString() ?? 'Sem título';

              final description =
                  order['descricao']?.toString() ?? '';

              final responsible =
                  order['responsavel']?.toString() ?? '';

              final equipmentDescription =
                  _equipmentDescription(order);

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
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.assignment_outlined,
                            color: Color(0xFF2457A7),
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'OS #${order['id']} — $title',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.devices_outlined,
                                      size: 18,
                                      color: Color(0xFF68758A),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        equipmentDescription,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF344054),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        description,
                        style: const TextStyle(height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            label: Text(
                              'Prioridade: ${_priorityLabel(priority)}',
                            ),
                            backgroundColor:
                                _priorityColor(priority).withOpacity(0.12),
                            side: BorderSide.none,
                            labelStyle: TextStyle(
                              color: _priorityColor(priority),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Chip(
                            label: Text(_statusLabel(status)),
                            backgroundColor:
                                _statusColor(status).withOpacity(0.12),
                            side: BorderSide.none,
                            labelStyle: TextStyle(
                              color: _statusColor(status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Responsável: '
                        '${responsible.isEmpty ? 'Não definido' : responsible}',
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Abertura: '
                        '${_formatDate(order['data_abertura']?.toString())}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF68758A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: orderId == null
                              ? null
                              : () => _showStatusOptions(
                                    orderId,
                                    status,
                                  ),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Alterar status'),
                        ),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _openCreateOrder,
              icon: const Icon(Icons.add),
              label: const Text('Nova ordem de serviço'),
            ),
          ),
        ),
        _buildFilters(),
        Expanded(
          child: _buildOrdersList(),
        ),
      ],
    );
  }
}
