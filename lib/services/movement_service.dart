import '../models/movement.dart';
import 'api_service.dart';

class MovementService {
  static final List<Movement> _movements = [];

  static List<Movement> getAll() {
    return List.unmodifiable(_movements);
  }

  static List<Movement> getByAsset(String assetCode) {
    return _movements
        .where((movement) => movement.assetCode == assetCode)
        .toList()
        .reversed
        .toList();
  }

  static Future<void> add(Movement movement) async {
    await ApiService.registrarMovimentacao(
      codigoEquipamento: movement.assetCode,
      tipo: movement.type,
      origem: movement.origin,
      destino: movement.destination,
      responsavel: movement.responsible,
      descricao: movement.description,
      novoStatus: movement.newStatus,
    );

    _movements.add(movement);
  }
}