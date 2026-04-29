import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/navigation_providers.dart';

class AppBarPortal extends ConsumerStatefulWidget {
  final List<Widget> actions;
  final String? title;

  const AppBarPortal({
    super.key,
    required this.actions,
    this.title,
  });

  @override
  ConsumerState<AppBarPortal> createState() => _AppBarPortalState();
}

class _AppBarPortalState extends ConsumerState<AppBarPortal> {
  @override
  void initState() {
    super.initState();
    _update();
  }

  @override
  void didUpdateWidget(AppBarPortal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.actions != widget.actions || oldWidget.title != widget.title) {
      _update();
    }
  }

  void _update() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(appBarActionsProvider.notifier).state = widget.actions;
      if (widget.title != null) {
        ref.read(appBarTitleProvider.notifier).state = widget.title;
      }
    });
  }

  @override
  void dispose() {
    // Clear actions when leaving the screen
    // We do this immediately to avoid "ref used after dispose" in postFrameCallback
    ref.read(appBarActionsProvider.notifier).state = [];
    ref.read(appBarTitleProvider.notifier).state = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
