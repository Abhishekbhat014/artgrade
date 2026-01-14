import 'package:artgrade/features/admin/users/admin_user_progress_screen.dart'; // ✅ Make sure to import the screen
import 'package:artgrade/widgets/app_svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: cs.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (_) => _UserDetailsSheet(
              userId: userId, // ✅ Pass ID for navigation
              name: "$firstName $lastName",
              email: email,
              role: role,
              active: active,
            ),
          );
        },
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
                      : cs.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: AppSvgIcon(
                    asset: AppIcons.user,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildBadge(
                          label: role.toUpperCase(),
                          color: _isAdmin ? Colors.purple : Colors.blue,
                          asset: _isAdmin ? AppIcons.shield : AppIcons.user,
                        ),
                        const SizedBox(width: 8),
                        _buildBadge(
                          label: active ? "ACTIVE" : "DISABLED",
                          color: statusColor,
                          isStatus: true,
                          asset: active ? AppIcons.checkmark : AppIcons.info,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ---------------- SWITCH ----------------
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
                    child: AppSvgIcon(
                      asset: AppIcons.shield,
                      size: 24,
                      color: Colors.purple.withOpacity(0.6),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required Color color,
    required String asset,
    bool isStatus = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            const SizedBox(width: 4),
          ] else ...[
            AppSvgIcon(asset: asset, size: 10, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
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
// USER DETAILS SHEET
// --------------------------------------------------
class _UserDetailsSheet extends StatelessWidget {
  final String userId;
  final String name;
  final String email;
  final String role;
  final bool active;

  const _UserDetailsSheet({
    required this.userId, // ✅ Added userId
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
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            email,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Divider(color: cs.outlineVariant),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text(
                    "ROLE",
                    style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
              Container(height: 30, width: 1, color: cs.outlineVariant),
              Column(
                children: [
                  Text(
                    "STATUS",
                    style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    active ? "ACTIVE" : "DISABLED",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: active ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ✅ NEW: View Progress Button (Only for Students)
          if (role.toLowerCase() == 'student')
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const AppSvgIcon(
                  asset: AppIcons.progress,
                  color: Colors.white,
                  size: 20,
                ),
                label: const Text("View Learning Progress"),
                onPressed: () {
                  Navigator.pop(context); // Close sheet first
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminUserProgressScreen(
                        userId: userId,
                        userName: name,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
