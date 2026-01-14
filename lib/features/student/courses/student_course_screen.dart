import 'package:artgrade/widgets/app_svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentCoursesScreen extends StatelessWidget {
  final void Function(String courseId, String courseTitle) onOpenCourse;

  const StudentCoursesScreen({super.key, required this.onOpenCourse});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      extendBody: true, // ✅ Allow content to scroll behind floating navbar
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          "All Courses",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // HEADER TEXT
            // ==================================================
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 24),
              child: Text(
                "Explore our curated art courses",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),

            // ==================================================
            // COURSE LIST
            // ==================================================
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('courses')
                    .orderBy('order')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: cs.primary),
                    );
                  }

                  if (!snapshot.hasData) {
                    return _EmptyState();
                  }

                  final courses = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['active'] != false;
                  }).toList();

                  if (courses.isEmpty) {
                    return _EmptyState();
                  }

                  return ListView.separated(
                    // ✅ Padding for Floating Navbar
                    padding: const EdgeInsets.only(bottom: 100, top: 8),
                    itemCount: courses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      final data = course.data() as Map<String, dynamic>;

                      return _CourseCard(
                        title: data['title'] ?? 'Untitled Course',
                        description: data['description'] ?? '',
                        level: data['level'],
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
// ✅ M3 COMPLIANT COURSE CARD
// ==================================================

class _CourseCard extends StatelessWidget {
  final String title;
  final String description;
  final String? level;
  final VoidCallback onTap;

  const _CourseCard({
    required this.title,
    required this.description,
    required this.onTap,
    this.level,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // ✅ Replaced Container+BoxShadow with standard Card
    return Card(
      elevation: 2, // Standard M3 Elevation
      margin: EdgeInsets.zero, // ListView handles spacing
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icon Box
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: AppSvgIcon(
                    asset: AppIcons.paint,
                    size: 28,
                    color: cs.primary,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    if (level != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        level!.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.4,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Arrow Icon
              AppSvgIcon(
                asset: AppIcons.arrow_right,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
            ],
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
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppSvgIcon(
            asset: AppIcons.book,
            size: 64,
            color: cs.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            "No active courses available",
            style: theme.textTheme.titleMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
