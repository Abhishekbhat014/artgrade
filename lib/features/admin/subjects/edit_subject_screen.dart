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

    if (widget.additionalDetails != null) {
      widget.additionalDetails!.forEach((k, v) {
        _extraFields.add(_ExtraField(key: k, value: v.toString()));
      });
    }
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    subtitleCtrl.dispose();
    for (final f in _extraFields) {
      f.keyCtrl.dispose();
      f.valueCtrl.dispose();
    }
    super.dispose();
  }

  void _addExtraField() => setState(() => _extraFields.add(_ExtraField()));

  void _removeExtraField(int i) {
    _extraFields[i].keyCtrl.dispose();
    _extraFields[i].valueCtrl.dispose();
    setState(() => _extraFields.removeAt(i));
  }

  Future<void> _save() async {
    if (loading) return;

    final title = titleCtrl.text.trim();
    final subtitle = subtitleCtrl.text.trim();

    if (!Validators.isNotEmpty(title)) {
      AppSnackBar.show(context, "Title is required", isError: true);
      return;
    }

    final Map<String, dynamic> extras = {};
    final used = <String>{};

    for (final f in _extraFields) {
      final k = f.keyCtrl.text.trim();
      final v = f.valueCtrl.text.trim();
      if (k.isEmpty || v.isEmpty) continue;

      if (!used.add(k.toLowerCase())) {
        AppSnackBar.show(context, "Duplicate field '$k'", isError: true);
        return;
      }
      extras[k] = v;
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
            "additionalDetails": extras,
            "updatedAt": Timestamp.now(),
          });

      if (!mounted) return;
      AppSnackBar.show(context, "Subject updated successfully");
      Navigator.pop(context);
    } catch (_) {
      AppSnackBar.show(context, "Failed to update subject", isError: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    InputDecoration decor(String label, dynamic icon, {String? hint}) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: cs.surface,
        labelStyle: TextStyle(color: cs.onSurfaceVariant),
        prefixIcon: icon == null
            ? null
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: HugeIcon(
                  icon: icon,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Edit Subject",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: decor(
                  "Subject Title",
                  HugeIcons.strokeRoundedCourse,
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: subtitleCtrl,
                decoration: decor(
                  "Subtitle (Optional)",
                  HugeIcons.strokeRoundedNote01,
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
                    color: cs.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "No additional fields added",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.onSurfaceVariant),
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
                          decoration: decor("Label", null, hint: "Time Limit"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: f.valueCtrl,
                          decoration: decor("Value", null, hint: "3 Hours"),
                        ),
                      ),
                      IconButton(
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedRemoveCircle,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => _removeExtraField(i),
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
    );
  }
}
