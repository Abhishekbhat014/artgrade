import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hugeicons/hugeicons.dart';

import 'add_subject_screen.dart';
import 'edit_subject_screen.dart';
import '../materials/admin_materials_screen.dart';

class AdminSubjectsScreen extends StatelessWidget {
  final String courseId;
  final String courseTitle;

  const AdminSubjectsScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // ✅ Use global theme background (same visual)
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            size: 20,
          ),
          color: Colors.black87,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Manage Subjects",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3142),
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Add New Subject",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddSubjectScreen(courseId: courseId),
                ),
              );
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedAdd01,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),

      body: Column(
        children: [
          // --------------------------------------------------
          // Course Context Header
          // --------------------------------------------------
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            color: Colors.white,
            child: Row(
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedBook01,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  courseTitle,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // --------------------------------------------------
          // Subjects List
          // --------------------------------------------------
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('courses')
                  .doc(courseId)
                  .collection('subjects')
                  .orderBy('order')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
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

                    return _SubjectCard(
                      courseId: courseId,
                      subjectId: doc.id,
                      title: data['title']?.toString() ?? '',
                      subtitle: data['subtitle']?.toString(),
                      minPersons: data['minPersons'] as int?,
                      additionalDetails: data['additionalDetails'] is Map
                          ? Map<String, dynamic>.from(data['additionalDetails'])
                          : null,
                      colorScheme: colorScheme,
                      onOpen: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminMaterialsScreen(
                              courseId: courseId,
                              subjectId: doc.id,
                              subjectTitle: data['title'] ?? '',
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
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
            icon: HugeIcons.strokeRoundedLayers01,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            "No subjects created yet",
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
        "Failed to load subjects",
        style: theme.textTheme.bodyLarge?.copyWith(color: Colors.redAccent),
      ),
    );
  }
}

// ===================================================================
// SUBJECT CARD
// ===================================================================

class _SubjectCard extends StatelessWidget {
  final String courseId;
  final String subjectId;
  final String title;
  final String? subtitle;
  final int? minPersons;
  final VoidCallback onOpen;
  final ColorScheme colorScheme;
  final Map<String, dynamic>? additionalDetails;

  const _SubjectCard({
    required this.courseId,
    required this.subjectId,
    required this.title,
    this.subtitle,
    this.additionalDetails,
    this.minPersons,
    required this.onOpen,
    required this.colorScheme,
  });

  Future<void> _deleteSubject(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Delete Subject",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "This will permanently delete this subject and all materials inside it.\n\nAre you sure?",
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
        .collection('subjects')
        .doc(subjectId)
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
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SubjectHeader(title: title, subtitle: subtitle),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFEEEFF3)),
                const SizedBox(height: 8),
                Row(
                  children: [
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
                            builder: (_) => EditSubjectScreen(
                              courseId: courseId,
                              subjectId: subjectId,
                              title: title,
                              subtitle: subtitle,
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
                      onPressed: () => _deleteSubject(context),
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

// ===================================================================
// SUB-WIDGETS
// ===================================================================

class _SubjectHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SubjectHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedLayers01,
              size: 24,
              color: Colors.orange,
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
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
