import 'package:artgrade/widgets/app_svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artgrade/utils/snackbar.dart';
import 'package:artgrade/utils/validators.dart';

class EditCourseScreen extends StatefulWidget {
  final String courseId;
  final String title;
  final String level;
  final String? description;
  final int? order;
  final bool active;
  final Map<String, dynamic>? additionalDetails;

  const EditCourseScreen({
    super.key,
    required this.courseId,
    required this.title,
    required this.level,
    this.description,
    this.order,
    required this.active,
    this.additionalDetails,
  });

  @override
  State<EditCourseScreen> createState() => _EditCourseScreenState();
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

class _EditCourseScreenState extends State<EditCourseScreen> {
  late final TextEditingController titleCtrl;
  late final TextEditingController levelCtrl;
  late final TextEditingController descCtrl;
  late final TextEditingController orderCtrl;

  final List<_ExtraField> _extraFields = [];

  bool active = true;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(text: widget.title);
    levelCtrl = TextEditingController(text: widget.level);
    descCtrl = TextEditingController(text: widget.description ?? '');
    orderCtrl = TextEditingController(text: widget.order?.toString() ?? '');
    active = widget.active;

    if (widget.additionalDetails != null) {
      widget.additionalDetails!.forEach((key, value) {
        _extraFields.add(_ExtraField(key: key, value: value.toString()));
      });
    }
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    levelCtrl.dispose();
    descCtrl.dispose();
    orderCtrl.dispose();
    for (final f in _extraFields) {
      f.keyCtrl.dispose();
      f.valueCtrl.dispose();
    }
    super.dispose();
  }

  /* =======================================================
     SAVE
   ======================================================= */

  Future<void> _save() async {
    if (loading) return;

    final title = titleCtrl.text.trim();
    final level = levelCtrl.text.trim();
    final desc = descCtrl.text.trim();
    final order = int.tryParse(orderCtrl.text.trim());

    if (!Validators.isNotEmpty(title) || !Validators.isNotEmpty(level)) {
      AppSnackBar.show(context, "Title and Level are required", isError: true);
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
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .update({
            "title": title,
            "level": level,
            "description": desc,
            "order": order,
            "active": active,
            "additionalDetails": extrasMap,
            "updatedAt": Timestamp.now(),
          });

      if (!mounted) return;
      AppSnackBar.show(context, "Course updated successfully");
      Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        AppSnackBar.show(context, "Failed to update course", isError: true);
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _addExtraField() => setState(() => _extraFields.add(_ExtraField()));

  void _removeExtraField(int index) {
    _extraFields[index].keyCtrl.dispose();
    _extraFields[index].valueCtrl.dispose();
    setState(() => _extraFields.removeAt(index));
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
          "Edit Course",
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
                  controller: titleCtrl,
                  style: TextStyle(color: cs.onSurface),
                  decoration: _inputDecor(
                    "Course Title",
                    AppIcons.title,
                    cs: cs,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: levelCtrl,
                  style: TextStyle(color: cs.onSurface),
                  decoration: _inputDecor(
                    "Level",
                    AppIcons.level,
                    hint: "Elementary",
                    cs: cs,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: descCtrl,
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
                  controller: orderCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: cs.onSurface),
                  decoration: _inputDecor("Sort Order", AppIcons.order, cs: cs),
                ),
                const SizedBox(height: 16),

                // Active Switch (M3 Card Style)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: cs.outlineVariant.withOpacity(0.5),
                    ),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      "Active Status",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      "Students can see this course",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    value: active,
                    activeColor: cs.primary,
                    onChanged: (v) => setState(() => active = v),
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
                  onPressed: loading ? null : _save,
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
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
