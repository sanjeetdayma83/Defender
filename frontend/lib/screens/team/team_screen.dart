import 'package:flutter/material.dart';
import '../screen_ui.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  String query = '';

  final members = const [
    ['Sanjeet Dayma', 'Administrator', 'Active'],
    ['Warehouse Operator', 'Operator', 'Active'],
    ['Quality Reviewer', 'Reviewer', 'Active'],
  ];

  @override
  Widget build(BuildContext context) {
    final list = members
        .where((m) => m.join(' ').toLowerCase().contains(query.toLowerCase()))
        .toList();

    return LDPage(
      title: 'Team',
      subtitle: 'Manage users, roles and operational access.',
      action: ldButton('Invite Member', Icons.person_add_alt_1_rounded),
      child: Column(
        children: [
          SizedBox(
            width: 400,
            child: LDSearch(
              hint: 'Search team members...',
              onChanged: (v) => setState(() => query = v),
            ),
          ),
          const SizedBox(height: 20),
          LDCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: LDSectionTitle(
                      title: 'Members',
                      subtitle: 'Users with access to Loss Defender',
                    ),
                  ),
                ),
                const Divider(height: 1),
                ...list.map(
                  (m) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 5,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: ldBlue.withValues(alpha: .10),
                      child: Text(
                        m[0].substring(0, 1),
                        style: const TextStyle(
                          color: ldBlue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    title: Text(
                      m[0],
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: ldNavy,
                      ),
                    ),
                    subtitle: Text(m[1], style: const TextStyle(color: ldMute)),
                    trailing: LDStatus(text: m[2], color: ldGreen),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
