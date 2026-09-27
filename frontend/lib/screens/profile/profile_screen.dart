import 'package:flutter/material.dart';
import '../screen_ui.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LDPage(
      title: 'Profile',
      subtitle: 'Your Loss Defender account and work profile.',
      action: ldButton('Edit Profile', Icons.edit_outlined),
      child: Column(
        children: [
          LDCard(
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 34,
                  backgroundColor: ldNavy,
                  child: Text(
                    'S',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sanjeet Dayma',
                        style: TextStyle(
                          color: ldNavy,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text('Administrator', style: TextStyle(color: ldMute)),
                    ],
                  ),
                ),
                const LDStatus(text: 'ACTIVE', color: ldGreen),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: LDCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const LDSectionTitle(title: 'Personal Information'),
                      _value('Name', 'Sanjeet Dayma'),
                      _value('Email', 'Account email'),
                      _value('Role', 'Administrator'),
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
                      const LDSectionTitle(title: 'Work Information'),
                      _value('Company', 'Loss Defender'),
                      _value('Warehouse', 'Main Warehouse'),
                      _value('Access', 'Full operational access'),
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

  Widget _value(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: ldMute, fontSize: 12)),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(color: ldNavy, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
