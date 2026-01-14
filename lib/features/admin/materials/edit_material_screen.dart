import 'package:artgrade/widgets/app_svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artgrade/utils/snackbar.dart';
import 'package:artgrade/utils/validators.dart';

class EditMaterialScreen extends StatefulWidget {
  final String courseId;
  final String subjectId;
  final String materialId;
  final String title;
  final String type;
  final String url;
  final int order;

  const EditMaterialScreen({
    super.key,
    required this.courseId,
    required this.subjectId,
    required this.materialId,
    required this.title,
    required this.type,
    required this.url,
    required this.order,
  });

  @override
  State<EditMaterialScreen> createState() => _EditMaterialScreenState();
}

class _EditMaterialScreenState extends State<EditMaterialScreen> {
  late final TextEditingController titleCtrl;
  late final TextEditingController urlCtrl;
  late final TextEditingController orderCtrl;

  late String type;
  bool loading = false;

  static const List<String> _validTypes = [
    'pdf',
    'video',
    'link',
    'excel sheet',
  ];

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(text: widget.title);
    urlCtrl = TextEditingController(text: widget.url);
    orderCtrl = TextEditingController(text: widget.order.toString());
    type = _validTypes.contains(widget.type) ? widget.type : 'link';
  }

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
  Future<void> _saveChanges() async {
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
          .doc(widget.materialId)
          .update({
            "title": title,
            "url": url,
            "type": type,
            "order": order,
            "updatedAt": Timestamp.now(),
          });

      if (!mounted) return;
      AppSnackBar.show(context, "Material updated successfully");
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(context, "Failed to update material", isError: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // --------------------------------------------------
  // UI (M3 STYLED)
  // --------------------------------------------------
  InputDecoration _inputDecor(
    String label,
    String asset, {
    String? hint,
    required ColorScheme cs,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: cs.onSurfaceVariant),
      hintStyle: TextStyle(color: cs.onSurfaceVariant.withOpacity(0.5)),
      filled: true,
      fillColor: cs.surfaceContainerHighest.withOpacity(0.5),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 16, right: 12),
        child: AppSvgIcon(asset: asset, size: 22, color: cs.onSurfaceVariant),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

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
          icon: AppSvgIcon(
            asset: AppIcons.arrow_left,
            color: cs.onSurface,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Edit Material",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
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
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: titleCtrl,
                  style: TextStyle(color: cs.onSurface),
                  decoration: _inputDecor(
                    "Material Title",
                    AppIcons.title,
                    cs: cs,
                  ),
                ),
                const SizedBox(height: 16),

                // ✅ M3 Styled Dropdown
                DropdownButtonFormField<String>(
                  value: type,
                  dropdownColor: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 16,
                    fontFamily: theme.textTheme.bodyLarge?.fontFamily,
                  ),
                  decoration: _inputDecor(
                    "Material Type",
                    AppIcons.folder,
                    cs: cs,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'pdf', child: Text("PDF Document")),
                    DropdownMenuItem(value: 'video', child: Text("Video")),
                    DropdownMenuItem(
                      value: 'link',
                      child: Text("External Link"),
                    ),
                    DropdownMenuItem(
                      value: 'excel sheet',
                      child: Text("Excel Sheet"),
                    ),
                  ],
                  onChanged: (v) => setState(() => type = v!),
                  icon: AppSvgIcon(
                    asset: AppIcons.arrow_down,
                    size: 20,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: urlCtrl,
                  keyboardType: TextInputType.url,
                  style: TextStyle(color: cs.onSurface),
                  decoration: _inputDecor("Content URL", AppIcons.link, cs: cs),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: orderCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: cs.onSurface),
                  decoration: _inputDecor(
                    "Display Order",
                    AppIcons.order,
                    cs: cs,
                  ),
                ),
                const SizedBox(height: 32),

                FilledButton(
                  onPressed: loading ? null : _saveChanges,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
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
                          "Save Changes",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
