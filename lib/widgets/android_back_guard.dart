import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AndroidBackGuard extends StatefulWidget {
  const AndroidBackGuard({
    required this.child,
    this.onBlockedPop,
    this.exitHint = 'Press back again to close the app',
    super.key,
  });

  final Widget child;
  final bool Function()? onBlockedPop;
  final String exitHint;

  @override
  State<AndroidBackGuard> createState() => _AndroidBackGuardState();
}

class _AndroidBackGuardState extends State<AndroidBackGuard> {
  DateTime? _lastBackPressAt;

  void _showExitHint() {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(widget.exitHint),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  bool _shouldExitNow() {
    final now = DateTime.now();
    final lastBackPressAt = _lastBackPressAt;
    _lastBackPressAt = now;

    return lastBackPressAt != null &&
        now.difference(lastBackPressAt) < const Duration(seconds: 2);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }

        final handledByChild = widget.onBlockedPop?.call() ?? false;
        if (handledByChild) {
          return;
        }

        if (_shouldExitNow()) {
          SystemNavigator.pop();
          return;
        }

        _showExitHint();
      },
      child: widget.child,
    );
  }
}
