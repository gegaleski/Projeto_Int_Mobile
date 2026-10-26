
import 'package:flutter/material.dart';

import '../services/api_service.dart';

class RegisterEquipmentScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const RegisterEquipmentScreen({
    super.key,
    this.initialData,
  });

  @override
  State<RegisterEquipmentScreen> createState() =>
      _RegisterEquipmentScreenState();
}

class _RegisterEquipmentScreenState
    extends State<RegisterEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _serialController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _status = 'DISPONIVEL';
  bool _saving = false;

  late final bool _fromQrCode;

  final Map<String, String> _statuses = const {
    'DISPONIVEL': 'Disponível',
    'EM_USO': 'Em uso',
    'EM_MANUTENCAO': 'Em manutenção',
    'INATIVO': 'Inativo',
  };

  @override
  void initState() {
    super.initState();

    final data = widget.initialData;
    _fromQrCode = data != null;

    if (data != null) {
      _codeController.text = _readValue(data, [
        'codigo_patrimonial',
        'codigoPatrimonial',
        'patrimonial_code',
        'asset_code',
        'assetCode',
        'codigo',
        'code',
        'tag',
      ]);

      _nameController.text = _readValue(data, [
        'nome',
        'name',
        'nome_equipamento',
        'equipment_name',
        'equipmentName',
        'asset_name',
      ]);

      _serialController.text = _readValue(data, [
        'numero_serie',
        'numeroSerie',
        'serialNumber',
        'serial_number',
        'serial',
      ]);

      _locationController.text = _readValue(data, [
        'localizacao',
        'localização',
        'location',
        'local',
        'localizacao_atual',
        'current_location',
      ]);

      _descriptionController.text = _readValue(data, [
        'descricao',
        'descrição',
        'description',
        'detalhes',
      ]);

      _status = _normalizeStatus(
        _readValue(data, ['status', 'situacao', 'situação', 'state']),
      );
    }
  }

  String _readValue(
    Map<String, dynamic> data,
    List<String> possibleKeys,
  ) {
    for (final key in possibleKeys) {
      final value = data[key];

      if (value != null &&
          value is! Map &&
          value is! List &&
          value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return '';
  }

  String _normalizeStatus(String value) {
    final normalized = value.trim().toUpperCase();

    const aliases = {
      'DISPONÍVEL': 'DISPONIVEL',
      'AVAILABLE': 'DISPONIVEL',
      'IN USE': 'EM_USO',
      'EM USO': 'EM_USO',
      'IN_USE': 'EM_USO',
      'UNDER MAINTENANCE': 'EM_MANUTENCAO',
      'EM MANUTENÇÃO': 'EM_MANUTENCAO',
      'MAINTENANCE': 'EM_MANUTENCAO',
      'INACTIVE': 'INATIVO',
      'INATIVO': 'INATIVO',
    };

    final result = aliases[normalized] ?? normalized;

    return _statuses.containsKey(result) ? result : 'DISPONIVEL';
  }

  bool get _hasRequiredData {
    return _codeController.text.trim().isNotEmpty &&
        _nameController.text.trim().isNotEmpty &&
        _locationController.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _serialController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveEquipment() async {
    if (_saving) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await ApiService.criarEquipamento(
        codigoPatrimonial: _codeController.text.trim(),
        nome: _nameController.text.trim(),
        localizacao: _locationController.text.trim(),
        status: _status,
        numeroSerie: _serialController.text.trim(),
        descricao: _descriptionController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Equipamento cadastrado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      final message = error.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  InputDecoration _decoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Text(
          _fromQrCode
              ? 'Confirmar equipamento'
              : 'Cadastrar equipamento',
        ),
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7EEFA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _fromQrCode
                          ? Icons.qr_code_scanner
                          : Icons.devices,
                      color: const Color(0xFF2457A7),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _fromQrCode
                            ? 'Dados recebidos do QR Code. Confira as informações e confirme o cadastro.'
                            : 'Preencha os dados do equipamento para registrá-lo no sistema.',
                        style: const TextStyle(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (_fromQrCode && _hasRequiredData)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFA5D6A7),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF2E7D32),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Dados obrigatórios identificados. Basta conferir e confirmar.',
                          style: TextStyle(
                            color: Color(0xFF1B5E20),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_fromQrCode && !_hasRequiredData)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'O QR Code não contém todos os dados obrigatórios. Complete os campos que estiverem vazios antes de confirmar.',
                    style: TextStyle(height: 1.4),
                  ),
                ),

              const SizedBox(height: 24),

              TextFormField(
                controller: _codeController,
                decoration: _decoration(
                  label: 'Código patrimonial *',
                  icon: Icons.qr_code,
                  hint: 'Ex.: LAB-2026-0150',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o código patrimonial.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: _decoration(
                  label: 'Nome do equipamento *',
                  icon: Icons.devices_outlined,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome do equipamento.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _serialController,
                decoration: _decoration(
                  label: 'Número de série',
                  icon: Icons.numbers,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _locationController,
                decoration: _decoration(
                  label: 'Localização *',
                  icon: Icons.location_on_outlined,
                  hint: 'Ex.: Laboratório A, Posto 04',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe a localização.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: _decoration(
                  label: 'Status',
                  icon: Icons.info_outline,
                ),
                items: _statuses.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _status = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: _decoration(
                  label: 'Descrição',
                  icon: Icons.description_outlined,
                  hint: 'Informações adicionais sobre o equipamento',
                ),
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 28),

              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _saveEquipment,
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    _saving
                        ? 'Cadastrando...'
                        : _fromQrCode
                            ? 'Confirmar cadastro'
                            : 'Cadastrar equipamento',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2457A7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
