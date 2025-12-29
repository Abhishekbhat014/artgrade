import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:artgrade/utils/snackbar.dart';
import 'package:artgrade/utils/validators.dart';

class EditSubjectScreen extends StatefulWidget {
  final String courseId;
  final String subjectId;
  final String title;
  final String? subtitle;

  /// ✅ SAME AS COURSE
  final Map<String, dynamic>? additionalDetails;

  const EditSubjectScreen({
    super.key,
    required this.courseId,
    required this.subjectId,
    required this.title,
    this.subtitle,
    this.additionalDetails,
  });

  @override
  State<EditSubjectScreen> createState() => _EditSubjectScreenState();
}

// ==================================================
// Dynamic Field Model (same as course)
// ==================================================
class _ExtraField {
  final TextEditingController keyCtrl;
  final TextEditingController valueCtrl;

  _ExtraField({String key = '', String value = ''})
    : keyCtrl = TextEditingController(text: key),
      valueCtrl = TextEditingController(text: value);
}

class _EditSubjectScreenState extends State<EditSubjectScreen> {
  late final TextEditingController titleCtrl;
  late final TextEditingController subtitleCtrl;

  final List<_ExtraField> _extraFields = [];

  bool loading = false;

  @override
  void initState() {
    super.initState();

    titleCtrl = TextEditingController(text: widget.title);
    subtitleCtrl = TextEditingController(text: widget.subtitle ?? '');

    // ✅ Populate existing extra fields (MAP → UI)
    if (widget.additionalDetails != null) {
      widget.additionalDetails!.forEach((key, value) {
        _extraFields.add(_ExtraField(key: key, value: value.toString()));
      });
    }
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    subtitleCtrl.dispose();
    for (final field in _extraFields) {
      field.keyCtrl.dispose();
      field.valueCtrl.dispose();
    }
    super.dispose();
  }

  void _addExtraField() {
    setState(() => _extraFields.add(_ExtraField()));
  }

  void _removeExtraField(int index) {
    _extraFields[index].keyCtrl.dispose();
    _extraFields[index].valueCtrl.dispose();
    setState(() => _extraFields.removeAt(index));
  }

  // ==================================================
  // SAVE
  // ==================================================
  Future<void> _save() async {
    if (loading) return;

    final title = titleCtrl.text.trim();
    final subtitle = subtitleCtrl.text.trim();

    if (!Validators.isNotEmpty(title)) {
      AppSnackBar.show(context, "Title is required", isError: true);
      return;
    }

    // Convert UI → MAP (same as course)
    final Map<String, dynamic> extrasMap = {};
    final Set<String> usedKeys = {};

    for (final field in _extraFields) {
      final key = field.keyCtrl.text.trim();
      final value = field.valueCtrl.text.trim();

      if (key.isEmpty || value.isEmpty) continue;

      if (usedKeys.contains(key.toLowerCase())) {
        AppSnackBar.show(
          context,
          "Duplicate field '$key' is not allowed",
          isError: true,
        );
        return;
      }

      usedKeys.add(key.toLowerCase());
      extrasMap[key] = value;
    }

    setState(() => loading = true);

    try {
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('subjects')
          .doc(widget.subjectId)
          .update({
            "title": title,
            if (subtitle.isNotEmpty) "subtitle": subtitle,
            if (subtitle.isEmpty) "subtitle": FieldValue.delete(),

            /// ✅ SAME FIELD NAME AS COURSE
            "additionalDetails": extrasMap,

            "updatedAt": Timestamp.now(),
          });

      if (!mounted) return;
      AppSnackBar.show(context, "Subject updated successfully");
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(context, "Failed to update subject", isError: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ==================================================
  // UI
  // ==================================================
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
        prefixIcon: icon == null
            ? null
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: HugeIcon(
                  icon: icon,
                  size: 20,
                  color: Colors.grey.shade500,
                ),
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Edit Subject",
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
                TextField(
                  controller: titleCtrl,
                  decoration: inputDecor(
                    "Subject Title",
                    HugeIcons.strokeRoundedCourse,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: subtitleCtrl,
                  decoration: inputDecor(
                    "Subtitle (Optional)",
                    HugeIcons.strokeRoundedNote01,
                  ),
                ),
                const SizedBox(height: 32),

                // ---------------- Dynamic Fields ----------------
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
                      icon: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01),
                      label: const Text("Add Field"),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_extraFields.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "No additional fields added",
                      textAlign: TextAlign.center,
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
                              hint: "Time Limit",
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
                              hint: "3 Hours",
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedRemoveCircle,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _removeExtraField(index),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
