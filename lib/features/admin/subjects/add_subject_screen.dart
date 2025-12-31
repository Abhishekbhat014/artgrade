import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hugeicons/hugeicons.dart';

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
  // UI
  // --------------------------------------------------
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
                  decoration: decor(
                    "Subject Title",
                    HugeIcons.strokeRoundedHeading02,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: subtitleCtrl,
                  decoration: decor("Subtitle", HugeIcons.strokeRoundedNote01),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: orderCtrl,
                  keyboardType: TextInputType.number,
                  decoration: decor(
                    "Display Order",
                    HugeIcons.strokeRoundedSorting05,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: minPersonsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: decor(
                    "Min Persons (Optional)",
                    HugeIcons.strokeRoundedUserGroup,
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
                      "No extra fields added yet",
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
                            decoration: decor("Label", null),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: f.valueCtrl,
                            decoration: decor("Value", null),
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
                  onPressed: loading ? null : _saveSubject,
                  child: loading
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: cs.onPrimary,
                          ),
                        )
                      : const Text("Save Subject"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
