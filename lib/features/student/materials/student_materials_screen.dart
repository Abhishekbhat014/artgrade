import 'package:artgrade/features/student/materials/pdf_view_screen.dart';
import 'package:artgrade/features/student/materials/video_player_screen.dart';
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
    _listenUserProgress();
  }

  Uri? _safeUri(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.contains('drive.google.com/file/d/')) {
      final reg = RegExp(r'/d/([^/]+)');
      final match = reg.firstMatch(trimmed);
      if (match != null) {
        final id = match.group(1);
        return Uri.parse('https://drive.google.com/uc?export=download&id=$id');
      }
    }

    if (!trimmed.startsWith('http')) {
      return Uri.parse('https://$trimmed');
    }

    return Uri.parse(trimmed);
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

  Future<void> _handleMaterialTap({
    required String url,
    required String materialId,
    required String type,
    required String title,
  }) async {
    final uri = _safeUri(url);
    if (uri == null) {
      AppSnackBar.show(context, "Could not open material", isError: true);
      return;
    }

    if (type == 'video') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(
            videoUrl: uri.toString(),
            title: title,
            onCompleted: () async {
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
            },
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
      // fallback (Excel / links)
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    // Progress tracking stays SAME
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
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
// MATERIAL CARD (THEME SAFE)
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

    dynamic icon;
    Color accent;
    String label;

    switch (type.toLowerCase()) {
      case 'pdf':
        icon = HugeIcons.strokeRoundedPdf02;
        accent = cs.error;
        label = "PDF Document";
        break;
      case 'video':
        icon = HugeIcons.strokeRoundedVideoReplay;
        accent = cs.primary;
        label = "Video Lecture";
        break;
      case 'excel':
        icon = HugeIcons.strokeRoundedFile01;
        accent = cs.tertiary;
        label = "Excel Sheet";
        break;
      default:
        icon = HugeIcons.strokeRoundedLink02;
        accent = cs.secondary;
        label = "External Link";
    }

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.08),
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
                // ICON
                Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: HugeIcon(icon: icon, size: 26, color: accent),
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
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedCheckmarkCircle01,
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
                          Text(
                            label,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: cs.onSurfaceVariant),
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
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedDownload01,
                          size: 18,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowRight01,
                      size: 20,
                      color: cs.onSurfaceVariant,
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
          HugeIcon(
            icon: HugeIcons.strokeRoundedFolder02,
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
          HugeIcon(
            icon: HugeIcons.strokeRoundedAlertCircle,
            size: 48,
            color: cs.error,
          ),
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
