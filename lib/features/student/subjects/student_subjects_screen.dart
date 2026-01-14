import 'package:artgrade/widgets/app_svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: AppSvgIcon(
            asset: AppIcons.arrow_left,
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
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.courseTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    letterSpacing: -0.5,
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
                if (snapshot.hasError) return _ErrorState();

                final subjects = snapshot.data?.docs ?? [];
                if (subjects.isEmpty) return _EmptyState();

                return ListView.separated(
                  // Padding for Floating Navbar
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
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
// ✅ M3 COMPLIANT SUBJECT CARD
// ==================================================
class _SubjectCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int completedSteps;
  final int totalSteps;
  final VoidCallback onTap;

  const _SubjectCard({
    required this.title,
    this.subtitle,
    required this.completedSteps,
    required this.totalSteps,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bool isCompleted = totalSteps > 0 && completedSteps == totalSteps;
    final bool isStarted = completedSteps > 0;
    final double progress = totalSteps > 0 ? completedSteps / totalSteps : 0;

    // Dynamic Colors
    final Color stateColor = isCompleted
        ? const Color(0xFF4ADE80) // Bright Green
        : isStarted
        ? cs.primary
        : cs.onSurfaceVariant;

    final Color iconBg = isCompleted
        ? const Color(0xFF4ADE80).withOpacity(0.15)
        : isStarted
        ? cs.primary.withOpacity(0.15)
        : cs.surfaceContainerHighest;

    // ✅ Using Standard Card (Theme handles Elevation/Shadows/Tint)
    return Card(
      // Elevation creates shadow in Light Mode, Surface Tint in Dark Mode
      elevation: 2,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16), // Matches Card Theme
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TOP ROW: Icon + Text
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon Box
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: AppSvgIcon(
                        asset: isCompleted ? AppIcons.checkmark : AppIcons.book,
                        size: 22,
                        color: stateColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Titles
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                                height: 1.2,
                              ),
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // BOTTOM ROW: Status Chip + Progress Text
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status Chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isCompleted
                          ? "Completed"
                          : isStarted
                          ? "In Progress"
                          : "Start Learning",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: stateColor,
                      ),
                    ),
                  ),

                  // Percentage Text
                  if (totalSteps > 0)
                    Text(
                      "${(progress * 100).toInt()}%",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: stateColor,
                      ),
                    ),
                ],
              ),

              // PROGRESS BAR
              if (totalSteps > 0) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: isDark
                        ? Colors.white.withOpacity(0.05)
                        : cs.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(stateColor),
                  ),
                ),
              ],
            ],
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
          AppSvgIcon(
            asset: AppIcons.folder,
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
