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
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Your Progress",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3142),
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
            return _EmptyState(theme: theme);
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

/* =======================================================
   PROGRESS CARD (SAFE MATERIAL COUNT)
======================================================= */

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

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
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
                        Row(
                          children: [
                            Container(
                              height: 48,
                              width: 48,
                              decoration: BoxDecoration(
                                color: cs.primary.withOpacity(0.1),
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
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3142),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Text(
                          "$completedCount / $totalMaterials completed",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 8),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade100,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress == 1 ? Colors.green : cs.primary,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          progress == 1
                              ? "Completed"
                              : progress == 0
                              ? "Not started"
                              : "In progress",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: progress == 1 ? Colors.green : cs.primary,
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

/* =======================================================
   EMPTY STATE
======================================================= */

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
            icon: HugeIcons.strokeRoundedChart01,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            "No progress yet",
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Text(
            "Start learning to see your progress here",
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
