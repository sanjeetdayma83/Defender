import 'package:flutter/material.dart';
import '../screen_ui.dart';

class WarehouseScreen extends StatelessWidget {
  const WarehouseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LDPage(
      title: 'Warehouse',
      subtitle: 'Operational configuration, devices and warehouse health.',
      action: ldButton('Edit Warehouse', Icons.edit_outlined),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: LDStat(
                  label: 'Active Orders',
                  value: '18',
                  icon: Icons.inventory_2_outlined,
                  color: ldBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LDStat(
                  label: 'Active Sessions',
                  value: '3',
                  icon: Icons.play_circle_outline,
                  color: ldAmber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LDStat(
                  label: 'Devices',
                  value: '4',
                  icon: Icons.devices_other_outlined,
                  color: ldGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: LDCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const LDSectionTitle(
                        title: 'Main Warehouse',
                        subtitle: 'Warehouse profile',
                      ),
                      _row('Code', 'MAIN'),
                      _row('Status', 'Active'),
                      _row('Packing Mode', 'Scanner + Camera'),
                      _row('Evidence', 'Enabled'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LDCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const LDSectionTitle(
                        title: 'Device Health',
                        subtitle: 'Connected operational hardware',
                      ),
                      _device('Barcode Scanner', 'Connected', ldGreen),
                      _device('Camera', 'Connected', ldGreen),
                      _device('Network', 'Online', ldGreen),
                      _device('Storage', 'Healthy', ldGreen),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: ldMute)),
          ),
          Text(
            value,
            style: const TextStyle(color: ldNavy, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _device(String name, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 9, color: ldGreen),
          const SizedBox(width: 10),
          Expanded(child: Text(name)),
          Text(
            status,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
