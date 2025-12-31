import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hugeicons/hugeicons.dart';

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
                  decoration: inputDecor(
                    "Course Title",
                    HugeIcons.strokeRoundedCourse,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: inputDecor(
                    "Description",
                    HugeIcons.strokeRoundedNote01,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _slugCtrl,
                  decoration: inputDecor(
                    "Course ID (Unique Slug)",
                    HugeIcons.strokeRoundedIdentityCard,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _orderCtrl,
                  keyboardType: TextInputType.number,
                  decoration: inputDecor(
                    "Display Order",
                    HugeIcons.strokeRoundedSorting05,
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
                  onPressed: loading ? null : _saveCourse,
                  child: loading
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: cs.onPrimary,
                          ),
                        )
                      : const Text("Save Course"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
