import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class BatteryOptimizationHelper {
  static Future<void> checkAndRequestBatteryOptimization(BuildContext context) async {
    // Check if battery optimization is enabled
    var status = await Permission.ignoreBatteryOptimizations.status;
    
    if (!status.isGranted) {
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text("Battery Optimization"),
            content: const Text(
              "To ensure continuous location tracking, please disable battery optimization for this app.\n\n"
              "This will prevent the system from stopping the tracking service.",
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await Permission.ignoreBatteryOptimizations.request();
                  Navigator.pop(context);
                },
                child: const Text("Disable Optimization"),
              ),
            ],
          ),
        );
      }
    }
  }
}