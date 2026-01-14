import 'package:artgrade/widgets/app_svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
          icon: AppSvgIcon(asset: AppIcons.arrow_left, color: cs.onSurface),
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
              child: AppSvgIcon(
                asset: AppIcons.plus,
                size: 20,
                color: cs.onPrimary, // Ensure high contrast
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),

      body: Column(
        children: [
          // Context Header (M3 Style)
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
                  asset: AppIcons.subject,
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
                  // ✅ Bottom Padding for Floating Navbar
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
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
          AppSvgIcon(
            asset: AppIcons.folder,
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
// MATERIAL CARD (M3 COMPLIANT)
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

  Future<void> _delete(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    String asset;
    Color color;
    String label;

    switch (type) {
      case 'pdf':
        asset = AppIcons.pdf;
        color = cs.error;
        label = "PDF Document";
        break;
      case 'video':
        asset = AppIcons.video;
        color = cs.primary;
        label = "Video Lecture";
        break;
      default:
        asset = AppIcons.link;
        color = Colors.green;
        label = "External Link";
    }

    // ✅ Standard M3 Card (Theme handles shadow/tint)
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                child: AppSvgIcon(asset: asset, size: 26, color: color),
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
                      fontWeight: FontWeight.w500,
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
              icon: AppSvgIcon(
                asset: AppIcons.edit,
                size: 20,
                color: cs.primary,
              ),
            ),

            IconButton(
              onPressed: () => _delete(context),
              icon: AppSvgIcon(
                asset: AppIcons.delete,
                size: 20,
                color: cs.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
