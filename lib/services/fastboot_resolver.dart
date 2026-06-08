import 'dart:io';

class FastbootResolver {
  static late final String path;

  static Future<String> resolve() async {
    if (Platform.isLinux) {
      return _linux();
    }
    if (Platform.isMacOS) {
      return _mac();
    }
    if (Platform.isWindows) {
      return _windows();
    }
    throw UnsupportedError("Unsupported platform");
  }

  static Future<String> _linux() async {
    return _shellWhich("fastboot");
  }

  static Future<String> _mac() async {
    return _shellWhich("fastboot");
  }

  static Future<String> _windows() async {
    final pathEnv = Platform.environment["PATH"] ?? "";
    
    // Windows uses semicolon as the PATH separator
    final paths = pathEnv.split(";");

    for (final p in paths) {
      if (p.isEmpty) continue;
      // Windows uses backslashes for paths
      final candidate = "$p\\fastboot.exe";
      if (File(candidate).existsSync()) {
        return candidate;
      }
    }

    throw Exception("fastboot.exe not found in PATH");
  }

  static Future<String> _shellWhich(String bin) async {
    final shell = Platform.environment['SHELL'] ?? '/bin/bash';
    
    final result = await Process.run(shell, ['-lc', 'which $bin']);
    
    if (result.exitCode == 0) {
      final resolvedPath = result.stdout.toString().trim();
      if (resolvedPath.isNotEmpty && File(resolvedPath).existsSync()) {
        return resolvedPath;
      }
    }

    throw Exception("$bin not found dynamically via shell");
  }

  static Future<void> init() async {
    path = await resolve();
  }
}