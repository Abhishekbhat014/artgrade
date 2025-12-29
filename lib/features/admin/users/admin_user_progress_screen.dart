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
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC), // Standard background
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: Colors.black87,
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              userName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3142),
              ),
            ),
            Text(
              "Progress Overview",
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user_progress')
            .doc(userId)
            .collection('courses')
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

          // Calculate Aggregates
          int totalCompleted = 0;
          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            totalCompleted +=
                (data['completedMaterials'] as List?)?.length ?? 0;
          }

          return Column(
            children: [
              // 1. Stats Header (Matching Dashboard Style)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
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

              // 2. List of Courses
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;

                    return _CourseProgressCard(
                      courseId: docs[index].id,
                      completedCount:
                          (data['completedMaterials'] as List?)?.length ?? 0,
                      lastUpdated: (data['updatedAt'] as Timestamp?)?.toDate(),
                      colorScheme: colorScheme,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ==================================================
// 1. STAT CARD (Matches Dashboard)
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
              color: color.withOpacity(0.1),
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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
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
// 2. COURSE PROGRESS CARD (Matches AdminCoursesScreen)
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
    //
    // Fetch course details to show real title instead of ID
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

        // Simulating a progress calculation (In real app, fetch total materials count)
        // For visual demo, if completed > 0, show 50%, else 5%
        final double progress = completedCount > 0
            ? (completedCount / 10).clamp(0.0, 1.0)
            : 0.02;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04), // Matches other screens
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3142),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (level != null)
                          Text(
                            level,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Progress Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Progress",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    "$completedCount activities",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade100,
                  color: colorScheme.primary,
                ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFEEEFF3)),
              const SizedBox(height: 12),

              // Footer: Last Updated
              Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedTime02,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    lastUpdated != null
                        ? "Last active: ${DateFormat('MMM d, h:mm a').format(lastUpdated!)}"
                        : "No activity recorded",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
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
// 3. EMPTY & ERROR STATES
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
          const HugeIcon(
            icon: HugeIcons.strokeRoundedNotebook,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            "No progress recorded yet",
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
        "Failed to load user progress",
        style: theme.textTheme.bodyLarge?.copyWith(color: Colors.redAccent),
      ),
    );
  }
}
