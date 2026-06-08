import 'dart:io';

class FirmwarePackage {
  final Map<String, String> images;

  FirmwarePackage(this.images);

  String? get(String partition) => images[partition];

  Future<FirmwarePackage> loadFirmware(String path) async {
    final dir = Directory(path);
    final files = await dir
        .list()
        .where((e) => e is File)
        .cast<File>()
        .toList();

    final Map<String, String> images = {};

    for (final file in files) {
      final name = file.uri.pathSegments.last;

      if (name.endsWith('.img')) {
        final partition = name.replaceAll('.img', '');
        images[partition] = file.path;
      }
    }

    return FirmwarePackage(images);
  }
}
