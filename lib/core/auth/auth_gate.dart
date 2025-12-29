import 'package:artgrade/features/admin/admin_shell.dart';
import 'package:artgrade/features/student/student_shell.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../features/auth/login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        final uid = snapshot.data!.uid;

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .snapshots(),
          builder: (context, userSnap) {
            // 1️⃣ Waiting for Firestore stream
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // 2️⃣ Firestore not ready yet (VERY common just after login)
            if (!userSnap.hasData || !userSnap.data!.exists) {
              return const Scaffold(
                body: Center(child: Text("Setting up your account…")),
              );
            }

            // 3️⃣ Safe to read data
            final data = userSnap.data!.data() as Map<String, dynamic>;
            final role = data['role'] ?? 'student';
            final active = data['active'] ?? true;

            // 4️⃣ Disabled account
            if (!active) {
              return const _DisabledAccountScreen();
            }

            // 5️⃣ Route by role
            return role == 'admin' ? const AdminShell() : const StudentShell();
          },
        );
      },
    );
  }
}

class _DisabledAccountScreen extends StatelessWidget {
  const _DisabledAccountScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ----------------------------------
                  // ICON
                  // ----------------------------------
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedUserBlock01,
                      size: 48,
                      color: Colors.orange,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ----------------------------------
                  // TITLE
                  // ----------------------------------
                  Text(
                    "Account Disabled",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D3142),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ----------------------------------
                  // MESSAGE
                  // ----------------------------------
                  Text(
                    "Your ArtGrade account has been temporarily disabled by the administrator.\n\nIf you believe this is a mistake, please contact support for assistance.",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ----------------------------------
                  // ACTION BUTTON
                  // ----------------------------------
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
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

                  // ----------------------------------
                  // FOOTER (OPTIONAL)
                  // ----------------------------------
                  Text(
                    "ArtGrade • Learn with confidence",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
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
