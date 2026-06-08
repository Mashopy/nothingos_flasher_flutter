class DeviceMapper {
  static const Map<String, String> _deviceMap = {
    // Qualcomm-devices mapping
    'lahaina': 'Nothing Phone (1)',
    'kalama': 'Nothing Phone (2)',
    'sun': 'Nothing Phone (3) and (4a) Pro',
    'volcano': 'Nothing Phone (3a), (3a) Pro and (4a)',
    // MediaTek-devices mapping
    'k6886v1_64': 'Nothing Phone (2a) and (2a) Plus',
    'k6878v1_64': 'CMF Phone 1, 2 Pro and Nothing Phone (3a) Lite',
  };

  static String getDisplayName(String productCodename) {
    if (productCodename.isEmpty) return '';

    final normalized = productCodename.toLowerCase().trim();

    return _deviceMap[normalized] ?? 'Unknown Device ($productCodename)';
  }
}
