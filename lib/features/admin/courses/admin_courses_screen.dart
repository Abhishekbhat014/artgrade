import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hugeicons/hugeicons.dart';

import 'add_courses_screen.dart';
import 'edit_course_screen.dart';
import '../subjects/admin_subjects_screen.dart';

class AdminCoursesScreen extends StatelessWidget {
  const AdminCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "Manage Courses",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Add New Course",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddCourseScreen()),
              );
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, color: cs.onPrimary, size: 20),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('courses')
            .orderBy('order')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: cs.primary));
          }

          if (snapshot.hasError) {
            return _ErrorState(theme: theme);
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _EmptyState(theme: theme);
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return _CourseCard(
                courseId: doc.id,
                title: data['title'] ?? '',
                description: data['description'],
                level: data['level'] ?? '',
                order: data['order'],
                active: data['active'] == true,
                additionalDetails: data['additionalDetails'] is Map
                    ? Map<String, dynamic>.from(data['additionalDetails'])
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}

/* =======================================================
   STATES
======================================================= */

class _EmptyState extends StatelessWidget {
  final ThemeData theme;
  const _EmptyState({required this.theme});

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedBookOpen01,
            size: 64,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            "No courses created yet",
            style: theme.textTheme.titleMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final ThemeData theme;
  const _ErrorState({required this.theme});

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;

    return Center(
      child: Text(
        "Failed to load courses",
        style: theme.textTheme.bodyLarge?.copyWith(color: cs.error),
      ),
    );
  }
}

/* =======================================================
   COURSE CARD
======================================================= */

class _CourseCard extends StatelessWidget {
  final String courseId;
  final String title;
  final String? description;
  final String level;
  final int? order;
  final bool active;
  final Map<String, dynamic>? additionalDetails;

  const _CourseCard({
    required this.courseId,
    required this.title,
    this.description,
    required this.level,
    this.order,
    required this.active,
    this.additionalDetails,
  });

  Future<void> _deleteCourse(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Course"),
        content: const Text(
          "This will permanently delete this course. This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance
        .collection('courses')
        .doc(courseId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AdminSubjectsScreen(courseId: courseId, courseTitle: title),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CourseHeader(
                  title: title,
                  level: level,
                  description: description,
                  active: active,
                ),
                const SizedBox(height: 16),
                Divider(color: cs.outlineVariant),
                const SizedBox(height: 8),

                Row(
                  children: [
                    _StatusChip(active: active),
                    const Spacer(),

                    IconButton(
                      tooltip: 'Edit',
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedPencilEdit02,
                        size: 20,
                        color: cs.primary,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditCourseScreen(
                              courseId: courseId,
                              title: title,
                              description: description,
                              order: order,
                              active: active,
                              level: level,
                              additionalDetails: additionalDetails,
                            ),
                          ),
                        );
                      },
                    ),

                    IconButton(
                      tooltip: 'Delete',
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedDelete02,
                        size: 20,
                        color: cs.error,
                      ),
                      onPressed: () => _deleteCourse(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CourseHeader extends StatelessWidget {
  final String title;
  final String level;
  final String? description;
  final bool active;

  const _CourseHeader({
    required this.title,
    required this.level,
    required this.description,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: active ? cs.primary.withOpacity(0.12) : cs.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedBook01,
              size: 24,
              color: active ? cs.primary : cs.onSurfaceVariant,
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              if (level.isNotEmpty)
                Text(
                  level,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: cs.secondary,
                  ),
                ),
              if (description != null && description!.isNotEmpty)
                Text(
                  description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool active;
  const _StatusChip({required this.active});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = active ? Colors.green : cs.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            active ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            active ? "Active" : "Inactive",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
