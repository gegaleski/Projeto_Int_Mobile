class Movement {
  final String assetCode;
  final String type;
  final String origin;
  final String destination;
  final String responsible;
  final String description;
  final DateTime date;
  final String? newStatus;

  const Movement({
    required this.assetCode,
    required this.type,
    required this.origin,
    required this.destination,
    required this.responsible,
    required this.description,
    required this.date,
    this.newStatus,
  });
}