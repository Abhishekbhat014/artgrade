import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hugeicons/hugeicons.dart';

import 'subjects/student_subjects_screen.dart';

class StudentHome extends StatelessWidget {
  const StudentHome({super.key});

  static const List<Map<String, dynamic>> _dailyTips = [
    {
      "text": "Master light and shadow before perfecting outlines.",
      "icon": HugeIcons.strokeRoundedSun03,
    },
    {
      "text": "Consistency beats intensity. Sketch for 10 mins daily.",
      "icon": HugeIcons.strokeRoundedTime02,
    },
    {
      "text": "Focus on shapes first, details come last.",
      "icon": HugeIcons.strokeRoundedShapes,
    },
    {
      "text": "Your observation skills matter more than speed.",
      "icon": HugeIcons.strokeRoundedEye,
    },
    {
      "text": "Every expert was once a beginner. Keep going.",
      "icon": HugeIcons.strokeRoundedRocket01,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final todayTip = _dailyTips[DateTime.now().day % _dailyTips.length];

    final twoDaysAgo = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(days: 2)),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            "ArtGrade",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedNotification03,
              size: 24,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// GREETING
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .get(),
              builder: (context, snapshot) {
                final name = snapshot.data?.get('firstName') ?? 'Student';
                return _Greeting(name: name);
              },
            ),

            const SizedBox(height: 32),

            /// PRO TIP (UNCHANGED)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cs.primary.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: HugeIcon(
                      icon: todayTip['icon'],
                      size: 24,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      todayTip['text'],
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            /// CONTINUE LEARNING (LOGIC FIXED, UI SAME)
            Text(
              "Continue Learning",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('user_progress')
                  .doc(uid)
                  .collection('courses')
                  .orderBy('updatedAt', descending: true)
                  .limit(1)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _EmptyState(
                    icon: HugeIcons.strokeRoundedPlay,
                    text: "Start a course to track progress",
                  );
                }

                final courseId = snapshot.data!.docs.first.id;

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('courses')
                      .doc(courseId)
                      .get(),
                  builder: (context, courseSnap) {
                    if (!courseSnap.hasData) {
                      return const CircularProgressIndicator();
                    }

                    return _ContinueCard(
                      title: courseSnap.data!['title'],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SubjectsScreen(
                              courseId: courseId,
                              courseTitle: courseSnap.data!['title'],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 32),

            /// FRESH CONTENT (2 DAYS FILTER, UI SAME)
            Text(
              "Fresh Content",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collectionGroup('materials')
                  .where('createdAt', isGreaterThan: twoDaysAgo)
                  .orderBy('createdAt', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _EmptyState(
                    icon: HugeIcons.strokeRoundedFolder02,
                    text: "No new materials available",
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final d =
                        snapshot.data!.docs[index].data()
                            as Map<String, dynamic>;

                    return _MaterialCard(
                      title: d['title'] ?? 'Untitled',
                      type: d['type'] ?? 'link',
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

/// ---------------- COMPONENTS ----------------

class _Greeting extends StatelessWidget {
  final String name;
  const _Greeting({required this.name});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome back, $name",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Let’s continue your creative journey",
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _ContinueCard({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: cs.primary.withOpacity(0.1),
          child: HugeIcon(icon: HugeIcons.strokeRoundedPlay, color: cs.primary),
        ),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "Resume where you left off",
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        trailing: HugeIcon(
          icon: HugeIcons.strokeRoundedArrowRight01,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final String title;
  final String type;

  const _MaterialCard({required this.title, required this.type});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedFolder02,
            size: 20,
            color: cs.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final dynamic icon;
  final String text;

  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          HugeIcon(icon: icon, size: 32, color: cs.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
