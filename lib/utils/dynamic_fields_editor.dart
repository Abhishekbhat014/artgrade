import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class DynamicFieldsEditor extends StatefulWidget {
  final Map<String, dynamic> initialFields;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const DynamicFieldsEditor({
    super.key,
    required this.initialFields,
    required this.onChanged,
  });

  @override
  State<DynamicFieldsEditor> createState() => _DynamicFieldsEditorState();
}

class _DynamicFieldsEditorState extends State<DynamicFieldsEditor> {
  late Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final e in widget.initialFields.entries)
        e.key: TextEditingController(text: e.value.toString()),
    };
  }

  void _addField() {
    setState(() {
      _controllers["field_${_controllers.length + 1}"] =
          TextEditingController();
    });
    _emit();
  }

  void _removeField(String key) {
    setState(() {
      _controllers[key]?.dispose();
      _controllers.remove(key);
    });
    _emit();
  }

  void _emit() {
    widget.onChanged({
      for (final e in _controllers.entries)
        e.key: e.value.text.trim(),
    });
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Additional Fields",
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),

        ..._controllers.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: entry.value,
                    decoration: InputDecoration(
                      labelText: entry.key,
                    ),
                    onChanged: (_) => _emit(),
                  ),
                ),
                IconButton(
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedDelete02,
                    size: 18,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => _removeField(entry.key),
                ),
              ],
            ),
          );
        }),

        TextButton.icon(
          onPressed: _addField,
          icon: const Icon(Icons.add),
          label: const Text("Add Field"),
        ),
      ],
    );
  }
}
