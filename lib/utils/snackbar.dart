import 'dart:async';
import 'package:artgrade/widgets/app_svg_icon.dart';
import 'package:flutter/material.dart';

class AppSnackBar {
  static OverlayEntry? _overlayEntry;
  static Timer? _timer;

  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    // 1. Remove any existing snackbar immediately
    _removeSnackBar();

    final overlayState = Overlay.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // 2. Prepare Colors
    final bg = isError ? cs.errorContainer : cs.primaryContainer;
    final fg = isError ? cs.onErrorContainer : cs.onPrimaryContainer;
    final icon = isError ? AppIcons.info : AppIcons.checkmark;

    // 3. Create the Overlay Entry
    _overlayEntry = OverlayEntry(
      builder: (context) => _TopSnackBarWidget(
        message: message,
        backgroundColor: bg,
        foregroundColor: fg,
        iconAsset: icon,
        onDismiss: _removeSnackBar,
      ),
    );

    // 4. Insert it into the screen
    overlayState.insert(_overlayEntry!);

    // 5. Auto-dismiss after 3 seconds
    _timer = Timer(const Duration(seconds: 3), () {
      _removeSnackBar();
    });
  }

  static void _removeSnackBar() {
    _timer?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;
    _timer = null;
  }
}

// --------------------------------------------------
// 🎨 ANIMATED WIDGET FOR TOP SNACKBAR
// --------------------------------------------------
class _TopSnackBarWidget extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final Color foregroundColor;
  final String iconAsset;
  final VoidCallback onDismiss;

  const _TopSnackBarWidget({
    required this.message,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.iconAsset,
    required this.onDismiss,
  });

  @override
  State<_TopSnackBarWidget> createState() => _TopSnackBarWidgetState();
}

class _TopSnackBarWidgetState extends State<_TopSnackBarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Slide down from top (-1.0) to natural position (0.0)
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      // ✅ Positions it at the top, respecting the notch/status bar
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: Dismissible(
            key: const Key('top_snackbar'),
            direction: DismissDirection.up,
            onDismissed: (_) => widget.onDismiss(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  AppSvgIcon(
                    asset: widget.iconAsset,
                    color: widget.foregroundColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        color: widget.foregroundColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
