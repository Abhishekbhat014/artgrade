import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hugeicons/hugeicons.dart';

import '../materials/student_materials_screen.dart';

class SubjectsScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;

  const SubjectsScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  List<String> completedMaterials = [];

  @override
  void initState() {
    super.initState();
    _loadUserProgress();
  }

  Future<void> _loadUserProgress() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection('user_progress')
        .doc(uid)
        .collection('courses')
        .doc(widget.courseId)
        .get();

    if (!doc.exists) return;

    if (mounted) {
      setState(() {
        completedMaterials = List<String>.from(
          doc.data()?['completedMaterials'] ?? [],
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            size: 20,
            color: cs.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Subjects",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= COURSE HEADER =================
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.courseTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Select a subject to start learning",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // ================= SUBJECT LIST =================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('courses')
                  .doc(widget.courseId)
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
                  return _ErrorState();
                }

                final subjects = snapshot.data?.docs ?? [];

                if (subjects.isEmpty) {
                  return _EmptyState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  itemCount: subjects.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final subject = subjects[index];
                    final subjectData = subject.data() as Map<String, dynamic>;

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('courses')
                          .doc(widget.courseId)
                          .collection('subjects')
                          .doc(subject.id)
                          .collection('materials')
                          .snapshots(),
                      builder: (context, matSnap) {
                        final totalMaterials = matSnap.data?.docs.length ?? 0;

                        final completedForSubject =
                            matSnap.data?.docs
                                .where((m) => completedMaterials.contains(m.id))
                                .length ??
                            0;

                        return _SubjectCard(
                          title: subjectData['title'] ?? 'Untitled',
                          subtitle: subjectData['subtitle'],
                          minPersons: subjectData['minPersons'],
                          completedSteps: completedForSubject,
                          totalSteps: totalMaterials,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MaterialsScreen(
                                  courseId: widget.courseId,
                                  subjectId: subject.id,
                                  subjectTitle: subjectData['title'] ?? '',
                                ),
                              ),
                            );
                            _loadUserProgress();
                          },
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

// ==================================================
// SUBJECT CARD (THEME SAFE)
// ==================================================
class _SubjectCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int? minPersons;
  final int completedSteps;
  final int totalSteps;
  final VoidCallback onTap;

  const _SubjectCard({
    required this.title,
    this.subtitle,
    this.minPersons,
    required this.completedSteps,
    required this.totalSteps,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bool isCompleted = totalSteps > 0 && completedSteps == totalSteps;
    final bool isStarted = completedSteps > 0;
    final double progress = totalSteps > 0 ? completedSteps / totalSteps : 0;

    final Color stateColor = isCompleted
        ? Colors.green
        : isStarted
        ? cs.primary
        : cs.onSurfaceVariant;

    final Color bgColor = isCompleted
        ? Colors.green.withOpacity(0.12)
        : isStarted
        ? cs.primary.withOpacity(0.12)
        : cs.surfaceVariant;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: HugeIcon(
                          icon: isCompleted
                              ? HugeIcons.strokeRoundedCheckmarkCircle02
                              : HugeIcons.strokeRoundedBookOpen01,
                          size: 24,
                          color: stateColor,
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
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                          ),
                          if (subtitle != null && subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ],
                      ),
                    ),

                    if (minPersons != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: cs.tertiary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedUserGroup,
                              size: 14,
                              color: cs.tertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "$minPersons+",
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cs.tertiary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),
                Divider(color: cs.outlineVariant),
                const SizedBox(height: 12),

                // FOOTER
                if (totalSteps > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isCompleted
                            ? "Completed"
                            : isStarted
                            ? "In Progress"
                            : "Not Started",
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: stateColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        "${(progress * 100).toInt()}%",
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: stateColor,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: cs.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation(stateColor),
                    ),
                  ),
                ] else
                  Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedInformationCircle,
                        size: 14,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Coming Soon",
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: cs.onSurfaceVariant),
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

// ==================================================
// EMPTY & ERROR STATES
// ==================================================

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedFolder02,
            size: 64,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            "No subjects found",
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Text(
        "Failed to load subjects",
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: cs.error),
      ),
    );
  }
}
