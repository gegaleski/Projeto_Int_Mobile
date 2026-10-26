
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'asset_details_screen.dart';

class EquipmentListScreen extends StatefulWidget {
  const EquipmentListScreen({super.key});

  @override
  State<EquipmentListScreen> createState() =>
      _EquipmentListScreenState();
}

class _EquipmentListScreenState extends State<EquipmentListScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  late Future<List<dynamic>> _equipmentFuture;

  String _selectedStatus = 'TODOS';

  final Map<String, String> _statuses = const {
    'TODOS': 'Todos',
    'DISPONIVEL': 'Disponível',
    'EM_USO': 'Em uso',
    'EM_MANUTENCAO': 'Em manutenção',
    'INATIVO': 'Inativo',
  };

  @override
  void initState() {
    super.initState();
    _loadEquipment();
    _searchController.addListener(_onSearchChanged);
  }

  void _loadEquipment() {
    _equipmentFuture = ApiService.getEquipamentos();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  Future<void> _refresh() async {
    setState(_loadEquipment);

    try {
      await _equipmentFuture;
    } catch (_) {
      // O FutureBuilder exibe o erro.
    }
  }

  List<dynamic> _filterEquipment(List<dynamic> equipment) {
    final query = _searchController.text.trim().toLowerCase();

    return equipment.where((item) {
      if (item is! Map) return false;

      final code =
          (item['codigo_patrimonial'] ?? '').toString().toLowerCase();
      final name = (item['nome'] ?? '').toString().toLowerCase();
      final serial =
          (item['numero_serie'] ?? '').toString().toLowerCase();

      final matchesSearch = query.isEmpty ||
          code.contains(query) ||
          name.contains(query) ||
          serial.contains(query);

      final status = (item['status'] ?? 'DISPONIVEL').toString();
      final matchesStatus = _selectedStatus == 'TODOS' ||
          status == _selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  String _statusLabel(String status) {
    return _statuses[status] ?? status;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'DISPONIVEL':
        return Colors.green.shade700;
      case 'EM_USO':
        return const Color(0xFF2457A7);
      case 'EM_MANUTENCAO':
        return Colors.deepOrange;
      case 'INATIVO':
        return Colors.red.shade700;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _equipmentIcon(String name) {
    final normalized = name.toLowerCase();

    if (normalized.contains('notebook') ||
        normalized.contains('laptop')) {
      return Icons.laptop_outlined;
    }

    if (normalized.contains('impressora')) {
      return Icons.print_outlined;
    }

    if (normalized.contains('monitor')) {
      return Icons.desktop_windows_outlined;
    }

    return Icons.devices_outlined;
  }

  Future<void> _openDetails(String code) async {
    if (code.trim().isEmpty) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AssetDetailsScreen(assetCode: code),
      ),
    );

    if (!mounted) return;
    await _refresh();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        title: const Text(
          'Equipamentos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar lista',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por nome, código ou série',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpar busca',
                          onPressed: _searchController.clear,
                          icon: const Icon(Icons.close),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: Color(0xFFE5EAF1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: Color(0xFFE5EAF1)),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                children: _statuses.entries.map((entry) {
                  final selected = _selectedStatus == entry.key;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(entry.value),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _selectedStatus = entry.key);
                      },
                      selectedColor: const Color(0xFFDCE8FA),
                      labelStyle: TextStyle(
                        color: selected
                            ? const Color(0xFF2457A7)
                            : const Color(0xFF344054),
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _equipmentFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
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
                              size: 48,
                              color: Color(0xFF68758A),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Não foi possível carregar os equipamentos.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: _refresh,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final equipment = snapshot.data ?? [];
                  final filtered = _filterEquipment(equipment);

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: filtered.isEmpty
                        ? ListView(
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(32),
                            children: [
                              const SizedBox(height: 50),
                              Icon(
                                equipment.isEmpty
                                    ? Icons.inventory_2_outlined
                                    : Icons.search_off,
                                size: 56,
                                color: const Color(0xFF98A2B3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                equipment.isEmpty
                                    ? 'Nenhum equipamento cadastrado.'
                                    : 'Nenhum equipamento encontrado.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF344054),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                equipment.isEmpty
                                    ? 'Os equipamentos cadastrados aparecerão aqui.'
                                    : 'Tente mudar a busca ou o filtro de status.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF68758A),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(
                                20, 8, 20, 24),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final item =
                                  filtered[index] as Map;
                              final code =
                                  (item['codigo_patrimonial'] ?? '')
                                      .toString();
                              final name =
                                  (item['nome'] ?? 'Sem nome')
                                      .toString();
                              final location =
                                  (item['localizacao'] ?? 'Não informada')
                                      .toString();
                              final status =
                                  (item['status'] ?? 'DISPONIVEL')
                                      .toString();
                              final serial =
                                  (item['numero_serie'] ?? '')
                                      .toString();

                              return Card(
                                elevation: 0,
                                margin:
                                    const EdgeInsets.only(bottom: 12),
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(16),
                                  side: const BorderSide(
                                    color: Color(0xFFE5EAF1),
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding:
                                      const EdgeInsets.all(14),
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE7EEFA),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _equipmentIcon(name),
                                      color: const Color(0xFF2457A7),
                                      size: 26,
                                    ),
                                  ),
                                  title: Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF172B4D),
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding:
                                        const EdgeInsets.only(top: 6),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Código: $code'),
                                        const SizedBox(height: 3),
                                        Text('Localização: $location'),
                                        if (serial.isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Text('Série: $serial'),
                                        ],
                                        const SizedBox(height: 8),
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 9,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _statusColor(status)
                                                .withValues(alpha: 0.10),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            _statusLabel(status),
                                            style: TextStyle(
                                              color: _statusColor(status),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right,
                                    color: Color(0xFF68758A),
                                  ),
                                  onTap: () => _openDetails(code),
                                ),
                              );
                            },
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
