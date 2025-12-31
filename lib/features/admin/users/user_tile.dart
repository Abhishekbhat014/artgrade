import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:artgrade/utils/snackbar.dart';

class UserTile extends StatelessWidget {
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final bool active;

  const UserTile({
    super.key,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.active,
  });

  bool get _isAdmin => role.toLowerCase() == 'admin';

  // --------------------------------------------------
  // STATUS TOGGLE
  // --------------------------------------------------
  Future<void> _toggleStatus(BuildContext context) async {
    if (_isAdmin) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'active': !active,
      });

      if (!context.mounted) return;
      AppSnackBar.show(context, active ? "User disabled" : "User activated");
    } catch (_) {
      if (!context.mounted) return;
      AppSnackBar.show(context, "Failed to update user status", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final statusColor = active ? Colors.green : Colors.redAccent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),

        // ---------------- USER DETAILS ----------------
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: cs.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (_) => _UserDetailsSheet(
              name: "$firstName $lastName",
              email: email,
              role: role,
              active: active,
            ),
          );
        },

        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // ---------------- AVATAR ----------------
                Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: active
                        ? cs.primary.withOpacity(0.15)
                        : cs.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedUser,
                      size: 24,
                      color: active ? cs.primary : cs.onSurfaceVariant,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // ---------------- USER INFO ----------------
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$firstName $lastName",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          _buildBadge(
                            label: role.toUpperCase(),
                            color: _isAdmin ? Colors.purple : Colors.blue,
                            icon: _isAdmin
                                ? HugeIcons.strokeRoundedChampion
                                : HugeIcons.strokeRoundedUser,
                          ),
                          const SizedBox(width: 8),
                          _buildBadge(
                            label: active ? "ACTIVE" : "DISABLED",
                            color: statusColor,
                            isStatus: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ---------------- ACTION ----------------
                if (!_isAdmin)
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: active,
                      activeColor: cs.onPrimary,
                      activeTrackColor: Colors.green,
                      inactiveThumbColor: cs.onPrimary,
                      inactiveTrackColor: Colors.red.shade300,
                      trackOutlineColor: WidgetStateProperty.all(
                        Colors.transparent,
                      ),
                      onChanged: (_) => _toggleStatus(context),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Tooltip(
                      message: "Cannot disable Admin",
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedSecurityCheck,
                        size: 24,
                        color: Colors.purple.withOpacity(0.6),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // BADGE
  // --------------------------------------------------
  Widget _buildBadge({
    required String label,
    required Color color,
    dynamic icon,
    bool isStatus = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isStatus) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          if (icon != null) ...[
            HugeIcon(icon: icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------
// USER DETAILS SHEET (DARK MODE SAFE)
// --------------------------------------------------
class _UserDetailsSheet extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  final bool active;

  const _UserDetailsSheet({
    required this.name,
    required this.email,
    required this.role,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            email,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Role: ${role.toUpperCase()}",
            style: theme.textTheme.bodyMedium,
          ),
          Text(
            "Status: ${active ? "ACTIVE" : "DISABLED"}",
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
