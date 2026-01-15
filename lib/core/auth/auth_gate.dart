import 'package:artgrade/core/complete_profile_screen.dart';
import 'package:artgrade/features/admin/admin_shell.dart';
import 'package:artgrade/features/student/student_shell.dart';
import 'package:artgrade/widgets/app_svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/auth/login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!authSnap.hasData) {
          return const KeyedSubtree(
            key: ValueKey('logged_out'),
            child: LoginScreen(),
          );
        }

        final uid = authSnap.data!.uid;
        return KeyedSubtree(
          key: ValueKey('logged_in_$uid'),
          child: _UserRouter(uid: uid),
        );
      },
    );
  }
}

class _UserRouter extends StatelessWidget {
  final String uid;
  const _UserRouter({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, userSnap) {
        if (userSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!userSnap.hasData || !userSnap.data!.exists) {
          return const Scaffold(
            body: Center(child: Text("Setting up your account…")),
          );
        }

        final data = userSnap.data!.data() as Map<String, dynamic>;

        final role = data['role'] ?? 'student';
        final active = data['active'] ?? true;
        final profileComplete = data['profileComplete'] ?? false;

        // 🚫 Disabled account
        if (!active) {
          return const _DisabledAccountScreen();
        }

        // 🧩 Incomplete profile
        if (!profileComplete) {
          return const CompleteProfileScreen();
        }

        // 🏁 Final destination
        return role == 'admin'
            ? AdminShell(key: ValueKey('admin_$uid'))
            : StudentShell(key: ValueKey('student_$uid'));
      },
    );
  }
}

// =======================================================
// 🚫 DISABLED ACCOUNT SCREEN (UNCHANGED)
// =======================================================

class _DisabledAccountScreen extends StatelessWidget {
  const _DisabledAccountScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: cs.tertiary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: AppSvgIcon(
                      asset: AppIcons.user_block,
                      size: 48,
                      color: cs.tertiary,
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    "Account Disabled",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    "Your ArtGrade account has been temporarily disabled by the administrator.\n\nIf you believe this is a mistake, please contact support for assistance.",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      color: cs.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Back to Login",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    "ArtGrade • Learn with confidence",
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
