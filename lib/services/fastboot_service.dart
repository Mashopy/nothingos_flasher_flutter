import 'dart:io';
import 'fastboot_resolver.dart';
import '../models/flash_step.dart';

class FastbootService {
  Future<String> command(String cmd1, [String? cmd2]) async {
    final args = <String>[cmd1];

    if (cmd2 != null) {
      args.add(cmd2);
    }

    final result = await Process.run(
      FastbootResolver.path,
      args
    );

    if (result.exitCode != 0) {
      throw Exception(
        'Failed to run fastboot ${args.join(" ")}: ${result.stderr}',
      );
    }

    return result.stdout.toString();
  }

  Future<String> getCurrentSlot() async {
    final result = await Process.run(
      FastbootResolver.path,
      ['getvar', 'current-slot'],
    );

    if (result.exitCode != 0) {
      throw Exception('Failed to get current-slot: ${result.stderr}');
    }

    final output = result.stdout.toString() + result.stderr.toString();
    final match = RegExp(r'current-slot:\s*([^\s]+)').firstMatch(output);

    if (match == null) {
      throw Exception('Failed to parse product from output: $output');
    }

    return '_${match.group(1)!}';
  }

  Future<String> getProduct() async {
    final result = await Process.run(
      FastbootResolver.path,
      ['getvar', 'product'],
    );

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

  Future<void> flash(List<FlashStep> steps, void Function(String) log) async {
    for (final step in steps) {
      log("Flashing ${step.partition}...\n");

      final process = await Process.start(
        FastbootResolver.path,
        ["flash", step.partition, step.file],
      );
    
      process.stdout
        .transform(SystemEncoding().decoder)
        .listen(log);

      process.stderr
        .transform(SystemEncoding().decoder)
        .listen(log);

      final exitCode = await process.exitCode;

      if (exitCode != 0) {
        throw Exception('Failed to flash ${step.partition}');
      }
    }
  }

  Future<void> eraseLogicalPartitions(
    List<LogicalStep> steps,
    String currentSlot,
    void Function(String) log
  ) async {
    final List<String> targets = [];
    
    for (final p in steps) {
      targets.add('${p.partition}$currentSlot');
      targets.add('${p.partition}$currentSlot-cow');
    }

    for (final target in targets) {
      log("Deleting logical partition $target...\n");

      final process = await Process.start(
        FastbootResolver.path,
        ["delete-logical-partition", target],
      );

      process.stdout
        .transform(SystemEncoding().decoder)
        .listen(log);

      process.stderr
        .transform(SystemEncoding().decoder)
        .listen(log);

      final exitCode = await process.exitCode;

      if (exitCode != 0) {
        throw Exception('Failed to delete $target');
      }
    }
  }

  Future<void> createLogicalPartitions(
    List<LogicalStep> steps,
    String currentSlot,
    void Function(String) log
  ) async {
    for (final step in steps) {
      log("Creating logical partition ${step.partition}$currentSlot...\n");

      final process = await Process.start(
        FastbootResolver.path,
        ["create-logical-partition", '${step.partition}$currentSlot', "1"],
      );

      process.stdout
        .transform(SystemEncoding().decoder)
        .listen(log);

      process.stderr
        .transform(SystemEncoding().decoder)
        .listen(log);

      final exitCode = await process.exitCode;

      if (exitCode != 0) {
        throw Exception('Failed to create ${step.partition}$currentSlot');
      }
    }
  }
}
