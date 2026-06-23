import 'package:flutter/material.dart';
import 'package:ui/shortcut.dart';

class _HoverCard extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _HoverCard({super.key, required this.onTap, required this.child});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _isHovered = false;
  bool _suppressHover = false;

  void setSuppressed(bool value) {
    setState(() => _suppressHover = value);
  }

  @override
  Widget build(BuildContext context) {
    final showHover = _isHovered && !_suppressHover;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: AnimatedPhysicalModel(
          duration: const Duration(milliseconds: 150),
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          elevation: showHover ? 8 : 2,
          color: Colors.transparent,
          shadowColor: Colors.black,
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: widget.onTap,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _EditButton extends StatefulWidget {
  final VoidCallback onTap;
  final ValueChanged<bool> onHoverEnter;

  const _EditButton({required this.onTap, required this.onHoverEnter});

  @override
  State<_EditButton> createState() => _EditButtonState();
}

class _EditButtonState extends State<_EditButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _isHovered = true);
        widget.onHoverEnter(true);
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        widget.onHoverEnter(false);
      },
      // fixed-size hit area, no padding shift
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: AnimatedScale(
            duration: const Duration(milliseconds: 150),
            scale: _isHovered ? 1.12 : 1.0,
            child: Material(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: const CircleBorder(),
              elevation: _isHovered ? 6 : 0,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: widget.onTap,
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.edit, size: 20),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ShortcutCard extends StatefulWidget {
  final ShortcutSummary shortcutSummary;
  const ShortcutCard({super.key, required this.shortcutSummary});

  @override
  State<ShortcutCard> createState() => _ShortcutCardState();
}

class _ShortcutCardState extends State<ShortcutCard> {
  final _hoverCardKey = GlobalKey<_HoverCardState>();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270.0,
      height: 160.0,
      child: _HoverCard(
        key: _hoverCardKey,
        onTap: () {},
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 16.0,
                    child: Icon(Icons.star_rounded, size: 24.0),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    widget.shortcutSummary.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    '${widget.shortcutSummary.stepCount} actions',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _EditButton(
                  onTap: () {
                    // edit action — separate from card tap
                  },
                  onHoverEnter: (hovered) {
                    _hoverCardKey.currentState?.setSuppressed(hovered);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
