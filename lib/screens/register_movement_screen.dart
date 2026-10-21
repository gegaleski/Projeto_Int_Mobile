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

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _responsibleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveMovement() {
    if (!_formKey.currentState!.validate()) return;

    MovementService.add(
      Movement(
        assetCode: widget.assetCode,
        type: _type,
        origin: _originController.text.trim(),
        destination: _destinationController.text.trim(),
        responsible: _responsibleController.text.trim(),
        description: _descriptionController.text.trim(),
        date: DateTime.now(),
      ),
    );

    Navigator.pop(context, true);
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
              onChanged: (value) {
                if (value != null) {
                  setState(() => _type = value);
                }
              },
            ),
            const SizedBox(height: 16),
            _field(_originController, 'Local de origem'),
            _field(_destinationController, 'Local de destino'),
            _field(_responsibleController, 'Responsável'),
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
                onPressed: _saveMovement,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Salvar movimentação'),
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
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (required && (value == null || value.trim().isEmpty)) {
            return 'Preencha este campo.';
          }
          return null;
        },
      ),
    );
  }
}