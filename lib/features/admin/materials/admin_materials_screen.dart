import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hugeicons/hugeicons.dart';

import 'add_material_screen.dart';
import 'edit_material_screen.dart'; // Import the edit screen

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
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: Text(
          "Manage Materials",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3142),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            size: 20,
          ),
          color: Colors.black87,
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: "Add New Material",
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedAdd01,
                size: 20,
                color: Colors.white,
              ),
            ),
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
            color: Colors.white,
            child: Row(
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedLayers01,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  subjectTitle,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.grey.shade700,
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
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _errorState(theme);
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return _emptyState(theme);
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
                      // Safely fetch order or default to 0
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

  Widget _emptyState(ThemeData theme) {
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
            "No materials added yet",
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _errorState(ThemeData theme) {
    return Center(
      child: Text(
        "Failed to load materials",
        style: theme.textTheme.bodyLarge?.copyWith(color: Colors.redAccent),
      ),
    );
  }
}

// --------------------------------------------------
// MATERIAL CARD
// --------------------------------------------------

class _MaterialCard extends StatelessWidget {
  final String materialId;
  final String courseId;
  final String subjectId;
  final String title;
  final String type;
  final String url;
  final int order; // Added order for editing

  const _MaterialCard({
    required this.materialId,
    required this.courseId,
    required this.subjectId,
    required this.title,
    required this.type,
    required this.url,
    required this.order,
  });

  Future<void> _deleteMaterial(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Delete Material",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "This will permanently delete this material link.",
          style: TextStyle(color: Colors.black54, fontSize: 15),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text(
              "Cancel",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "Delete",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
        .collection('materials')
        .doc(materialId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    dynamic iconData;
    Color typeColor;
    String typeLabel;

    switch (type) {
      case 'pdf':
        iconData = HugeIcons.strokeRoundedPdf02;
        typeColor = const Color(0xFFFF5252);
        typeLabel = "PDF Document";
        break;
      case 'video':
        iconData = HugeIcons.strokeRoundedVideoReplay;
        typeColor = const Color(0xFF448AFF);
        typeLabel = "Video Lecture";
        break;
      default:
        iconData = HugeIcons.strokeRoundedLink02;
        typeColor = const Color(0xFF00E676);
        typeLabel = "External Link";
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 1. Icon Box
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: HugeIcon(icon: iconData, size: 26, color: typeColor),
              ),
            ),
            const SizedBox(width: 16),

            // 2. Details
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
                  const SizedBox(height: 4),
                  Text(
                    typeLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),

            // 3. Edit Action
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
              tooltip: "Edit Material",
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedPencilEdit02,
                size: 20,
                color: Colors.blueGrey,
              ),
            ),

            // 4. Delete Action
            IconButton(
              onPressed: () => _deleteMaterial(context),
              tooltip: "Delete Material",
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
}
