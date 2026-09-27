import 'package:flutter/material.dart';

import '../../models/identity/current_user.dart';

class LDIdentityCard extends StatelessWidget {
  final CurrentUser user;
  final VoidCallback? onProfile;
  final VoidCallback? onLogout;

  const LDIdentityCard({
    super.key,
    required this.user,
    this.onProfile,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final companyName = user.company?.name.isNotEmpty == true
        ? user.company!.name
        : 'No company';

    final warehouseName = user.warehouse?.name.isNotEmpty == true
        ? user.warehouse!.name
        : 'No warehouse';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: const Color(0xFF2563EB),
                child: Text(
                  _initials(user.name, user.email),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name.isEmpty ? 'User' : user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _infoRow(Icons.business_rounded, 'Company', companyName),

          const SizedBox(height: 10),

          _infoRow(Icons.warehouse_rounded, 'Warehouse', warehouseName),

          const SizedBox(height: 10),

          _infoRow(Icons.admin_panel_settings_rounded, 'Role', user.role),

          if (onProfile != null || onLogout != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                if (onProfile != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onProfile,
                      icon: const Icon(Icons.person_outline_rounded, size: 18),
                      label: const Text('Profile'),
                    ),
                  ),
                if (onProfile != null && onLogout != null)
                  const SizedBox(width: 8),
                if (onLogout != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onLogout,
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Logout'),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 17, color: const Color(0xFF64748B)),
        const SizedBox(width: 9),
        Text(
          '$label:',
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  String _initials(String name, String email) {
    final source = name.trim().isNotEmpty ? name.trim() : email;

    final parts = source
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'U';
    }

    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
