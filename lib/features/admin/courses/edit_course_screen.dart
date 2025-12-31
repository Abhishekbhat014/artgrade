import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hugeicons/hugeicons.dart';

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
     UI
  ======================================================= */

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    InputDecoration inputDecor(String label, dynamic icon, {String? hint}) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: cs.surfaceVariant,
        prefixIcon: icon != null
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: HugeIcon(
                  icon: icon,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
              )
            : null,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 44,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
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
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: cs.onSurface,
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
                  decoration: inputDecor(
                    "Course Title",
                    HugeIcons.strokeRoundedCourse,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: levelCtrl,
                  decoration: inputDecor(
                    "Level",
                    HugeIcons.strokeRoundedDiploma,
                    hint: "Elementary",
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: inputDecor(
                    "Description",
                    HugeIcons.strokeRoundedNote01,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: orderCtrl,
                  keyboardType: TextInputType.number,
                  decoration: inputDecor(
                    "Sort Order",
                    HugeIcons.strokeRoundedSorting05,
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      "Active Status",
                      style: theme.textTheme.titleMedium,
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
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedAdd01,
                        size: 18,
                      ),
                      label: const Text("Add Field"),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_extraFields.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "No extra fields added",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.onSurfaceVariant),
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
                            decoration: inputDecor(
                              "Label",
                              null,
                              hint: "Duration",
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: field.valueCtrl,
                            decoration: inputDecor(
                              "Value",
                              null,
                              hint: "4 Weeks",
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _removeExtraField(index),
                          icon: HugeIcon(
                            icon: HugeIcons.strokeRoundedRemoveCircle,
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
                  child: loading
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: cs.onPrimary,
                          ),
                        )
                      : const Text("Save Changes"),
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
