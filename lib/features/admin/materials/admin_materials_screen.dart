import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hugeicons/hugeicons.dart';

import 'add_material_screen.dart';
import 'edit_material_screen.dart';

class AdminMaterialsScreen extends StatelessWidget {
  final String courseId;
  final String subjectId;
  final String subjectTitle;

  const AdminMaterialsScreen({
    super.key,
    required this.courseId,
    required this.subjectId,
    required this.subjectTitle,
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
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Manage Materials",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Add New Material",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddMaterialScreen(
                    courseId: courseId,
                    subjectId: subjectId,
                  ),
                ),
              );
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedAdd01,
                size: 20,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),

      body: Column(
        children: [
          // Context Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            color: cs.surface,
            child: Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedLayers01,
                  size: 16,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  subjectTitle,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('courses')
                  .doc(courseId)
                  .collection('subjects')
                  .doc(subjectId)
                  .collection('materials')
                  .orderBy('order')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: cs.primary),
                  );
                }

                if (snapshot.hasError) {
                  return _errorState(context);
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return _emptyState(context);
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return _MaterialCard(
                      materialId: doc.id,
                      courseId: courseId,
                      subjectId: subjectId,
                      title: data['title'] ?? '',
                      type: data['type'] ?? 'link',
                      url: data['url'] ?? '',
                      order: (data['order'] as num?)?.toInt() ?? 0,
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

  Widget _emptyState(BuildContext context) {
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
            "No materials added yet",
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _errorState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Text(
        "Failed to load materials",
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: cs.error),
      ),
    );
  }
}

// --------------------------------------------------
// MATERIAL CARD (THEME SAFE)
// --------------------------------------------------

class _MaterialCard extends StatelessWidget {
  final String materialId;
  final String courseId;
  final String subjectId;
  final String title;
  final String type;
  final String url;
  final int order;

  const _MaterialCard({
    required this.materialId,
    required this.courseId,
    required this.subjectId,
    required this.title,
    required this.type,
    required this.url,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    dynamic icon;
    Color color;
    String label;

    switch (type) {
      case 'pdf':
        icon = HugeIcons.strokeRoundedPdf02;
        color = Colors.redAccent;
        label = "PDF Document";
        break;
      case 'video':
        icon = HugeIcons.strokeRoundedVideoReplay;
        color = Colors.blueAccent;
        label = "Video Lecture";
        break;
      default:
        icon = HugeIcons.strokeRoundedLink02;
        color = Colors.green;
        label = "External Link";
    }

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: HugeIcon(icon: icon, size: 26, color: color),
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
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditMaterialScreen(
                      courseId: courseId,
                      subjectId: subjectId,
                      materialId: materialId,
                      title: title,
                      type: type,
                      url: url,
                      order: order,
                    ),
                  ),
                );
              },
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedPencilEdit02,
                size: 20,
                color: cs.primary,
              ),
            ),

            IconButton(
              onPressed: () => _delete(context),
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedDelete02,
                size: 20,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Material"),
        content: const Text("This will permanently delete this material."),
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

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .collection('subjects')
          .doc(subjectId)
          .collection('materials')
          .doc(materialId)
          .delete();
    }
  }
}
