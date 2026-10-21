import '../models/asset.dart';

class AssetService {
  static const List<Asset> _assets = [
    Asset(
      code: 'LAB-2026-0148',
      name: 'Dell OptiPlex 7010',
      location: 'Posto 04',
      status: 'Em uso',
      maintenanceDate: '15/12/2026',
      serialNumber: 'DELL-DEMO-0148',
      description: 'Computador desktop do laboratório de informática.',
    ),
    Asset(
      code: 'LAB-2026-0149',
      name: 'Monitor Dell P2422H',
      location: 'Posto 05',
      status: 'Disponível',
      maintenanceDate: '20/12/2026',
      serialNumber: 'DELL-DEMO-0149',
      description: 'Monitor utilizado nas estações de trabalho.',
    ),
    Asset(
      code: 'LAB-2026-0150',
      name: 'Notebook Lenovo ThinkPad',
      location: 'Armário A02',
      status: 'Em manutenção',
      maintenanceDate: 'Consultar ordem de serviço',
      serialNumber: 'LENOVO-DEMO-0150',
      description: 'Notebook destinado às atividades do laboratório.',
    ),
  ];

  static Asset? findByCode(String code) {
    final normalizedCode = code.trim().toUpperCase();

    for (final asset in _assets) {
      if (asset.code.toUpperCase() == normalizedCode) {
        return asset;
      }
    }

    return null;
  }

  static List<Asset> getAll() {
    return List.unmodifiable(_assets);
  }
}