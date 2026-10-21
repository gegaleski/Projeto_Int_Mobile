import '../models/movement.dart';

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

  static void add(Movement movement) {
    _movements.add(movement);
  }
}