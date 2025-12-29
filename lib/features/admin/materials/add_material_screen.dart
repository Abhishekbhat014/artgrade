import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:artgrade/utils/snackbar.dart';
import 'package:artgrade/utils/validators.dart';

class AddMaterialScreen extends StatefulWidget {
  final String courseId;
  final String subjectId;

  const AddMaterialScreen({
    super.key,
    required this.courseId,
    required this.subjectId,
  });

  @override
  State<AddMaterialScreen> createState() => _AddMaterialScreenState();
}

class _AddMaterialScreenState extends State<AddMaterialScreen> {
  final titleCtrl = TextEditingController();
  final urlCtrl = TextEditingController();
  final orderCtrl = TextEditingController();

  String type = 'pdf';
  bool loading = false;

  @override
  void dispose() {
    titleCtrl.dispose();
    urlCtrl.dispose();
    orderCtrl.dispose();
    super.dispose();
  }

  // --------------------------------------------------
  // SAVE
  // --------------------------------------------------
  Future<void> _saveMaterial() async {
    if (loading) return;

    final title = titleCtrl.text.trim();
    final url = urlCtrl.text.trim();
    final order = int.tryParse(orderCtrl.text.trim());

    if (!Validators.isNotEmpty(title) ||
        !Validators.isNotEmpty(url) ||
        order == null) {
      AppSnackBar.show(
        context,
        "Please fill all fields correctly",
        isError: true,
      );
      return;
    }

    setState(() => loading = true);

    try {
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('subjects')
          .doc(widget.subjectId)
          .collection('materials')
          .add({
            "title": title,
            "url": url,
            "type": type,
            "order": order,
            "createdAt": Timestamp.now(),
          });

      if (!mounted) return;
      AppSnackBar.show(context, "Material added successfully");
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(context, "Failed to add material", isError: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // --------------------------------------------------
  // UI
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    InputDecoration inputDecor(String label, dynamic icon, {String? hint}) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: HugeIcon(icon: icon, size: 20, color: Colors.grey.shade500),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 44,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      );
    }

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
        title: Text(
          "Add Material",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3142),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Material Details",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: titleCtrl,
                  decoration: inputDecor(
                    "Material Title",
                    HugeIcons.strokeRoundedCourse,
                  ),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: type,
                  decoration: inputDecor(
                    "Material Type",
                    HugeIcons.strokeRoundedFolder02,
                  ),
                  dropdownColor: Colors.white,
                  items: const [
                    DropdownMenuItem(value: 'pdf', child: Text("PDF Document")),
                    DropdownMenuItem(value: 'video', child: Text("Video")),
                    DropdownMenuItem(
                      value: 'link',
                      child: Text("External Link"),
                    ),
                  ],
                  onChanged: (v) => setState(() => type = v!),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: urlCtrl,
                  keyboardType: TextInputType.url,
                  decoration: inputDecor(
                    "Content URL",
                    HugeIcons.strokeRoundedLink02,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: orderCtrl,
                  keyboardType: TextInputType.number,
                  decoration: inputDecor(
                    "Display Order",
                    HugeIcons.strokeRoundedSorting05,
                  ),
                ),
                const SizedBox(height: 32),

                FilledButton(
                  onPressed: loading ? null : _saveMaterial,
                  child: loading
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: cs.onPrimary,
                          ),
                        )
                      : const Text(
                          "Save Material",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
