import 'package:flutter/material.dart';

class ResizableContainer extends StatefulWidget {
  const ResizableContainer({
    super.key,
    required this.child,
    this.initialWidth = 200,
    this.minWidth = 100,
    this.maxWidth = 500,
    this.height,
    this.handleWidth = 8,
    this.handleColor,
    this.resizeFromLeft = false,
    this.onWidthChanged,
  });

  final Widget child;
  final double initialWidth;
  final double minWidth;
  final double maxWidth;

  /// Null = match child height.
  final double? height;

  final double handleWidth;
  final Color? handleColor;

  /// Drag handle on the left edge instead of right.
  final bool resizeFromLeft;

  final ValueChanged<double>? onWidthChanged;

  @override
  State<ResizableContainer> createState() => _ResizableContainerState();
}

class _ResizableContainerState extends State<ResizableContainer> {
  late double _width;

  double? _dragStartX;
  double? _dragStartWidth;

  @override
  void initState() {
    super.initState();
    _width = widget.initialWidth.clamp(widget.minWidth, widget.maxWidth);
  }

  void _onDragStart(DragStartDetails d) {
    _dragStartX = d.globalPosition.dx;
    _dragStartWidth = _width;
  }

  void _onDrag(DragUpdateDetails d) {
    final delta = d.globalPosition.dx - _dragStartX!;
    final raw = _dragStartWidth! + (widget.resizeFromLeft ? -delta : delta);
    setState(() {
      _width = raw.clamp(widget.minWidth, widget.maxWidth);
    });
    widget.onWidthChanged?.call(_width);
  }

  Widget _handle(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDrag,
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeLeftRight,
        child: Container(
          width: widget.handleWidth,
          height: widget.height,
          color: widget.handleColor ?? Theme.of(context).dividerColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final container = SizedBox(
      width: _width,
      height: widget.height,
      child: widget.child,
    );

    return IntrinsicHeight(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: widget.resizeFromLeft
            ? [_handle(context), container]
            : [container, _handle(context)],
      ),
    );
  }
}
