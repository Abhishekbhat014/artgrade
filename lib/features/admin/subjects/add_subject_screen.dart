import 'package:artgrade/widgets/app_svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artgrade/utils/snackbar.dart';
import 'package:artgrade/utils/validators.dart';

class AddSubjectScreen extends StatefulWidget {
  final String courseId;

  const AddSubjectScreen({super.key, required this.courseId});

  @override
  State<AddSubjectScreen> createState() => _AddSubjectScreenState();
}

// --------------------------------------------------
// Dynamic Field Model
// --------------------------------------------------
class _ExtraField {
  final TextEditingController keyCtrl = TextEditingController();
  final TextEditingController valueCtrl = TextEditingController();
}

class _AddSubjectScreenState extends State<AddSubjectScreen> {
  final titleCtrl = TextEditingController();
  final subtitleCtrl = TextEditingController();
  final orderCtrl = TextEditingController();
  final minPersonsCtrl = TextEditingController();

  final List<_ExtraField> _extraFields = [];
  bool loading = false;

  @override
  void dispose() {
    titleCtrl.dispose();
    subtitleCtrl.dispose();
    orderCtrl.dispose();
    minPersonsCtrl.dispose();
    for (final f in _extraFields) {
      f.keyCtrl.dispose();
      f.valueCtrl.dispose();
    }
    super.dispose();
  }

  void _addExtraField() => setState(() => _extraFields.add(_ExtraField()));

  void _removeExtraField(int index) {
    _extraFields[index].keyCtrl.dispose();
    _extraFields[index].valueCtrl.dispose();
    setState(() => _extraFields.removeAt(index));
  }

  // --------------------------------------------------
  // SAVE
  // --------------------------------------------------
  Future<void> _saveSubject() async {
    if (loading) return;

    final title = titleCtrl.text.trim();
    final subtitle = subtitleCtrl.text.trim();
    final order = int.tryParse(orderCtrl.text.trim());
    final minPersons = int.tryParse(minPersonsCtrl.text.trim());

    if (!Validators.isNotEmpty(title) ||
        !Validators.isNotEmpty(subtitle) ||
        order == null) {
      AppSnackBar.show(
        context,
        "Please fill all required fields",
        isError: true,
      );
      return;
    }

    final Map<String, dynamic> additionalDetails = {};
    final Set<String> usedKeys = {};

    for (final f in _extraFields) {
      final k = f.keyCtrl.text.trim();
      final v = f.valueCtrl.text.trim();
      if (k.isEmpty || v.isEmpty) continue;

      if (!usedKeys.add(k.toLowerCase())) {
        AppSnackBar.show(
          context,
          "Duplicate field '$k' is not allowed",
          isError: true,
        );
        return;
      }
      additionalDetails[k] = v;
    }

    setState(() => loading = true);

    try {
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('subjects')
          .add({
            "title": title,
            "subtitle": subtitle,
            "order": order,
            if (minPersons != null) "minPersons": minPersons,
            if (additionalDetails.isNotEmpty)
              "additionalDetails": additionalDetails,
            "createdAt": Timestamp.now(),
          });

      if (!mounted) return;
      AppSnackBar.show(context, "Subject added successfully");
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(context, "Failed to add subject", isError: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // --------------------------------------------------
  // UI (M3 STYLED)
  // --------------------------------------------------
  InputDecoration _inputDecor(
    String label,
    String? asset, {
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
      prefixIcon: asset != null
          ? Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: AppSvgIcon(
                asset: asset,
                size: 22,
                color: cs.onSurfaceVariant,
              ),
            )
          : null,
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
          "Add Subject",
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
                TextField(
                  controller: titleCtrl,
                  style: TextStyle(color: cs.onSurface),
                  decoration: _inputDecor(
                    "Subject Title",
                    AppIcons.title,
                    cs: cs,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: subtitleCtrl,
                  style: TextStyle(color: cs.onSurface),
                  decoration: _inputDecor(
                    "Subtitle",
                    AppIcons.description,
                    cs: cs,
                  ),
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
                const SizedBox(height: 16),

                TextField(
                  controller: minPersonsCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: cs.onSurface),
                  decoration: _inputDecor(
                    "Min Persons (Optional)",
                    AppIcons.user_group,
                    cs: cs,
                  ),
                ),
                const SizedBox(height: 32),

                // Extra Fields Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Additional Details",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addExtraField,
                      icon: AppSvgIcon(
                        asset: AppIcons.plus,
                        size: 18,
                        color: cs.primary,
                      ),
                      label: Text(
                        "Add Field",
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_extraFields.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: cs.outlineVariant.withOpacity(0.5),
                      ),
                    ),
                    child: Column(
                      children: [
                        AppSvgIcon(
                          asset: AppIcons.info,
                          size: 32,
                          color: cs.onSurfaceVariant.withOpacity(0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "No extra fields added yet",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                ..._extraFields.asMap().entries.map((e) {
                  final i = e.key;
                  final f = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: f.keyCtrl,
                            style: TextStyle(color: cs.onSurface),
                            decoration: _inputDecor(
                              "Label",
                              null, // No icon for dynamic labels to save space
                              cs: cs,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: f.valueCtrl,
                            style: TextStyle(color: cs.onSurface),
                            decoration: _inputDecor("Value", null, cs: cs),
                          ),
                        ),
                        IconButton(
                          icon: AppSvgIcon(
                            asset: AppIcons.remove,
                            size: 24,
                            color: cs.error,
                          ),
                          onPressed: () => _removeExtraField(i),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 32),

                FilledButton(
                  onPressed: loading ? null : _saveSubject,
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
                          "Save Subject",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
