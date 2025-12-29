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
  /// All completed material IDs for this course
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
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC), // Consistent background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            size: 20,
          ),
          color: Colors.black87,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Subjects",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3142),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------------------------------------
          // 1. COURSE HEADER
          // ------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.courseTitle,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2D3142),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Select a subject to start learning",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // ------------------------------------------
          // 2. SUBJECT LIST
          // ------------------------------------------
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
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _buildErrorState(theme);
                }

                final subjects = snapshot.data!.docs;

                if (subjects.isEmpty) {
                  return _buildEmptyState(theme);
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
                          colorScheme: colorScheme,
                          onTap: () async {
                            // Wait for navigation so we reload progress when returning
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
                            _loadUserProgress(); // Refresh progress
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

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedFolder02,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            "No subjects found",
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Text(
        "Failed to load subjects",
        style: theme.textTheme.bodyLarge?.copyWith(color: Colors.redAccent),
      ),
    );
  }
}

// ------------------------------------------------------
// SUBJECT CARD
// ------------------------------------------------------
class _SubjectCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int? minPersons;
  final int completedSteps;
  final int totalSteps;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _SubjectCard({
    required this.title,
    this.subtitle,
    this.minPersons,
    required this.completedSteps,
    required this.totalSteps,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = totalSteps > 0 && completedSteps == totalSteps;
    final bool isStarted = completedSteps > 0;
    final double progress = totalSteps > 0 ? completedSteps / totalSteps : 0;

    // Define colors based on state
    final Color iconColor = isCompleted
        ? const Color(0xFF00C853) // Green
        : isStarted
        ? colorScheme.primary
        : Colors.grey.shade400;

    final Color bgColor = isCompleted
        ? const Color(0xFFE8F5E9) // Light Green
        : isStarted
        ? colorScheme.primary.withOpacity(0.1)
        : Colors.grey.shade100;

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
                // 1. Header Row
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
                          color: iconColor,
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
                          if (subtitle != null && subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Min Persons Badge
                    if (minPersons != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const HugeIcon(
                              icon: HugeIcons.strokeRoundedUserGroup,
                              size: 14,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "$minPersons+",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFEEEFF3)),
                const SizedBox(height: 12),

                // 2. Progress Footer
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
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isCompleted
                              ? Colors.green
                              : Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        "${(progress * 100).toInt()}%",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isCompleted
                              ? Colors.green
                              : colorScheme.primary,
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
                      backgroundColor: Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted ? Colors.green : colorScheme.primary,
                      ),
                    ),
                  ),
                ] else
                  // If no materials
                  Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedInformationCircle,
                        size: 14,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Coming Soon",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w500,
                        ),
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
