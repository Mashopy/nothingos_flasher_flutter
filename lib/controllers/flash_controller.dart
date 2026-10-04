import '../data/device_profiles.dart';
import '../models/device_profile.dart';
import '../models/firmware_package.dart';
import '../models/flash_step.dart';
import '../services/fastboot_service.dart';

DeviceProfile getDeviceProfile(String product) {
  return deviceProfiles[product] ?? deviceProfiles["default"]!;
}

const _bootloaderPartitions = [
  "boot",
  "init_boot",
  "dtbo",
  "recovery",
  "vendor_boot",
  "vbmeta",
  "vbmeta_system",
  "vbmeta_vendor",
  // MediaTek only allow flashing most of the firmware in bootloader mode
  "apusys",
  "audio_dsp",
  "ccu",
  "connsys_bt",
  "connsys_gnss",
  "connsys_wifi",
  "dpm",
  "gpueb",
  "gz",
  "lk",
  "logo",
  "mcf_ota",
  "mcupm",
  "md1img",
  "modem",
  "mvpu_algo",
  "pi_img",
  "scp",
  "spmfw",
  "sspm",
  "tee",
  "vcp",
];

const _fastbootdPartitions = [
  // Qualcomm-based devices
  "abl",
  "aop",
  "aop_config",
  "bluetooth",
  "cpucp",
  "cpucb_dtb",
  "devcfg",
  "dsp",
  "featenabler",
  "hyp",
  "imagefv",
  "keymaster",
  "modem",
  "multiimgoem",
  "multiimgqti",
  "qupfw",
  "qweslicstore",
  "shrm",
  "soccp_dcd",
  "soccp_debug",
  "tz",
  "uefi",
  "uefisecapp",
  "xbl",
  "xbl_config",
  "xbl_ramdump",
  // MediaTek-based devices
  "preloader_raw",
];

const _dynamicPartitions = [
  "system",
  "product",
  "system_ext",
  "vendor",
  "odm",
  "system_dlkm",
  "vendor_dlkm",
  "odm_dlkm",
];

class FlashController {
  final FastbootService service;
  final void Function() onUpdate;

  FlashController(this.service, this.onUpdate);

  String output = '';
  String product = '';
  Slot? slot;

  void _log(String text) {
    output += text;
    onUpdate();
  }

  List<FlashStep> _buildSteps(
    List<String> ordered,
    List<String> supported,
    FirmwarePackage firmware,
  ) {
    return ordered
        .where(supported.contains)
        .map((p) {
          final file = firmware.images[p];
          return file == null ? null : FlashStep(p, file);
        })
        .whereType<FlashStep>()
        .toList();
  }

  List<FlashStep> buildBootloaderSteps(
    DeviceProfile profile,
    FirmwarePackage firmware,
  ) {
    return _buildSteps(_bootloaderPartitions, profile.partitions, firmware);
  }

  List<FlashStep> buildFastbootdSteps(
    DeviceProfile profile,
    FirmwarePackage firmware,
  ) {
    return _buildSteps(
      _fastbootdPartitions,
      profile.fastbootdPartitions,
      firmware,
    );
  }

  List<FlashStep> buildDynamicSteps(
    DeviceProfile profile,
    FirmwarePackage firmware,
  ) {
    return _buildSteps(_dynamicPartitions, profile.dynamicPartitions, firmware);
  }

  List<LogicalStep> buildSetupLogicalSteps(
    DeviceProfile profile,
    FirmwarePackage firmware,
  ) {
    return _dynamicPartitions
        .where(profile.dynamicPartitions.contains)
        .map(LogicalStep.new)
        .toList();
  }

  Future<void> detectDevices() async {
    _log("Scanning...");
    final result = await service.command("devices");
    _log(result);
  }

  Future<void> detectProduct() async {
    product = await service.getProduct();
    onUpdate();
  }

  Future<void> detectSlot() async {
    slot = await service.getCurrentSlot();
    onUpdate();
  }

  Future<void> fullFlash(
    FirmwarePackage firmware, {
    bool rebootToSystem = true,
    bool formatData = false,
    bool lockBootloader = false,
  }) async {
    _log("Detecting device...\n");

    final device = await service.command("devices");
    final product = await service.getProduct();
    final profile = getDeviceProfile(product);
    final currentSlot = await service.getCurrentSlot();
    final slots = [currentSlot, currentSlot.other];

    Future<void> forEachSlot(Future<void> Function(Slot) action) async {
      for (final slot in slots) {
        await action(slot);
      }
    }

    _log("Device: $device\n");
    _log("Product: $product\n");
    _log("Current slot: $currentSlot\n");

    _log("\nFlashing partitions in bootloader mode...\n");
    final bootloaderSteps = buildBootloaderSteps(profile, firmware);
    await forEachSlot((s) => service.flash(bootloaderSteps, s, _log));

    _log("\nRebooting to fastbootd mode...\n");
    await service.command("reboot", "fastboot");

    _log("\nFlashing parititions in fastbootd mode...\n");
    final fastbootdSteps = buildFastbootdSteps(profile, firmware);
    await forEachSlot((s) => service.flash(fastbootdSteps, s, _log));

    final logicalSteps = buildSetupLogicalSteps(profile, firmware);

    _log("\nErasing dynamic partitions in fastbootd mode...\n");
    await forEachSlot(
      (s) => service.eraseLogicalPartitions(logicalSteps, s, _log),
    );

    _log("\nCreating dynamic partitions in fastbootd mode...\n");
    await forEachSlot(
      (s) => service.createLogicalPartitions(logicalSteps, s, _log),
    );

    _log("\nFlashing dynamic partitions in fastbootd mode...\n");
    final dynamicSteps = buildDynamicSteps(profile, firmware);
    await forEachSlot((s) => service.flash(dynamicSteps, s, _log));

    if (formatData) {
      _log("\nErasing userdata and metadata partitions...");
      await service.command("erase", "userdata");
      await service.command("erase", "metadata");
    }

    if (lockBootloader) {
      _log("\nRebooting to bootloader mode...\n");
      await service.command("reboot", "bootloader");

      _log("\nLocking the bootloader please confirm on your device...\n");
      await service.command("flashing", "lock");
    }

    if (rebootToSystem) {
      _log("\nRebooting to system...\n");
      await service.command("reboot");
    }
  }
}
