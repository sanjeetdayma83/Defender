import 'package:flutter/material.dart';
import '../screen_ui.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notifications = true;
  bool autoRecord = true;
  bool darkMode = false;

  @override
  Widget build(BuildContext context) {
    return LDPage(
      title: 'Settings',
      subtitle: 'Configure account, warehouse, notifications and integrations.',
      child: Column(
        children: [
          _section('Account', 'Manage account preferences and identity.', [
            _item(
              Icons.person_outline,
              'Personal information',
              'Name, email and profile details',
            ),
            _item(
              Icons.lock_outline,
              'Security',
              'Authentication and account security',
            ),
          ]),
          _section('Warehouse', 'Operational environment settings.', [
            _item(
              Icons.warehouse_outlined,
              'Warehouse configuration',
              'Location, code and operating settings',
            ),
            _item(
              Icons.qr_code_scanner_rounded,
              'Scanner & Camera',
              'Scanner and camera device preferences',
            ),
          ]),
          _section('Notifications', 'Control operational alerts.', [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Operational notifications',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Receive packing and evidence alerts'),
              value: notifications,
              onChanged: (v) => setState(() => notifications = v),
            ),
          ]),
          _section('Recording', 'Packing evidence preferences.', [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Automatic recording',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'Start recording after a valid shipment scan',
              ),
              value: autoRecord,
              onChanged: (v) => setState(() => autoRecord = v),
            ),
          ]),
          _section('Appearance', 'Interface preferences.', [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Dark mode',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Use dark interface where supported'),
              value: darkMode,
              onChanged: (v) => setState(() => darkMode = v),
            ),
          ]),
          _section('Storage', 'Evidence storage configuration.', [
            _item(
              Icons.cloud_outlined,
              'Cloud storage',
              'Backblaze B2 evidence storage',
            ),
          ]),
          _section('Integrations', 'Marketplace and service connections.', [
            _item(
              Icons.storefront_outlined,
              'Marketplace integrations',
              'Amazon, Flipkart and future channels',
            ),
          ]),
        ],
      ),
    );
  }

  Widget _section(String title, String subtitle, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: LDCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LDSectionTitle(title: title, subtitle: subtitle),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _item(IconData icon, String title, String subtitle) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: ldBlue.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: ldBlue),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800, color: ldNavy),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}
