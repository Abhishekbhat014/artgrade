import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hugeicons/hugeicons.dart';

class StudentCoursesScreen extends StatelessWidget {
  final void Function(String courseId, String courseTitle) onOpenCourse;

  const StudentCoursesScreen({super.key, required this.onOpenCourse});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          "All Courses",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3142),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // GREETING
            // ==================================================
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .get(),
              builder: (context, snapshot) {
                return Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Explore our curated art courses",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // ==================================================
            // COURSE LIST
            // ==================================================
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('courses')
                    .orderBy('order') // ✅ SAFE
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: cs.primary),
                    );
                  }

                  if (!snapshot.hasData) {
                    return _EmptyState(theme: theme);
                  }

                  /// ✅ FILTER ACTIVE COURSES SAFELY
                  final courses = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['active'] != false; // null or true = allowed
                  }).toList();

                  if (courses.isEmpty) {
                    return _EmptyState(theme: theme);
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 32),
                    itemCount: courses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      final data = course.data() as Map<String, dynamic>;

                      return _CourseCard(
                        title: data['title'] ?? 'Untitled Course',
                        description: data['description'] ?? '',
                        level: data['level'],
                        colorScheme: cs,
                        onTap: () {
                          onOpenCourse(course.id, data['title'] ?? 'Course');
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================
// COURSE CARD (UNCHANGED DESIGN)
// ==================================================

class _CourseCard extends StatelessWidget {
  final String title;
  final String description;
  final String? level;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _CourseCard({
    required this.title,
    required this.description,
    required this.colorScheme,
    required this.onTap,
    this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedPaintBoard,
                      size: 28,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

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
                      ),
                      if (level != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          level!.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 12),
                HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  size: 16,
                  color: Colors.grey.shade300,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================================================
// EMPTY STATE
// ==================================================

class _EmptyState extends StatelessWidget {
  final ThemeData theme;
  const _EmptyState({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedBookOpen01,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            "No active courses available",
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
