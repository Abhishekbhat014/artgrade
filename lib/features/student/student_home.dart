import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hugeicons/hugeicons.dart';

import 'subjects/student_subjects_screen.dart';

class StudentHome extends StatelessWidget {
  const StudentHome({super.key});

  // Updated Trendy Tips (No Emojis)
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

    // Get today's tip based on day of year
    final todayTip = _dailyTips[DateTime.now().day % _dailyTips.length];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            "ArtGrade",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF2D3142),
              letterSpacing: -0.5,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedNotification03,
              size: 24,
              color: Colors.black87,
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
            // ==================================================
            // 1. GREETING SECTION
            // ==================================================
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .get(),
              builder: (context, snapshot) {
                // 1️⃣ Loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 60,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                // 2️⃣ Document missing (very common just after signup)
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Welcome back, Student",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "Let’s continue your creative journey",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  );
                }

                // 3️⃣ Safe to read fields
                final data = snapshot.data!.data() as Map<String, dynamic>;
                final name = data['firstName'] ?? 'Student';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome back, $name",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Let’s continue your creative journey",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            // ==================================================
            // 2. TRENDY TIP CARD
            // ==================================================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cs.primary.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
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
                      icon: todayTip['icon'], // Dynamic Icon
                      size: 24,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "PRO TIP",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: cs.primary,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          todayTip['text'], // Dynamic Text
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3142),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ==================================================
            // 3. CONTINUE LEARNING (Hero Card)
            // ==================================================
            _SectionHeader(title: "Continue Learning"),
            const SizedBox(height: 16),

            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('user_progress')
                  .doc(uid)
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return _EmptyStateCard(
                    icon: HugeIcons.strokeRoundedPlay,
                    text: "Start a course to track progress",
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                if (data.isEmpty) {
                  return _EmptyStateCard(
                    icon: HugeIcons.strokeRoundedPlay,
                    text: "No active courses found",
                  );
                }

                // Get the first course ID found in progress
                final firstCourseId = data.keys.first;

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('courses')
                      .doc(firstCourseId)
                      .get(),
                  builder: (context, courseSnap) {
                    if (!courseSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final course = courseSnap.data!;
                    return _ContinueLearningCard(
                      title: course['title'],
                      subtitle: "Resume where you left off",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SubjectsScreen(
                              courseId: course.id,
                              courseTitle: course['title'],
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

            // ==================================================
            // 4. NEW MATERIALS
            // ==================================================
            _SectionHeader(title: "Fresh Content"),
            const SizedBox(height: 16),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collectionGroup('materials')
                  .orderBy('createdAt', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _EmptyStateCard(
                    icon: HugeIcons.strokeRoundedFolder02,
                    text: "No new materials available",
                  );
                }

                return ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: snapshot.data!.docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final d =
                        snapshot.data!.docs[index].data()
                            as Map<String, dynamic>;
                    return _MaterialListCard(
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

// ==================================================
// REUSABLE COMPONENTS (Unchanged Logic, just visual polish)
// ==================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D3142),
      ),
    );
  }
}

class _ContinueLearningCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContinueLearningCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedPlay,
                      size: 28,
                      color: cs.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  size: 24,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MaterialListCard extends StatelessWidget {
  final String title;
  final String type;

  const _MaterialListCard({required this.title, required this.type});

  @override
  Widget build(BuildContext context) {
    dynamic icon;
    Color color;

    switch (type) {
      case 'video':
        icon = HugeIcons.strokeRoundedVideoReplay;
        color = Colors.blueAccent;
        break;
      case 'pdf':
        icon = HugeIcons.strokeRoundedPdf02;
        color = Colors.redAccent;
        break;
      default:
        icon = HugeIcons.strokeRoundedLink02;
        color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: HugeIcon(icon: icon, size: 20, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3142),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  type.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade400,
                    letterSpacing: 0.5,
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

class _EmptyStateCard extends StatelessWidget {
  final dynamic icon;
  final String text;

  const _EmptyStateCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          HugeIcon(icon: icon, size: 32, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
