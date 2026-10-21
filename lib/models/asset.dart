class Asset {
  final String code;
  final String name;
  final String location;
  final String status;
  final String maintenanceDate;
  final String serialNumber;
  final String description;

  const Asset({
    required this.code,
    required this.name,
    required this.location,
    required this.status,
    required this.maintenanceDate,
    required this.serialNumber,
    required this.description,
  });
}