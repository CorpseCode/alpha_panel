import 'package:flutter/material.dart';

class BluetoothPanel extends StatelessWidget {
  const BluetoothPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final connectedDevice = "AirPods Pro"; // mock
    final availableDevices = [
      "Sony WH-1000XM4",
      "JBL Go Speaker",
      "Boat SoundBass"
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (connectedDevice.isNotEmpty) ...[
          const Text(
            "Connected device",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Card(
            color: Colors.white.withValues(alpha: 0.09),
            child: ListTile(
              title: Text(
                connectedDevice,
                style: const TextStyle(color: Colors.white),
              ),
              trailing: TextButton(
                onPressed: () {},
                child: const Text("Disconnect"),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        const Text(
          "Available devices",
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 10),

        Expanded(
          child: ListView.builder(
            itemCount: availableDevices.length,
            itemBuilder: (_, index) {
              return Card(
                color: Colors.white.withValues(alpha: 0.07),
                child: ListTile(
                  title: Text(
                    availableDevices[index],
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
