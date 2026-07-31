import 'package:flutter/material.dart';

/// Protects active experiences from accidental back navigation.
class ConfirmExitScope extends StatefulWidget {
  const ConfirmExitScope({required this.child, super.key});

  final Widget child;

  @override
  State<ConfirmExitScope> createState() => _ConfirmExitScopeState();
}

class _ConfirmExitScopeState extends State<ConfirmExitScope> {
  var _allowPop = false;
  var _dialogOpen = false;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _allowPop,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _confirmExit();
    },
    child: widget.child,
  );

  Future<void> _confirmExit() async {
    if (_dialogOpen) return;
    _dialogOpen = true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave this game?'),
        content: const Text('Your current round may be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    _dialogOpen = false;
    if (!mounted || leave != true) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).maybePop();
    });
  }
}
