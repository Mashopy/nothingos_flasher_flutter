import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../controllers/flash_controller.dart';
import '../data/device_mapper.dart';
import '../models/firmware_package.dart';
import '../services/fastboot_service.dart';

class FlashPage extends StatefulWidget {
  const FlashPage({super.key});

  @override
  State<FlashPage> createState() => _FlashPageState();
}

class _FlashPageState extends State<FlashPage> {
  late final FlashController controller;
  final ScrollController scrollController = ScrollController();

  FirmwarePackage? firmware;
  bool rebootToSystem = true;
  bool formatData = false;
  bool lockBootloader = false;

  @override
  void initState() {
    super.initState();

    controller = FlashController(
      FastbootService(),
      () {
        if (!mounted) return;

        setState(() {});

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients) {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      },
    );
  }

  Future<void> pickFirmware() async {
    final result = await FilePicker.getDirectoryPath();

    if (result == null) return;

    final dir = Directory(result);
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

    setState(() {
      firmware = FirmwarePackage(images);
    });
  }

  @override
  Widget build(BuildContext context) {
    final String displayName = DeviceMapper.getDisplayName(controller.product);

    return Scaffold(
      appBar: AppBar(
        title: const Text('NOTHING OS flash tool'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
              Text(
                "Product: ${controller.product.isEmpty ? 'None detected' : controller.product}",
              ),
              if (displayName.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      "- $displayName",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await controller.detectProduct();
                      },
                      child: const Text('Detect device'),
                    ),

                    const SizedBox(height: 12),

                    ElevatedButton(
                      onPressed: controller.product.isEmpty
                          ? null
                          : () async {
                              await pickFirmware();
                            },
                      child: const Text('Select firmware folder'),
                    ),

                    const SizedBox(height: 12),

                    ElevatedButton(
                      onPressed: firmware == null
                          ? null
                          : () async {
                              await controller.fullFlash(
                                firmware!,
                                rebootToSystem: rebootToSystem,
                                formatData: formatData,
                                lockBootloader: lockBootloader,
                              );
                            },
                      child: const Text('Flash images'),
                    ),
                  ],
                ),

                const Spacer(),

                Container(
                  width: 260,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Options",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(height: 8),

                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Reboot to system"),
                        value: rebootToSystem,
                        onChanged: (value) {
                          setState(() {
                            rebootToSystem = value ?? true;
                          });
                        },
                      ),

                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Format data"),
                        value: formatData,
                        onChanged: (value) {
                          setState(() {
                            formatData = value ?? false;
                          });
                        },
                      ),

                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Lock the bootloader"),
                        value: lockBootloader,
                        onChanged: (value) {
                          setState(() {
                            lockBootloader = value ?? false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(8),
                  children: [
                    Text(
                      controller.output,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
