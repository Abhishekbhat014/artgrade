import 'package:artgrade/widgets/app_svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: AppSvgIcon(asset: AppIcons.arrow_left, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Manage Subjects",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
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
                color: cs.primary,
                shape: BoxShape.circle,
              ),
              child: AppSvgIcon(
                asset: AppIcons.plus,
                size: 20,
                color: cs.onPrimary, // Ensure contrast
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),

      body: Column(
        children: [
          // --------------------------------------------------
          // COURSE CONTEXT HEADER (M3 Style)
          // --------------------------------------------------
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.5),
              border: Border(
                bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
              ),
            ),
            child: Row(
              children: [
                AppSvgIcon(
                  asset: AppIcons.book,
                  size: 16,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  courseTitle,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // --------------------------------------------------
          // SUBJECT LIST
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
                    child: CircularProgressIndicator(color: cs.primary),
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
                  // ✅ Bottom Padding for Floating Navbar
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
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
          AppSvgIcon(
            asset: AppIcons.subject,
            size: 64,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            "No subjects created yet",
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
        "Failed to load subjects",
        style: theme.textTheme.bodyLarge?.copyWith(color: cs.error),
      ),
    );
  }
}

/* =======================================================
   SUBJECT CARD (M3 COMPLIANT)
======================================================= */

class _SubjectCard extends StatelessWidget {
  final String courseId;
  final String subjectId;
  final String title;
  final String? subtitle;
  final int? minPersons;
  final VoidCallback onOpen;
  final Map<String, dynamic>? additionalDetails;

  const _SubjectCard({
    required this.courseId,
    required this.subjectId,
    required this.title,
    this.subtitle,
    this.additionalDetails,
    this.minPersons,
    required this.onOpen,
  });

  Future<void> _deleteSubject(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Subject"),
        content: const Text(
          "This will permanently delete this subject and all materials inside it.",
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
        .collection('subjects')
        .doc(subjectId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // ✅ Standard M3 Card (Theme handles shadow/tint)
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SubjectHeader(title: title, subtitle: subtitle),
              const SizedBox(height: 16),
              Divider(height: 1, color: cs.outlineVariant.withOpacity(0.5)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Spacer(),
                  IconButton(
                    tooltip: 'Edit',
                    icon: AppSvgIcon(
                      asset: AppIcons.edit,
                      size: 20,
                      color: cs.primary,
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
                    icon: AppSvgIcon(
                      asset: AppIcons.delete,
                      size: 20,
                      color: cs.error,
                    ),
                    onPressed: () => _deleteSubject(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* =======================================================
   SUBJECT HEADER (M3 COMPLIANT)
======================================================= */

class _SubjectHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SubjectHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: cs.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: AppSvgIcon(
              asset: AppIcons.subject,
              size: 24,
              color: cs.onSecondaryContainer,
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
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
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
