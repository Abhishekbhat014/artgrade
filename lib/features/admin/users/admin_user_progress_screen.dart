import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

class AdminUserProgressScreen extends StatelessWidget {
  final String userId;
  final String userName;

  const AdminUserProgressScreen({
    super.key,
    required this.userId,
    required this.userName,
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
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              userName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            Text(
              "Progress Overview",
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),

      body: SafeArea(
        bottom: true,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('user_progress')
              .doc(userId)
              .collection('courses')
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

            // ---------------- AGGREGATES ----------------
            int totalCompleted = 0;
            for (final doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              totalCompleted +=
                  (data['completedMaterials'] as List?)?.length ?? 0;
            }

            return Column(
              children: [
                // ---------------- STATS HEADER ----------------
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          count: docs.length.toString(),
                          label: "Courses",
                          icon: HugeIcons.strokeRoundedBookOpen01,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          count: totalCompleted.toString(),
                          label: "Activities",
                          icon: HugeIcons.strokeRoundedTaskDaily02,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),

                // ---------------- COURSE LIST ----------------
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      MediaQuery.of(context).padding.bottom + 24,
                    ),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;

                      return _CourseProgressCard(
                        courseId: docs[index].id,
                        completedCount:
                            (data['completedMaterials'] as List?)?.length ?? 0,
                        lastUpdated: (data['updatedAt'] as Timestamp?)
                            ?.toDate(),
                        colorScheme: cs,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ==================================================
// STAT CARD (THEME SAFE)
// ==================================================
class _StatCard extends StatelessWidget {
  final String count;
  final String label;
  final dynamic icon;
  final Color color;

  const _StatCard({
    required this.count,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: HugeIcon(icon: icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==================================================
// COURSE PROGRESS CARD (BOTTOM SAFE)
// ==================================================
class _CourseProgressCard extends StatelessWidget {
  final String courseId;
  final int completedCount;
  final DateTime? lastUpdated;
  final ColorScheme colorScheme;

  const _CourseProgressCard({
    required this.courseId,
    required this.completedCount,
    this.lastUpdated,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .get(),
      builder: (context, snapshot) {
        String title = "Loading...";
        String? level;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          title = data['title'] ?? 'Unknown Course';
          level = data['level'];
        }

        final double progress = completedCount > 0
            ? (completedCount / 10).clamp(0.0, 1.0)
            : 0.02;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedBookOpen01,
                        size: 24,
                        color: colorScheme.primary,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (level != null)
                          Text(
                            level!,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: colorScheme.surfaceContainerHighest,
                color: colorScheme.primary,
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedTime02,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    lastUpdated != null
                        ? "Last active: ${DateFormat('MMM d, h:mm a').format(lastUpdated!)}"
                        : "No activity recorded",
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==================================================
// EMPTY & ERROR STATES
// ==================================================
class _EmptyState extends StatelessWidget {
  final ThemeData theme;
  const _EmptyState({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedNotebook,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            "No progress recorded yet",
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
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
    return Center(
      child: Text(
        "Failed to load user progress",
        style: theme.textTheme.bodyLarge?.copyWith(color: Colors.redAccent),
      ),
    );
  }
}
