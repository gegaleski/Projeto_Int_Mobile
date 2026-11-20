import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'scanner_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';
import 'register_equipment_screen.dart';
import 'equipment_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _changeTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _DashboardContent(
        onOpenScanner: () => _changeTab(1),
        onOpenOrders: () => _changeTab(2),
      ),
      const ScannerScreen(),
      const OrdersScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _changeTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scanner',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            label: 'Ordens',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class _DashboardContent extends StatefulWidget {
  final VoidCallback onOpenScanner;
  final VoidCallback onOpenOrders;

  const _DashboardContent({
    required this.onOpenScanner,
    required this.onOpenOrders,
  });

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  late Future<Map<String, dynamic>> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  void _loadDashboard() {
    _dashboardFuture = _fetchDashboard();
  }

  Future<Map<String, dynamic>> _fetchDashboard() async {
    final results = await Future.wait([
      ApiService.getOrdensServico(),
      ApiService.getEquipamentos(),
    ]);

    final orders = results[0];
    final equipment = results[1];

    int countStatus(String status) {
      return orders.where((item) {
        if (item is! Map) return false;
        return item['status']?.toString() == status;
      }).length;
    }

    return {
      'totalOrdens': orders.length,
      'totalEquipamentos': equipment.length,
      'abertas': countStatus('ABERTA'),
      'emAndamento': countStatus('EM_ANDAMENTO'),
      'concluidas': countStatus('CONCLUIDA'),
      'canceladas': countStatus('CANCELADA'),
    };
  }

  Future<void> _refreshDashboard() async {
    setState(_loadDashboard);

    try {
      await _dashboardFuture;
    } catch (_) {
      // O FutureBuilder apresenta a mensagem de erro.
    }
  }

  Future<void> _openEquipmentRegistration() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const RegisterEquipmentScreen(),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await _refreshDashboard();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Indicadores atualizados.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openEquipmentList() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EquipmentListScreen(),
      ),
    );

    if (!mounted) return;

    await _refreshDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/labcontrol_logo.png',
              width: 42,
              height: 42,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            const Text(
              'LabControl',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF172B4D),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar indicadores',
            onPressed: _refreshDashboard,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Olá, usuário!',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF172B4D),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Acompanhe a situação do seu laboratório.',
                  style: TextStyle(
                    color: Color(0xFF68758A),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Visão geral',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF172B4D),
                  ),
                ),
                const SizedBox(height: 14),
                FutureBuilder<Map<String, dynamic>>(
                  future: _dashboardFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF2457A7),
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return _DashboardError(
                        onRetry: _refreshDashboard,
                      );
                    }

                    final data = snapshot.data!;

                    final totalOrdens = data['totalOrdens'] as int;
                    final abertas = data['abertas'] as int;
                    final emAndamento = data['emAndamento'] as int;
                    final concluidas = data['concluidas'] as int;
                    final canceladas = data['canceladas'] as int;

                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                title: 'Equipamentos',
                                value: '${data['totalEquipamentos']}',
                                icon: Icons.devices_outlined,
                                color: const Color(0xFF2457A7),
                                onTap: _openEquipmentList,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                title: 'Total de ordens',
                                value: '$totalOrdens',
                                icon: Icons.assignment_outlined,
                                color: const Color(0xFF7047B8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                title: 'Abertas',
                                value: '$abertas',
                                icon: Icons.pending_actions_outlined,
                                color: const Color(0xFF2457A7),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                title: 'Em andamento',
                                value: '$emAndamento',
                                icon: Icons.build_outlined,
                                color: Colors.deepOrange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                title: 'Concluídas',
                                value: '$concluidas',
                                icon: Icons.check_circle_outline,
                                color: Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                title: 'Canceladas',
                                value: '$canceladas',
                                icon: Icons.cancel_outlined,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _StatusSummary(
                          total: totalOrdens,
                          abertas: abertas,
                          emAndamento: emAndamento,
                          concluidas: concluidas,
                          canceladas: canceladas,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),
                const Text(
                  'Acesso rápido',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF172B4D),
                  ),
                ),
                const SizedBox(height: 16),
                _ActionCard(
                  icon: Icons.add_box_outlined,
                  title: 'Cadastrar equipamento',
                  description: 'Registre um novo ativo manualmente.',
                  onTap: _openEquipmentRegistration,
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  icon: Icons.qr_code_scanner,
                  title: 'Identificar equipamento',
                  description: 'Leia o QR Code de um ativo.',
                  onTap: widget.onOpenScanner,
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  icon: Icons.assignment_outlined,
                  title: 'Ordens e movimentações',
                  description: 'Acompanhe os registros dos ativos.',
                  onTap: widget.onOpenOrders,
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7EEFA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFF2457A7),
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Consulte os ativos e acompanhe suas '
                          'movimentações em um só lugar.',
                          style: TextStyle(height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 124),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE5EAF1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172B4D),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF68758A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusSummary extends StatelessWidget {
  final int total;
  final int abertas;
  final int emAndamento;
  final int concluidas;
  final int canceladas;

  const _StatusSummary({
    required this.total,
    required this.abertas,
    required this.emAndamento,
    required this.concluidas,
    required this.canceladas,
  });

  @override
  Widget build(BuildContext context) {
    final statuses = [
      _StatusData(
        label: 'Abertas',
        count: abertas,
        color: const Color(0xFF2457A7),
      ),
      _StatusData(
        label: 'Em andamento',
        count: emAndamento,
        color: Colors.deepOrange,
      ),
      _StatusData(
        label: 'Concluídas',
        count: concluidas,
        color: Colors.green,
      ),
      _StatusData(
        label: 'Canceladas',
        count: canceladas,
        color: Colors.red,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5EAF1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ordens por status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF172B4D),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Distribuição das ordens cadastradas.',
            style: TextStyle(
              color: Color(0xFF68758A),
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(
                children: statuses.map((status) {
                  return Expanded(
                    flex: status.count == 0 ? 1 : status.count,
                    child: Container(
                      color: status.count == 0
                          ? const Color(0xFFE5EAF1)
                          : status.color,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...statuses.map((status) {
            final percentage =
                total == 0 ? 0 : (status.count / total * 100).round();

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: status.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      status.label,
                      style: const TextStyle(
                        color: Color(0xFF344054),
                      ),
                    ),
                  ),
                  Text(
                    '${status.count}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF172B4D),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 42,
                    child: Text(
                      '$percentage%',
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF68758A),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StatusData {
  final String label;
  final int count;
  final Color color;

  const _StatusData({
    required this.label,
    required this.count,
    required this.color,
  });
}

class _DashboardError extends StatelessWidget {
  final VoidCallback onRetry;

  const _DashboardError({
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5EAF1),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 40,
            color: Color(0xFF68758A),
          ),
          const SizedBox(height: 12),
          const Text(
            'Não foi possível carregar os indicadores.',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: Color(0xFFE5EAF1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: Icon(
          icon,
          color: const Color(0xFF2457A7),
          size: 30,
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(description),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
