import 'package:artgrade/widgets/app_svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'subjects/student_subjects_screen.dart';

class StudentHome extends StatelessWidget {
  const StudentHome({super.key});

  static const List<Map<String, dynamic>> _dailyTips = [
    {
      "text": "Master light and shadow before perfecting outlines.",
      "asset": AppIcons.sun,
    },
    {
      "text": "Consistency beats intensity. Sketch for 10 mins daily.",
      "asset": AppIcons.time,
    },
    {
      "text": "Focus on shapes first, details come last.",
      "asset": AppIcons.shape,
    },
    {
      "text": "Your observation skills matter more than speed.",
      "asset": AppIcons.eye,
    },
    {
      "text": "Every expert was once a beginner. Keep going.",
      "asset": AppIcons.rocket,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final todayTip = _dailyTips[DateTime.now().day % _dailyTips.length];

    return Scaffold(
      extendBody: true, // ✅ Allows content to scroll behind floating navbar
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: false,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        title: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            "ArtGrade",
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: AppSvgIcon(
              asset: AppIcons.notification,
              size: 24,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        // ✅ Bottom padding ensures content isn't hidden by the floating navbar
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 1. Greeting Section
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 60);
                }

                String name = "Student";
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  name = data['firstName'] ?? "Student";
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome back, $name",
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Let’s create something amazing today.",
                      style: textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            /// 2. Daily Tip Card
            _HomeInfoCard(
              // Daily tip specific colors
              iconBgColor: cs.primaryContainer,
              iconColor: cs.onPrimaryContainer,
              iconAsset: todayTip['asset'],
              // Content
              title: Text(
                "DAILY TIP",
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: cs.primary,
                ),
              ),
              subtitle: Text(
                todayTip['text'],
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),

            const SizedBox(height: 32),

            /// 3. Continue Learning Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                "Continue Learning",
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 12),

            /// 4. Course Progress Card
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('user_progress')
                  .doc(uid)
                  .collection('courses')
                  .orderBy('updatedAt', descending: true)
                  .limit(1)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const _M3StatusCard(
                    icon: AppIcons.info,
                    text: "Could not load progress.",
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const _M3StatusCard(
                    icon: AppIcons.play,
                    text: "Start a course to track progress.",
                  );
                }

                final courseId = snapshot.data!.docs.first.id;

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('courses')
                      .doc(courseId)
                      .get(),
                  builder: (context, courseSnap) {
                    if (courseSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!courseSnap.hasData || !courseSnap.data!.exists) {
                      return const SizedBox.shrink();
                    }

                    final data =
                        courseSnap.data!.data() as Map<String, dynamic>;
                    final title = data['title'] ?? 'Course';

                    // Using the same unified card component
                    return _HomeInfoCard(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SubjectsScreen(
                              courseId: courseId,
                              courseTitle: title,
                            ),
                          ),
                        );
                      },
                      // Course specific colors
                      iconBgColor: cs.secondaryContainer,
                      iconColor: cs.onSecondaryContainer,
                      iconAsset: AppIcons.play,
                      // Content
                      title: Text(
                        title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        "Tap to resume",
                        style: textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      // Arrow icon for action
                      trailing: AppSvgIcon(
                        asset: AppIcons.arrow_right,
                        color: cs.onSurfaceVariant,
                        size: 20,
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 32),

            /// 5. Fresh Content Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                "Fresh Content",
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

/// ---------------- COMPONENTS ----------------

/// ✅ Standard Material 3 Card
/// Automatically handles Dark Mode surface tinting and Light Mode shadows.
class _HomeInfoCard extends StatelessWidget {
  final VoidCallback? onTap;
  final String iconAsset;
  final Color iconBgColor;
  final Color iconColor;
  final Widget title;
  final Widget subtitle;
  final Widget? trailing;

  const _HomeInfoCard({
    this.onTap,
    required this.iconAsset,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2, // Standard M3 Elevation
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16), // Matches Card Shape
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                height: 48,
                width: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: AppSvgIcon(asset: iconAsset, size: 24, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 4), subtitle],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

/// ✅ Outlined Card for Empty States
class _M3StatusCard extends StatelessWidget {
  final String icon;
  final String text;

  const _M3StatusCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Use a Card with 0 elevation and a Border side for "Outlined" look
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppSvgIcon(asset: icon, size: 20, color: cs.onSurfaceVariant),
            const SizedBox(width: 12),
            Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
