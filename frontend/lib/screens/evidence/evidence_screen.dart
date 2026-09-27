import 'package:flutter/material.dart';
import '../screen_ui.dart';

class EvidenceScreen extends StatefulWidget {
  const EvidenceScreen({super.key});

  @override
  State<EvidenceScreen> createState() => _EvidenceScreenState();
}

class _EvidenceScreenState extends State<EvidenceScreen> {
  String query = '';

  final evidence = const [
    ['368275770371', '406-3151945-3281902', 'Video', 'VERIFIED', '16s'],
    ['FMPP3767030215', 'FK-3767030215', 'Video', 'VERIFIED', '35s'],
    ['1490841263428112', '331724360573683072_1', 'Video', 'PROCESSING', '21s'],
  ];

  @override
  Widget build(BuildContext context) {
    final list = evidence
        .where((e) => e.join(' ').toLowerCase().contains(query.toLowerCase()))
        .toList();

    return LDPage(
      title: 'Evidence',
      subtitle: 'Packing proof linked to orders, shipments and sessions.',
      action: ldButton('Refresh', Icons.refresh_rounded),
      child: Column(
        children: [
          SizedBox(
            width: 420,
            child: LDSearch(
              hint: 'Search AWB, order or evidence...',
              onChanged: (v) => setState(() => query = v),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: LDStat(
                  label: 'Evidence Items',
                  value: '${evidence.length}',
                  icon: Icons.folder_copy_outlined,
                  color: ldBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LDStat(
                  label: 'Verified',
                  value: '2',
                  icon: Icons.verified_outlined,
                  color: ldGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LDStat(
                  label: 'Processing',
                  value: '1',
                  icon: Icons.sync_rounded,
                  color: ldAmber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (list.isEmpty)
            const LDEmpty(
              icon: Icons.folder_open_outlined,
              title: 'No evidence found',
              subtitle: 'Evidence matching your search will appear here.',
            )
          else
            LDCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(18),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: LDSectionTitle(
                        title: 'Evidence Timeline',
                        subtitle: 'Shipment-level proof records',
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ...list.map(
                    (e) => ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 7,
                      ),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFEFF6FF),
                        child: Icon(Icons.videocam_outlined, color: ldBlue),
                      ),
                      title: Text(
                        e[0],
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: ldNavy,
                        ),
                      ),
                      subtitle: Text(
                        '${e[1]} • ${e[2]} • ${e[4]}',
                        style: const TextStyle(color: ldMute),
                      ),
                      trailing: LDStatus(
                        text: e[3],
                        color: e[3] == 'VERIFIED' ? ldGreen : ldAmber,
                      ),
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
