import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/api_service.dart';
import 'asset_details_screen.dart';
import 'register_equipment_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();

  bool _processing = false;

  static const Map<String, List<String>> _fieldAliases = {
    'codigo_patrimonial': [
      'codigo_patrimonial',
      'codigoPatrimonial',
      'patrimonial_code',
      'asset_code',
      'assetCode',
      'codigo',
      'code',
      'tag',
      'id_ativo',
    ],
    'nome': [
      'nome',
      'name',
      'nome_equipamento',
      'equipment_name',
      'equipmentName',
      'asset_name',
    ],
    'numero_serie': [
      'numero_serie',
      'numeroSerie',
      'serial_number',
      'serialNumber',
      'serial',
    ],
    'localizacao': [
      'localizacao',
      'localização',
      'location',
      'local',
      'localizacao_atual',
      'current_location',
    ],
    'status': [
      'status',
      'situacao',
      'situação',
      'state',
    ],
    'descricao': [
      'descricao',
      'descrição',
      'description',
      'detalhes',
    ],
  };

  // Normaliza nomes como serialNumber, serial_number e
  // "Número de Série" para facilitar a identificação dos campos.
  String _normalizeKey(String key) {
    return key
        .trim()
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (match) => '${match[1]}_${match[2]}',
        )
        .toLowerCase()
        .replaceAll(RegExp(r'[\s-]+'), '_');
  }

  Map<String, dynamic> _normalizePayload(Map<dynamic, dynamic> source) {
    final result = <String, dynamic>{};

    for (final canonicalKey in _fieldAliases.keys) {
      final aliases = _fieldAliases[canonicalKey]!
          .map(_normalizeKey)
          .toSet();

      for (final entry in source.entries) {
        final sourceKey = _normalizeKey(entry.key.toString());

        if (aliases.contains(sourceKey)) {
          final value = entry.value;

          if (value != null &&
              value is! Map &&
              value is! List &&
              value.toString().trim().isNotEmpty) {
            result[canonicalKey] = value.toString().trim();
            break;
          }
        }
      }
    }

    return result;
  }

  // Interpreta QR Codes que contêm campos no formato:
  // code: LAB-2026-0148
  // name: Dell OptiPlex 7010
  // serialNumber: DELL-DEMO-0148
  Map<String, dynamic>? _parseKeyValueText(String raw) {
    final parsed = <String, dynamic>{};

    for (final line in raw.split(RegExp(r'\r?\n'))) {
      final trimmedLine = line.trim();

      if (trimmedLine.isEmpty) continue;

      // Divide somente no primeiro ":" para preservar os demais
      // dois-pontos que possam existir no valor.
      final separatorIndex = trimmedLine.indexOf(':');

      if (separatorIndex <= 0) continue;

      final key = trimmedLine.substring(0, separatorIndex).trim();
      final value = trimmedLine.substring(separatorIndex + 1).trim();

      if (key.isEmpty || value.isEmpty) continue;

      parsed[key] = value;
    }

    if (parsed.isEmpty) return null;

    final normalized = _normalizePayload(parsed);

    // Evita interpretar uma frase qualquer com ":" como
    // dados de equipamento.
    if (normalized.isEmpty) return null;

    return {
      ...normalized,
      '_conteudo_original': raw,
    };
  }

  Map<String, dynamic> _parseQrContent(String rawValue) {
    final raw = rawValue.trim();

    // 1. Formato JSON.
    try {
      final decoded = jsonDecode(raw);

      if (decoded is Map) {
        return {
          ..._normalizePayload(decoded),
          '_conteudo_original': raw,
        };
      }
    } catch (_) {
      // Não é JSON. Tenta os próximos formatos.
    }

    // 2. Formato URL.
    final uri = Uri.tryParse(raw);

    if (uri != null &&
        (uri.hasScheme || raw.startsWith('?') || raw.contains('='))) {
      final queryData = <String, dynamic>{};

      for (final entry in uri.queryParametersAll.entries) {
        if (entry.value.isNotEmpty) {
          queryData[entry.key] = entry.value.first;
        }
      }

      final parsedQuery = _normalizePayload(queryData);

      if (parsedQuery.isNotEmpty) {
        return {
          ...parsedQuery,
          '_conteudo_original': raw,
        };
      }

      // URL terminando com o código patrimonial.
      if (uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https')) {
        final segments = uri.pathSegments
            .where((segment) => segment.trim().isNotEmpty)
            .toList();

        if (segments.isNotEmpty) {
          final lastSegment = Uri.decodeComponent(segments.last);

          return {
            'codigo_patrimonial': lastSegment,
            '_conteudo_original': raw,
          };
        }
      }
    }

    // 3. Texto com pares chave: valor.
    // Esta é a correção principal para o QR Code atual.
    final keyValuePayload = _parseKeyValueText(raw);

    if (keyValuePayload != null) {
      return keyValuePayload;
    }

    // 4. Texto simples: considera o conteúdo como código patrimonial.
    return {
      'codigo_patrimonial': raw,
      '_conteudo_original': raw,
    };
  }

  String _getEquipmentCode(Map<String, dynamic> data) {
    return data['codigo_patrimonial']?.toString().trim() ?? '';
  }

  Future<Map<String, dynamic>?> _findExistingEquipment(
    String code,
  ) async {
    if (code.trim().isEmpty) return null;

    final equipments = await ApiService.getEquipamentos();

    for (final item in equipments) {
      if (item is! Map) continue;

      final existingCode = item['codigo_patrimonial']?.toString().trim();

      if (existingCode != null &&
          existingCode.toLowerCase() == code.trim().toLowerCase()) {
        return Map<String, dynamic>.from(item);
      }
    }

    return null;
  }

  bool _hasRequiredRegistrationData(Map<String, dynamic> data) {
    return _getEquipmentCode(data).isNotEmpty &&
        (data['nome']?.toString().trim().isNotEmpty ?? false) &&
        (data['localizacao']?.toString().trim().isNotEmpty ?? false);
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;

    String? rawValue;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;

      if (value != null && value.trim().isNotEmpty) {
        rawValue = value.trim();
        break;
      }
    }

    if (rawValue == null) return;

    _processing = true;

    try {
      await _controller.stop();

      if (!mounted) return;

      await _handleQrContent(rawValue);
    } catch (error) {
      if (mounted) {
        final message = error.toString().replaceFirst('Exception: ', '');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível processar o QR Code: $message'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      _processing = false;

      if (mounted) {
        try {
          await _controller.start();
        } catch (_) {
          // A câmera pode não estar disponível no momento.
        }
      }
    }
  }

  Future<void> _handleQrContent(String rawValue) async {
    final payload = _parseQrContent(rawValue);
    final code = _getEquipmentCode(payload);

    // Primeiro verifica automaticamente se o equipamento já existe na API Django.
    if (code.isNotEmpty) {
      final existing = await _findExistingEquipment(code);

      if (!mounted) return;

      if (existing != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AssetDetailsScreen(
              assetCode: _getEquipmentCode(existing),
            ),
          ),
        );
        return;
      }
    }

    if (!mounted) return;

    // Equipamento novo com os campos obrigatórios identificados.
    if (_hasRequiredRegistrationData(payload)) {
      await _openRegistration(payload);
      return;
    }

    // QR Code desconhecido ou com informações incompletas.
    await _showUnknownQrDialog(rawValue, payload);
  }

  Future<void> _openRegistration(Map<String, dynamic> data) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RegisterEquipmentScreen(
          initialData: data,
        ),
      ),
    );
  }

  Future<void> _showUnknownQrDialog(
    String rawValue,
    Map<String, dynamic> payload,
  ) async {
    if (!mounted) return;

    final code = _getEquipmentCode(payload);
    final hasSomeEquipmentData = payload.keys.any(
      (key) => !key.startsWith('_'),
    );

    final registerData = Map<String, dynamic>.from(payload);
    registerData['_conteudo_original'] = rawValue;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.qr_code_2,
                color: Color(0xFF2457A7),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text('QR Code não identificado'),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Não encontramos um equipamento cadastrado com '
                  'esse conteúdo ou os dados estão incompletos.',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Conteúdo lido:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F4F8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SelectableText(
                    rawValue,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Confira os dados e inicie o cadastro. '
                  'Nenhum equipamento será criado automaticamente.',
                  style: TextStyle(
                    color: Color(0xFF68758A),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fechar'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);

                final data = Map<String, dynamic>.from(registerData);

                if (code.isEmpty && !hasSomeEquipmentData) {
                  data.clear();
                }

                Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RegisterEquipmentScreen(
                      initialData: data.isEmpty ? null : data,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Cadastrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Identificar equipamento'),
        actions: [
          IconButton(
            onPressed: () => _controller.toggleTorch(),
            icon: const Icon(Icons.flash_on),
            tooltip: 'Ligar ou desligar o flash',
          ),
          IconButton(
            onPressed: () => _controller.switchCamera(),
            icon: const Icon(Icons.cameraswitch),
            tooltip: 'Trocar câmera',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                ),
                IgnorePointer(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 30,
                  left: 24,
                  right: 24,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Posicione o QR Code dentro da área '
                      'delimitada para identificar ou cadastrar um ativo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
