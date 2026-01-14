import 'package:artgrade/features/student/materials/pdf_view_screen.dart';
import 'package:artgrade/features/student/materials/video_player_screen.dart';
import 'package:artgrade/utils/snackbar.dart';
import 'package:artgrade/utils/validators.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../widgets/app_svg_icon.dart';

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
    _listenUserProgress();
  }

  Uri? _safeUri(String url) {
    final cleaned = url.trim().replaceAll(RegExp(r'\s+'), '');
    if (cleaned.isEmpty) return null;

    if (cleaned.contains('drive.google.com')) {
      final match = RegExp(r'/d/([^/]+)').firstMatch(cleaned);
      if (match != null) {
        final fileId = match.group(1);
        return Uri.parse(
          'https://drive.google.com/uc?export=download&id=$fileId',
        );
      }
    }
    return null;
  }

  Future<void> _handleMaterialTap({
    required String url,
    required String materialId,
    required String type,
    required String title,
  }) async {
    final uri = _safeUri(url);

    if (uri == null || !Validators.isValidNetworkUri(uri)) {
      if (mounted) {
        AppSnackBar.show(
          context,
          "This material link is broken or invalid",
          isError: true,
        );
      }
      return;
    }

    try {
      if (type == 'video') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(
              videoUrl: uri.toString(),
              title: title,
              onCompleted: () => _markAsCompleted(materialId),
            ),
          ),
        );
      } else if (type == 'pdf') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfViewerScreen(url: uri.toString(), title: title),
          ),
        );
      } else {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (!launched) {
          throw const FormatException('Launch failed');
        }
      }

      _markAsCompleted(materialId);
    } catch (e, s) {
      debugPrint("Material open failed: $e");
      debugPrintStack(stackTrace: s);

      if (mounted) {
        AppSnackBar.show(
          context,
          "Material is unavailable or your connection failed",
          isError: true,
        );
      }
    }
  }

  Future<void> _markAsCompleted(String materialId) async {
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
  }

  void _listenUserProgress() {
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
          "Materials",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= HEADER =================
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.subjectTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Access your learning resources below",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // ================= MATERIAL LIST =================
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
                    child: CircularProgressIndicator(color: cs.primary),
                  );
                }

                if (snapshot.hasError) {
                  return _ErrorState();
                }

                final materials = snapshot.data?.docs ?? [];

                if (materials.isEmpty) {
                  return _EmptyState();
                }

                return ListView.separated(
                  // ✅ Bottom padding to clear floating elements if any
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
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
                        type: data['type'] ?? '',
                        title: data['title'] ?? '',
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
}

// ==================================================
// ✅ M3 COMPLIANT MATERIAL CARD
// ==================================================
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
    final cs = Theme.of(context).colorScheme;

    String asset;
    Color accent;
    String label;

    switch (type.toLowerCase()) {
      case 'pdf':
        asset = AppIcons.pdf;
        accent = cs.error;
        label = "PDF Document";
        break;
      case 'video':
        asset = AppIcons.video;
        accent = cs.primary;
        label = "Video Lecture";
        break;
      case 'excel':
        asset = AppIcons.folder;
        accent = cs.tertiary;
        label = "Excel Sheet";
        break;
      default:
        asset = AppIcons.link;
        accent = cs.secondary;
        label = "External Link";
    }

    // ✅ Using Standard M3 Card
    return Card(
      elevation: 2, // M3 Elevation
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // ICON
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: AppSvgIcon(asset: asset, size: 26, color: accent),
                ),
              ),

              const SizedBox(width: 16),

              // INFO
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (isCompleted) ...[
                          AppSvgIcon(
                            asset: AppIcons.checkmark,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Completed",
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: cs.onSurfaceVariant,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                        // Label text (PDF Document, etc.)
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ACTIONS
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: onDownload,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cs.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: AppSvgIcon(
                        asset: AppIcons.download,
                        size: 18,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  AppSvgIcon(
                    asset: AppIcons.arrow_right,
                    size: 20,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
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
            "No materials uploaded yet",
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppSvgIcon(asset: AppIcons.info, size: 48, color: cs.error),
          const SizedBox(height: 16),
          Text(
            "Failed to load materials",
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
