import 'package:flutter/material.dart';
import '../screen_ui.dart';

class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({super.key});

  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen> {
  String query = '';

  final recordings = const [
    ['368275770371', '97-U1YR-N3GW', '16s', '4.8 MB', 'VERIFIED'],
    ['FMPP3767030215', 'DG-LT-S', '35s', '5.2 MB', 'VERIFIED'],
    ['1490841263428112', 'PC-TWISTER-001', '21s', '3.7 MB', 'PROCESSING'],
  ];

  @override
  Widget build(BuildContext context) {
    final list = recordings
        .where((r) => r.join(' ').toLowerCase().contains(query.toLowerCase()))
        .toList();

    return LDPage(
      title: 'Recordings',
      subtitle:
          'Review packing recordings captured during shipment processing.',
      action: ldButton('Refresh', Icons.refresh_rounded),
      child: Column(
        children: [
          SizedBox(
            width: 400,
            child: LDSearch(
              hint: 'Search AWB or SKU...',
              onChanged: (v) => setState(() => query = v),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: LDStat(
                  label: 'Recordings',
                  value: '${recordings.length}',
                  icon: Icons.videocam_outlined,
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
                  label: 'Storage',
                  value: '13.7 MB',
                  icon: Icons.storage_outlined,
                  color: ldCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (list.isEmpty)
            const LDEmpty(
              icon: Icons.videocam_off_outlined,
              title: 'No recordings',
              subtitle: 'Matching recordings will appear here.',
            )
          else
            ...list.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: LDCard(
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: ldNavy,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r[0],
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: ldNavy,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'SKU ${r[1]}',
                              style: const TextStyle(color: ldMute),
                            ),
                          ],
                        ),
                      ),
                      if (MediaQuery.sizeOf(context).width > 650)
                        Text(
                          '${r[2]} • ${r[3]}',
                          style: const TextStyle(
                            color: ldMute,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      const SizedBox(width: 16),
                      LDStatus(
                        text: r[4],
                        color: r[4] == 'VERIFIED' ? ldGreen : ldAmber,
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.more_horiz_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
