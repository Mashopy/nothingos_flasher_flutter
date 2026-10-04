import 'dart:io';
import 'fastboot_resolver.dart';
import '../models/flash_step.dart';

class FastbootService {
  Future<String> command(String cmd1, [String? cmd2]) async {
    final args = <String>[cmd1];

    if (cmd2 != null) {
      args.add(cmd2);
    }

    final result = await Process.run(FastbootResolver.path, args);

    if (result.exitCode != 0) {
      throw Exception(
        'Failed to run fastboot ${args.join(" ")}: ${result.stderr}',
      );
    }

    return result.stdout.toString();
  }

  Future<Slot> getCurrentSlot() async {
    final result = await Process.run(FastbootResolver.path, [
      'getvar',
      'current-slot',
    ]);

    if (result.exitCode != 0) {
      throw Exception('Failed to get current-slot: ${result.stderr}');
    }

    final output = result.stdout.toString() + result.stderr.toString();
    final match = RegExp(r'current-slot:\s*([ab])').firstMatch(output);

    if (match == null) {
      throw Exception('Failed to parse current-slot from output: $output');
    }

    return Slot.values.byName(match.group(1)!);
  }

  Future<String> getProduct() async {
    final result = await Process.run(FastbootResolver.path, [
      'getvar',
      'product',
    ]);

    if (result.exitCode != 0) {
      throw Exception('Failed to get product: ${result.stderr}');
    }

    final output = result.stdout.toString() + result.stderr.toString();
    final match = RegExp(r'product:\s*([^\s]+)').firstMatch(output);

    if (match == null) {
      throw Exception('Failed to parse product from output: $output');
    }

    return match.group(1)!;
  }

  Future<void> _run(List<String> args, void Function(String) log) async {
    final process = await Process.start(FastbootResolver.path, args);
    final decoder = SystemEncoding().decoder;

    await Future.wait([
      process.stdout.transform(decoder).forEach(log),
      process.stderr.transform(decoder).forEach(log),
    ]);

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('fastboot ${args.join(' ')} failed ($exitCode)');
    }
  }

  Future<void> flash(
    List<FlashStep> steps,
    Slot slot,
    void Function(String) log,
  ) async {
    for (final s in steps) {
      final target = '${s.partition}${slot.suffix}';
      log("Flashing ${s.partition}...\n");
      await _run(['flash', target, s.file], log);
    }
  }

  Future<void> eraseLogicalPartitions(
    List<LogicalStep> steps,
    Slot slot,
    void Function(String) log,
  ) async {
    for (final s in steps) {
      for (final target in [
        '${s.partition}${slot.suffix}',
        '${s.partition}${slot.suffix}-cow',
      ]) {
        log('Deleting logical partition $target...\n');
        await _run(['delete-logical-partition', target], log);
      }
    }
  }

  Future<void> createLogicalPartitions(
    List<LogicalStep> steps,
    Slot slot,
    void Function(String) log,
  ) async {
    for (final s in steps) {
      final target = '${s.partition}${slot.suffix}';
      log('Creating logical partition $target...\n');
      await _run(['create-logical-partition', target, '1'], log);
    }
  }
}
