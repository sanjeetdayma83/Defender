import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api/api_config.dart';
import '../theme/app_theme.dart';
import 'app_widgets.dart';

class LiveStorageUsageCard extends StatefulWidget {
  const LiveStorageUsageCard({super.key});

  @override
  State<LiveStorageUsageCard> createState() => _LiveStorageUsageCardState();
}

class _LiveStorageUsageCardState extends State<LiveStorageUsageCard> {
  Timer? _refreshTimer;

  bool _loading = true;
  bool _refreshing = false;

  double _usedMb = 0;
  int _videoCount = 0;

  String? _error;

  @override
  void initState() {
    super.initState();

    _loadStorageUsage();

    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadStorageUsage(silent: true);
    });
  }

  Future<void> _loadStorageUsage({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    if (silent && mounted) {
      setState(() {
        _refreshing = true;
      });
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.storageBaseUrl}/usage'),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Storage API returned HTTP ${response.statusCode}.');
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid storage usage response.');
      }

      final success = decoded['success'] == true;

      if (!success) {
        throw Exception(
          decoded['message']?.toString() ?? 'Storage usage request failed.',
        );
      }

      final storage = decoded['storage'];

      if (storage is! Map<String, dynamic>) {
        throw Exception('Storage data is missing from API response.');
      }

      final usedMbValue = storage['usedMb'];

      final videoCountValue = storage['videoCount'];

      final usedMb = usedMbValue is num
          ? usedMbValue.toDouble()
          : double.tryParse(usedMbValue?.toString() ?? '') ?? 0;

      final videoCount = videoCountValue is num
          ? videoCountValue.toInt()
          : int.tryParse(videoCountValue?.toString() ?? '') ?? 0;

      if (!mounted) {
        return;
      }

      setState(() {
        _usedMb = usedMb;
        _videoCount = videoCount;
        _loading = false;
        _refreshing = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _refreshing = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _formatStorage() {
    if (_usedMb < 1) {
      final kb = _usedMb * 1024;

      if (kb < 1) {
        return '0 KB';
      }

      return '${kb.toStringAsFixed(1)} KB';
    }

    if (_usedMb >= 1024) {
      final gb = _usedMb / 1024;

      return '${gb.toStringAsFixed(2)} GB';
    }

    return '${_usedMb.toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return LDCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: LDColors.blue.withAlpha(22),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.cloud_done_outlined, color: LDColors.blue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Storage Used',
                  style: TextStyle(color: LDColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 5),
                if (_loading)
                  const SizedBox(
                    height: 30,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else if (_error != null)
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Unavailable',
                          style: TextStyle(
                            color: LDColors.danger,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Retry',
                        onPressed: () {
                          _loadStorageUsage();
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatStorage(),
                          style: const TextStyle(
                            color: LDColors.text,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (_refreshing)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        IconButton(
                          tooltip: 'Refresh storage',
                          onPressed: () {
                            _loadStorageUsage();
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 19),
                        ),
                    ],
                  ),
                if (!_loading && _error == null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '$_videoCount videos stored in B2',
                    style: const TextStyle(color: LDColors.muted, fontSize: 12),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _error!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: LDColors.danger,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
