import 'package:flutter/material.dart';

class _HoverCard extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _HoverCard({super.key, required this.onTap, required this.child});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
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
          elevation: _isHovered ? 8 : 2,
          color: Colors.transparent, // let Material paint the surface
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

class ShortcutCard extends StatelessWidget {
  const ShortcutCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270.0,
      height: 160.0,
      child: _HoverCard(
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
                    'Shortcut',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.edit,
                    size: 20,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
