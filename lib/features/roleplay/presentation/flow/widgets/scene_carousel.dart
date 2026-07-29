import 'package:flutter/material.dart';
import 'package:veloura/features/roleplay/domain/roleplay_story.dart';
import 'package:veloura/features/roleplay/presentation/flow/widgets/scene_card.dart';

/// Centred scene pager with scaled, faded neighbours.
class SceneCarousel extends StatefulWidget {
  const SceneCarousel({
    required this.stories,
    required this.isPremium,
    required this.onChanged,
    super.key,
  });

  final List<RoleplayStory> stories;
  final bool isPremium;
  final ValueChanged<RoleplayStory> onChanged;

  @override
  State<SceneCarousel> createState() => _SceneCarouselState();
}

class _SceneCarouselState extends State<SceneCarousel> {
  late final PageController _controller;
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.78)
      ..addListener(() => setState(() => _page = _controller.page ?? 0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageView.builder(
    controller: _controller,
    clipBehavior: Clip.none,
    itemCount: widget.stories.length,
    onPageChanged: (index) => widget.onChanged(widget.stories[index]),
    itemBuilder: (context, index) {
      final distance = (_page - index).abs().clamp(0.0, 1.0);
      return Transform.scale(
        scale: 1 - (distance * 0.08),
        child: Opacity(
          opacity: 1 - (distance * 0.40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            child: SceneCard(
              story: widget.stories[index],
              locked: widget.stories[index].premium && !widget.isPremium,
            ),
          ),
        ),
      );
    },
  );
}
