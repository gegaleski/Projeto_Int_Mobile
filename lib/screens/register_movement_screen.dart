import 'package:flutter/material.dart';

import '../models/movement.dart';
import '../services/movement_service.dart';

class RegisterMovementScreen extends StatefulWidget {
  final String assetCode;

  const RegisterMovementScreen({
    super.key,
    required this.assetCode,
  });

  @override
  State<RegisterMovementScreen> createState() =>
      _RegisterMovementScreenState();
}

class _RegisterMovementScreenState
    extends State<RegisterMovementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _responsibleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _type = 'Transferência';
  String _newStatus = 'DISPONIVEL';
  bool _isSaving = false;

  static const Map<String, String> _statusOptions = {
    'DISPONIVEL': 'Disponível',
    'EM_USO': 'Em uso',
    'EM_MANUTENCAO': 'Em manutenção',
    'INATIVO': 'Inativo',
  };

  bool get _isTransfer => _type == 'Transferência';

  String get _automaticStatus {
    if (_type == 'Envio para manutenção') {
      return 'EM_MANUTENCAO';
    }

    if (_type == 'Retorno de manutenção') {
      return 'DISPONIVEL';
    }

    return _newStatus;
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _responsibleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveMovement() async {
    if (!_formKey.currentState!.validate() || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await MovementService.add(
        Movement(
          assetCode: widget.assetCode,
          type: _type,
          origin: _originController.text.trim(),
          destination: _destinationController.text.trim(),
          responsible: _responsibleController.text.trim(),
          description: _descriptionController.text.trim(),
          date: DateTime.now(),
          newStatus: _automaticStatus,
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Movimentação salva com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar movimentação: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar movimentação'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Ativo: ${widget.assetCode}',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Tipo de movimentação',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Transferência',
                  child: Text('Transferência'),
                ),
                DropdownMenuItem(
                  value: 'Envio para manutenção',
                  child: Text('Envio para manutenção'),
                ),
                DropdownMenuItem(
                  value: 'Retorno de manutenção',
                  child: Text('Retorno de manutenção'),
                ),
              ],
              onChanged: _isSaving
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() {
                          _type = value;
                        });
                      }
                    },
            ),

            const SizedBox(height: 16),

            if (_isTransfer) ...[
              DropdownButtonFormField<String>(
                value: _newStatus,
                decoration: const InputDecoration(
                  labelText: 'Novo status do equipamento',
                  border: OutlineInputBorder(),
                ),
                items: _statusOptions.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _newStatus = value;
                          });
                        }
                      },
              ),
              const SizedBox(height: 16),
            ] else ...[
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Novo status automático',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _statusOptions[_automaticStatus]!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            _field(
              _originController,
              'Local de origem',
            ),

            _field(
              _destinationController,
              'Local de destino',
            ),

            _field(
              _responsibleController,
              'Responsável',
            ),

            _field(
              _descriptionController,
              'Observações',
              required: false,
              maxLines: 3,
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveMovement,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _isSaving
                      ? 'Salvando...'
                      : 'Salvar movimentação',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2457A7),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = true,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        enabled: !_isSaving,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (required &&
              (value == null || value.trim().isEmpty)) {
            return 'Preencha este campo.';
          }

          return null;
        },
      ),
    );
  }
}