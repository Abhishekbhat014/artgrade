import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class StudentProgressScreen extends StatelessWidget {
  const StudentProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Your Progress",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user_progress')
            .doc(uid)
            .collection('courses')
            .snapshots(),
        builder: (context, progressSnap) {
          if (progressSnap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: cs.primary));
          }

          if (!progressSnap.hasData || progressSnap.data!.docs.isEmpty) {
            return const _EmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            itemCount: progressSnap.data!.docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final progressDoc = progressSnap.data!.docs[index];
              final progressData = progressDoc.data() as Map<String, dynamic>;

              final completedMaterials = List<String>.from(
                progressData['completedMaterials'] ?? [],
              );

              return _ProgressCard(
                courseId: progressDoc.id,
                completedCount: completedMaterials.length,
              );
            },
          );
        },
      ),
    );
  }
}

// =======================================================
// PROGRESS CARD (THEME SAFE)
// =======================================================

class _ProgressCard extends StatelessWidget {
  final String courseId;
  final int completedCount;

  const _ProgressCard({required this.courseId, required this.completedCount});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .get(),
      builder: (context, courseSnap) {
        if (!courseSnap.hasData || !courseSnap.data!.exists) {
          return const SizedBox.shrink();
        }

        final course = courseSnap.data!.data() as Map<String, dynamic>;

        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('courses')
              .doc(courseId)
              .collection('subjects')
              .get(),
          builder: (context, subjectSnap) {
            if (!subjectSnap.hasData) {
              return const SizedBox.shrink();
            }

            final subjects = subjectSnap.data!.docs;

            return FutureBuilder<int>(
              future: _countAllMaterials(courseId, subjects),
              builder: (context, totalSnap) {
                final totalMaterials = totalSnap.data ?? 0;
                final double progress = totalMaterials == 0
                    ? 0
                    : completedCount / totalMaterials;

                final Color progressColor = progress == 1
                    ? Colors.green
                    : cs.primary;

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
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HEADER
                        Row(
                          children: [
                            Container(
                              height: 48,
                              width: 48,
                              decoration: BoxDecoration(
                                color: cs.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: HugeIcon(
                                  icon: HugeIcons.strokeRoundedChart01,
                                  size: 24,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                course['title'] ?? 'Course',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: cs.onSurface,
                                    ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // COUNT
                        Text(
                          "$completedCount / $totalMaterials completed",
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: cs.onSurfaceVariant,
                              ),
                        ),

                        const SizedBox(height: 8),

                        // PROGRESS BAR
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: cs.surfaceVariant,
                            valueColor: AlwaysStoppedAnimation(progressColor),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // STATUS
                        Text(
                          progress == 1
                              ? "Completed"
                              : progress == 0
                              ? "Not started"
                              : "In progress",
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: progressColor,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// 🔢 Counts ALL materials across ALL subjects
  Future<int> _countAllMaterials(
    String courseId,
    List<QueryDocumentSnapshot> subjects,
  ) async {
    int total = 0;

    for (final subject in subjects) {
      final materialsSnap = await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .collection('subjects')
          .doc(subject.id)
          .collection('materials')
          .get();

      total += materialsSnap.docs.length;
    }

    return total;
  }
}

// =======================================================
// EMPTY STATE (THEME SAFE)
// =======================================================

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedChart01,
            size: 64,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            "No progress yet",
            style: theme.textTheme.titleMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Start learning to see your progress here",
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
