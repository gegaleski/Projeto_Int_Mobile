import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CreateServiceOrderScreen extends StatefulWidget {
  const CreateServiceOrderScreen({super.key});

  @override
  State<CreateServiceOrderScreen> createState() =>
      _CreateServiceOrderScreenState();
}

class _CreateServiceOrderScreenState
    extends State<CreateServiceOrderScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _responsibleController = TextEditingController();

  List<dynamic> _equipments = [];
  String? _selectedEquipment;
  String _priority = 'MEDIA';
  bool _loadingEquipments = true;
  bool _saving = false;
  String? _equipmentError;

  @override
  void initState() {
    super.initState();
    _loadEquipments();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _responsibleController.dispose();
    super.dispose();
  }

  Future<void> _loadEquipments() async {
    try {
      final equipments = await ApiService.getEquipamentos();

      if (!mounted) return;

      setState(() {
        _equipments = equipments;
        _loadingEquipments = false;

        if (equipments.isNotEmpty) {
          _selectedEquipment =
              equipments.first['codigo_patrimonial'].toString();
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingEquipments = false;
        _equipmentError = e.toString();
      });
    }
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedEquipment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um equipamento.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await ApiService.criarOrdemServico(
        codigoEquipamento: _selectedEquipment!,
        titulo: _titleController.text.trim(),
        descricao: _descriptionController.text.trim(),
        prioridade: _priority,
        responsavel: _responsibleController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ordem de serviço criada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao criar ordem: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova ordem de serviço'),
      ),
      body: _loadingEquipments
          ? const Center(child: CircularProgressIndicator())
          : _equipmentError != null
              ? Center(
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
                          'Não foi possível carregar os equipamentos.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _equipmentError!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () {
                            setState(() {
                              _loadingEquipments = true;
                              _equipmentError = null;
                            });
                            _loadEquipments();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : _equipments.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.devices_other,
                              size: 52,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Nenhum equipamento cadastrado.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Cadastre um equipamento antes de criar uma ordem de serviço.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _loadingEquipments = true;
                                  _equipmentError = null;
                                });
                                _loadEquipments();
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Atualizar equipamentos'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          const Text(
                            'Informações da ordem',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Preencha os dados para registrar uma solicitação de serviço.',
                          ),
                          const SizedBox(height: 24),

                          DropdownButtonFormField<String>(
                            value: _selectedEquipment,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Equipamento',
                              prefixIcon: Icon(Icons.devices_outlined),
                              border: OutlineInputBorder(),
                            ),
                            items: _equipments.map((equipment) {
                              final code =
                                  equipment['codigo_patrimonial'].toString();
                              final name =
                                  equipment['nome']?.toString() ??
                                      'Sem nome';

                              return DropdownMenuItem<String>(
                                value: code,
                                child: Text(
                                  '$code — $name',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedEquipment = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Selecione um equipamento.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Título da ordem',
                              hintText: 'Ex.: Computador não liga',
                              prefixIcon: Icon(Icons.title),
                              border: OutlineInputBorder(),
                            ),
                            textCapitalization: TextCapitalization.sentences,
                            maxLength: 150,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Informe o título da ordem.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Descrição do problema',
                              hintText:
                                  'Descreva o problema ou serviço necessário',
                              prefixIcon: Icon(Icons.description_outlined),
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                            textCapitalization: TextCapitalization.sentences,
                            minLines: 4,
                            maxLines: 6,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Informe a descrição do problema.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          DropdownButtonFormField<String>(
                            value: _priority,
                            decoration: const InputDecoration(
                              labelText: 'Prioridade',
                              prefixIcon: Icon(Icons.flag_outlined),
                              border: OutlineInputBorder(),
                            ),
                            items: const [
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
                              if (value != null) {
                                setState(() => _priority = value);
                              }
                            },
                          ),
                          const SizedBox(height: 20),

                          TextFormField(
                            controller: _responsibleController,
                            decoration: const InputDecoration(
                              labelText: 'Responsável (opcional)',
                              hintText: 'Nome do técnico responsável',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                            ),
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 28),

                          SizedBox(
                            height: 52,
                            child: FilledButton.icon(
                              onPressed: _saving ? null : _saveOrder,
                              icon: _saving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: Text(
                                _saving
                                    ? 'Salvando...'
                                    : 'Criar ordem de serviço',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
