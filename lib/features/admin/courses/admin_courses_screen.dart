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
    final colorScheme = theme.colorScheme;

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
            color: const Color(0xFF2D3142),
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
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
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
            return Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            );
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
                title: data['title']?.toString() ?? '',
                description: data['description']?.toString(),
                level: data['level']?.toString() ?? '',
                order: data['order'] as int?,
                active: data['active'] == true,
                additionalDetails: data['additionalDetails'] is Map
                    ? Map<String, dynamic>.from(
                        data['additionalDetails'] as Map,
                      )
                    : null,
                colorScheme: colorScheme,
              );
            },
          );
        },
      ),
    );
  }
}

// ===================================================================
// STATES
// ===================================================================

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
            "No courses created yet",
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
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
    return Center(
      child: Text(
        "Failed to load courses",
        style: theme.textTheme.bodyLarge?.copyWith(color: Colors.redAccent),
      ),
    );
  }
}

// ===================================================================
// COURSE CARD
// ===================================================================

class _CourseCard extends StatelessWidget {
  final String courseId;
  final String title;
  final String? description;
  final String level;
  final int? order;
  final bool active;
  final Map<String, dynamic>? additionalDetails;
  final ColorScheme colorScheme;

  const _CourseCard({
    required this.courseId,
    required this.title,
    this.description,
    required this.level,
    this.order,
    required this.active,
    this.additionalDetails,
    required this.colorScheme,
  });

  Future<void> _deleteCourse(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Delete Course",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _StatusChip(active: active),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Edit',
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedPencilEdit02,
                        size: 20,
                        color: Colors.blueGrey,
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
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedDelete02,
                        size: 20,
                        color: Colors.redAccent,
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
  final ColorScheme colorScheme;

  const _CourseHeader({
    required this.title,
    required this.level,
    required this.description,
    required this.active,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: active
                ? colorScheme.primary.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedBook01,
              size: 24,
              color: active ? colorScheme.primary : Colors.grey,
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
              if (level.isNotEmpty)
                Text(
                  level,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.secondary,
                  ),
                ),
              if (description != null && description!.isNotEmpty)
                Text(
                  description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600),
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
    final color = active ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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
