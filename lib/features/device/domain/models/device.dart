class Device {
  final String id;
  final String name;
  final String description;
  final String? nfcCode;

  Device({
    required this.id,
    required this.name,
    this.description = '',
    this.nfcCode,
  });
}
