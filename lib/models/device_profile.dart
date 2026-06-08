class DeviceProfile {
  final String product;
  final List<String> partitions;
  final List<String> fastbootdPartitions;
  final List<String> dynamicPartitions;

  const DeviceProfile({
    required this.product,
    required this.partitions,
    required this.fastbootdPartitions,
    required this.dynamicPartitions,
  });
}
