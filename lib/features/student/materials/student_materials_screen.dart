import 'package:artgrade/utils/snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hugeicons/hugeicons.dart';

class MaterialsScreen extends StatefulWidget {
  final String courseId;
  final String subjectId;
  final String subjectTitle;

  const MaterialsScreen({
    super.key,
    required this.courseId,
    required this.subjectId,
    required this.subjectTitle,
  });

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  List<String> completedMaterialIds = [];

  @override
  void initState() {
    super.initState();
    _loadUserProgress();
  }

  Uri? _safeUri(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;

    // Google Drive view → direct download
    if (trimmed.contains('drive.google.com/file/d/')) {
      final reg = RegExp(r'/d/([^/]+)');
      final match = reg.firstMatch(trimmed);
      if (match != null) {
        final fileId = match.group(1);
        return Uri.parse(
          'https://drive.google.com/uc?export=download&id=$fileId',
        );
      }
    }

    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      return Uri.parse('https://$trimmed');
    }

    return Uri.parse(trimmed);
  }

  /// Real-time listener for progress
  void _loadUserProgress() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    FirebaseFirestore.instance
        .collection('user_progress')
        .doc(uid)
        .collection('courses')
        .doc(widget.courseId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists && mounted) {
            setState(() {
              completedMaterialIds = List<String>.from(
                snapshot.data()?['completedMaterials'] ?? [],
              );
            });
          }
        });
  }

  Future<void> _handleMaterialTap({
    required String url,
    required String materialId,
  }) async {
    final uri = _safeUri(url);

    if (uri == null) {
      AppSnackBar.show(context, "Could not open material", isError: true);
      return;
    }

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);

      // Mark completed AFTER successful open
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance
          .collection('user_progress')
          .doc(uid)
          .collection('courses')
          .doc(widget.courseId)
          .set({
            'completedMaterials': FieldValue.arrayUnion([materialId]),
            'updatedAt': Timestamp.now(),
          }, SetOptions(merge: true));
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(context, "Could not open material", isError: true);
    }
  }

  Future<void> _downloadMaterial(String url) async {
    final uri = _safeUri(url);

    if (uri == null) {
      AppSnackBar.show(context, "Can’t download material", isError: true);
      return;
    }

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(context, "Can’t download material", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC), // Consistent Background
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
          "Materials",
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
          // 1. HERO HEADER
          // ------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.subjectTitle,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2D3142),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Access your learning resources below",
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
          // 2. MATERIALS LIST
          // ------------------------------------------
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('courses')
                  .doc(widget.courseId)
                  .collection('subjects')
                  .doc(widget.subjectId)
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
                  return _buildErrorState(theme);
                }

                final materials = snapshot.data!.docs;

                if (materials.isEmpty) {
                  return _buildEmptyState(theme);
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  itemCount: materials.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final material = materials[index];
                    final data = material.data() as Map<String, dynamic>;

                    final isCompleted = completedMaterialIds.contains(
                      material.id,
                    );

                    return _MaterialCard(
                      title: data['title'] ?? 'Untitled',
                      type: data['type'] ?? 'link',
                      isCompleted: isCompleted,
                      onTap: () => _handleMaterialTap(
                        url: data['url'] ?? '',
                        materialId: material.id,
                      ),
                      onDownload: () => _downloadMaterial(data['url'] ?? ''),
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
            "No materials uploaded yet",
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedAlertCircle,
            size: 48,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 16),
          Text(
            "Failed to load materials",
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------
// CUSTOM MATERIAL CARD
// ----------------------------------------
class _MaterialCard extends StatelessWidget {
  final String title;
  final String type;
  final bool isCompleted;
  final VoidCallback onTap;
  final VoidCallback onDownload;

  const _MaterialCard({
    required this.title,
    required this.type,
    required this.isCompleted,
    required this.onTap,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Determine Icon & Color
    dynamic iconData;
    Color typeColor;
    String typeLabel;

    switch (type.toLowerCase()) {
      case 'pdf':
        iconData = HugeIcons.strokeRoundedPdf02;
        typeColor = const Color(0xFFFF5252); // Red
        typeLabel = "PDF Document";
        break;
      case 'video':
        iconData = HugeIcons.strokeRoundedVideoReplay;
        typeColor = const Color(0xFF448AFF); // Blue
        typeLabel = "Video Lecture";
        break;
      case 'excel':
      case 'excel sheet':
        iconData = HugeIcons.strokeRoundedFile01;
        typeColor = const Color(0xFF2E7D32); // Green
        typeLabel = "Excel Sheet";
        break;
      default:
        iconData = HugeIcons.strokeRoundedLink02;
        typeColor = const Color(0xFFFFA000); // Amber
        typeLabel = "External Link";
    }

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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 1. Icon Box
                Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: HugeIcon(icon: iconData, size: 26, color: typeColor),
                  ),
                ),
                const SizedBox(width: 16),

                // 2. Info Section
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Status Row
                      Row(
                        children: [
                          if (isCompleted) ...[
                            const HugeIcon(
                              icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                              size: 14,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Completed",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade600,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                          Text(
                            typeLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 3. Actions
                const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // DOWNLOAD BUTTON (isolated tap)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onDownload,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade50,
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedDownload01,
                          size: 18,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Arrow Indicator
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowRight01,
                      size: 20,
                      color: Colors.grey.shade300,
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
