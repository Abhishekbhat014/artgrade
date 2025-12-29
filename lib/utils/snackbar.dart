import 'package:flutter/material.dart';

class AppSnackBar {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final bg = isError ? cs.errorContainer : cs.primaryContainer;
    final fg = isError ? cs.onErrorContainer : cs.onPrimaryContainer;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: fg,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: fg, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
