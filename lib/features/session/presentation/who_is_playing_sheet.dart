import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veloura/features/session/domain/game_session.dart';
import 'package:veloura/features/session/presentation/session_controller.dart';
import 'package:veloura/shared/widgets/game/primary_cta.dart';
import 'package:veloura/theme/game_tokens.dart';

const _playerColors = [
  0xFFFF4D6D,
  0xFF8E4BD1,
  0xFFFFB703,
  0xFF54D67A,
  0xFF4B9BFF,
  0xFFFF6BD6,
];

/// Name and color editor for the shared two-player session.
class WhoIsPlayingSheet extends ConsumerStatefulWidget {
  const WhoIsPlayingSheet({required this.session, super.key});

  final GameSession session;

  static Future<void> show(
    BuildContext context, {
    required GameSession session,
    bool dismissible = true,
  }) => showModalBottomSheet<void>(
    context: context,
    isDismissible: dismissible,
    enableDrag: dismissible,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => WhoIsPlayingSheet(session: session),
  );

  @override
  ConsumerState<WhoIsPlayingSheet> createState() => _WhoIsPlayingSheetState();
}

class _WhoIsPlayingSheetState extends ConsumerState<WhoIsPlayingSheet> {
  late final TextEditingController _a;
  late final TextEditingController _b;
  late var _colorA = widget.session.a.colorValue;
  late var _colorB = widget.session.b.colorValue;

  @override
  void initState() {
    super.initState();
    _a = TextEditingController(text: widget.session.a.name);
    _b = TextEditingController(text: widget.session.b.name);
  }

  void _cycleA() => setState(() {
    _colorA = _playerColors[(_playerColors.indexOf(_colorA) + 1) % _playerColors.length];
  });

  void _cycleB() => setState(() {
    _colorB = _playerColors[(_playerColors.indexOf(_colorB) + 1) % _playerColors.length];
  });

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: Container(
      height: 360,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: GameTokens.sheet,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Who's playing?", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          _PlayerField(controller: _a, color: _colorA, onColorTap: _cycleA),
          const SizedBox(height: 12),
          _PlayerField(controller: _b, color: _colorB, onColorTap: _cycleB),
          const Spacer(),
          PrimaryCta(
            label: 'Start playing',
            onPressed: () async {
              await ref.read(sessionControllerProvider.notifier).setPlayers(
                    nameA: _a.text,
                    colorA: _colorA,
                    nameB: _b.text,
                    colorB: _colorB,
                  );
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    ),
  );
}

class _PlayerField extends StatelessWidget {
  const _PlayerField({
    required this.controller,
    required this.color,
    required this.onColorTap,
  });

  final TextEditingController controller;
  final int color;
  final VoidCallback onColorTap;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Semantics(
        button: true,
        label: 'Change player color',
        child: InkWell(
          onTap: onColorTap,
          borderRadius: BorderRadius.circular(22),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: Color(color),
            child: Text(
              controller.text.isEmpty ? '?' : controller.text[0].toUpperCase(),
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: TextField(
          controller: controller,
          maxLength: 12,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Name',
            counterText: '',
            filled: true,
          ),
        ),
      ),
    ],
  );
}
