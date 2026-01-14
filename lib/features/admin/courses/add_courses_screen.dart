import 'package:artgrade/widgets/app_svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artgrade/utils/snackbar.dart';
import 'package:artgrade/utils/validators.dart';

class AddCourseScreen extends StatefulWidget {
  const AddCourseScreen({super.key});

  @override
  State<AddCourseScreen> createState() => _AddCourseScreenState();
}

/* =======================================================
   EXTRA FIELD MODEL
======================================================= */

class _ExtraField {
  final TextEditingController keyCtrl;
  final TextEditingController valueCtrl;

  _ExtraField({String key = '', String value = ''})
    : keyCtrl = TextEditingController(text: key),
      valueCtrl = TextEditingController(text: value);
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();
  final _orderCtrl = TextEditingController();

  final List<_ExtraField> _extraFields = [];

  bool loading = false;

  /* =======================================================
     EXTRA FIELDS HANDLING
   ======================================================= */

  void _addExtraField() {
    setState(() => _extraFields.add(_ExtraField()));
  }

  void _removeExtraField(int index) {
    _extraFields[index].keyCtrl.dispose();
    _extraFields[index].valueCtrl.dispose();
    setState(() => _extraFields.removeAt(index));
  }

  /* =======================================================
     SAVE COURSE
   ======================================================= */

  Future<void> _saveCourse() async {
    if (loading) return;

    final title = _titleCtrl.text.trim();
    final description = _descCtrl.text.trim();
    final slug = _slugCtrl.text.trim().toLowerCase();
    final order = int.tryParse(_orderCtrl.text.trim());

    if (!Validators.isNotEmpty(title) ||
        !Validators.isNotEmpty(description) ||
        !Validators.isNotEmpty(slug) ||
        order == null) {
      AppSnackBar.show(
        context,
        "Please fill all fields correctly",
        isError: true,
      );
      return;
    }

    final validSlug = RegExp(r'^[a-z0-9_-]+$');
    if (!validSlug.hasMatch(slug)) {
      AppSnackBar.show(
        context,
        "Course ID must use lowercase letters, numbers, '-' or '_'",
        isError: true,
      );
      return;
    }

    final Map<String, dynamic> extrasMap = {};
    for (final field in _extraFields) {
      final key = field.keyCtrl.text.trim();
      final value = field.valueCtrl.text.trim();
      if (key.isNotEmpty && value.isNotEmpty) {
        extrasMap[key] = value;
      }
    }

    setState(() => loading = true);

    try {
      final courseRef = FirebaseFirestore.instance
          .collection('courses')
          .doc(slug);

      final existing = await courseRef.get();
      if (existing.exists) {
        AppSnackBar.show(
          context,
          "Course ID '$slug' already exists",
          isError: true,
        );
        setState(() => loading = false);
        return;
      }

      await courseRef.set({
        "title": title,
        "description": description,
        "order": order,
        "active": true,
        "additionalDetails": extrasMap,
        "createdAt": Timestamp.now(),
      });

      if (!mounted) return;
      AppSnackBar.show(context, "Course added successfully");

      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        AppSnackBar.show(context, "Failed to save course", isError: true);
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _slugCtrl.dispose();
    _orderCtrl.dispose();
    for (final field in _extraFields) {
      field.keyCtrl.dispose();
      field.valueCtrl.dispose();
    }
    super.dispose();
  }

  /* =======================================================
     UI (M3 Styled)
   ======================================================= */

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
          "Add Course",
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
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _titleCtrl,
                  style: TextStyle(color: cs.onSurface),
                  decoration: _inputDecor(
                    "Course Title",
                    AppIcons.title,
                    cs: cs,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _descCtrl,
                  maxLines: 3,
                  style: TextStyle(color: cs.onSurface),
                  decoration: _inputDecor(
                    "Description",
                    AppIcons.description,
                    cs: cs,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _slugCtrl,
                  style: TextStyle(color: cs.onSurface),
                  decoration: _inputDecor(
                    "Course ID (Unique Slug)",
                    AppIcons.id,
                    cs: cs,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _orderCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: cs.onSurface),
                  decoration: _inputDecor(
                    "Display Order",
                    AppIcons.order,
                    cs: cs,
                  ),
                ),

                const SizedBox(height: 32),

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
                          "No extra fields added",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                ..._extraFields.asMap().entries.map((entry) {
                  final index = entry.key;
                  final field = entry.value;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: field.keyCtrl,
                            style: TextStyle(color: cs.onSurface),
                            decoration: _inputDecor(
                              "Label",
                              AppIcons.label,
                              hint: "Duration",
                              cs: cs,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: field.valueCtrl,
                            style: TextStyle(color: cs.onSurface),
                            decoration: _inputDecor(
                              "Value",
                              AppIcons.blur,
                              hint: "4 Weeks",
                              cs: cs,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _removeExtraField(index),
                          icon: AppSvgIcon(
                            asset: AppIcons.remove,
                            size: 24,
                            color: cs.error,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 32),

                FilledButton(
                  onPressed: loading ? null : _saveCourse,
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
                          "Save Course",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
