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
  final Map<String, dynamic>? additionalDetails; // 1. Receive existing extras

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

// Helper class to manage dynamic controllers
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

  // List to hold dynamic fields
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

    // 2. Populate existing extra fields into controllers
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
    // Dispose dynamic controllers
    for (var field in _extraFields) {
      field.keyCtrl.dispose();
      field.valueCtrl.dispose();
    }
    super.dispose();
  }

  // Add a new blank row
  void _addExtraField() {
    setState(() {
      _extraFields.add(_ExtraField());
    });
  }

  // Remove a specific row
  void _removeExtraField(int index) {
    setState(() {
      _extraFields[index].keyCtrl.dispose();
      _extraFields[index].valueCtrl.dispose();
      _extraFields.removeAt(index);
    });
  }

  // ------------------
  // Save logic
  // ------------------
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

    // 3. Convert dynamic fields back to Map
    Map<String, dynamic> extrasMap = {};
    for (var field in _extraFields) {
      String key = field.keyCtrl.text.trim();
      String value = field.valueCtrl.text.trim();
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
            "additionalDetails": extrasMap, // Save to Firestore
            "updatedAt": Timestamp.now(),
          });

      if (!mounted) return;
      AppSnackBar.show(context, "Course updated successfully");
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(context, "Failed to update course", isError: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    InputDecoration inputDecor(String label, dynamic icon, {String? hint}) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        prefixIcon: icon != null
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: HugeIcon(
                  icon: icon,
                  size: 20,
                  color: Colors.grey.shade500,
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
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
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
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01),
          color: Colors.black87,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Edit Course",
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
                // Standard Fields
                TextField(
                  controller: titleCtrl,
                  decoration: inputDecor(
                    "Course Title",
                    HugeIcons.strokeRoundedCourse,
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: levelCtrl,
                  decoration: inputDecor(
                    "Level",
                    HugeIcons.strokeRoundedDiploma,
                    hint: "e.g. Elementary",
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration:
                      inputDecor(
                        "Description",
                        HugeIcons.strokeRoundedNote01,
                      ).copyWith(
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(
                            left: 12,
                            right: 12,
                            bottom: 44,
                          ),
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedNote01,
                            size: 20,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: orderCtrl,
                  keyboardType: TextInputType.number,
                  decoration: inputDecor(
                    "Sort Order",
                    HugeIcons.strokeRoundedSorting05,
                  ),
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      "Active Status",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      "Students can see this course",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    value: active,
                    activeColor: colorScheme.primary,
                    onChanged: (v) => setState(() => active = v),
                  ),
                ),

                const SizedBox(height: 32),

                // 4. Dynamic Fields Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Additional Details",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addExtraField,
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedAdd01,
                        size: 18,
                      ),
                      label: const Text("Add Field"),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_extraFields.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Text(
                        "No extra fields added.\nTap 'Add Field' to add items like 'Duration', 'Software', etc.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),

                ..._extraFields.asMap().entries.map((entry) {
                  int index = entry.key;
                  _ExtraField field = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedRemoveCircle,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _removeExtraField(index),
                          tooltip: "Remove",
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 32),

                // Save Button
                FilledButton(
                  onPressed: loading ? null : _save,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: loading
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : const Text("Save Changes"),
                ),
                const SizedBox(height: 40), // Bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }
}
