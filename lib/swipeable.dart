library swipeable;

import 'dart:math';

import 'package:flutter/material.dart';

class Swipeable extends StatefulWidget {
  const Swipeable({
    required this.child,
    required this.backgroundWidget,
    this.onSwipeStart,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onSwipeCancel,
    this.onSwipeEnd,
    this.threshold = 64.0,
  });

  final Widget child;
  final Widget backgroundWidget;
  final VoidCallback? onSwipeStart;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeCancel;
  final VoidCallback? onSwipeEnd;
  final double threshold;

  @override
  State<StatefulWidget> createState() => _SwipeableState();
}

class _SwipeableState extends State<Swipeable> with TickerProviderStateMixin {
  late AnimationController _moveController;
  late Animation<Offset> _moveAnimation;

  late double _backgroundWidgetOpacity;

  late double _dragExtent;

  bool get _swipingRight => _dragExtent > 0 && widget.onSwipeRight != null;
  bool get _swipingLeft => _dragExtent < 0 && widget.onSwipeLeft != null;

  @override
  void initState() {
    super.initState();
    _moveController = AnimationController(
        duration: const Duration(milliseconds: 200), vsync: this);
    _moveAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(1.0, 0.0))
            .animate(_moveController);

    _dragExtent = 0.0;
    _backgroundWidgetOpacity = 0.0;
    _moveController.animateTo(0.0);
  }

  @override
  void dispose() {
    _moveController.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    if (widget.onSwipeStart != null) {
      widget.onSwipeStart?.call();
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (context.size == null) return;
    final width = context.size!.width;
    if (width == 0) return;

    final delta = details.primaryDelta ?? 0;
    final oldDragExtent = _dragExtent;
    _dragExtent += delta;

    if (oldDragExtent.sign != _dragExtent.sign) {
      setState(_updateMoveAnimation);
    }

    final movePastThresholdPixels = widget.threshold;
    double newPos = _dragExtent.abs() / width;

    if (_dragExtent.abs() > movePastThresholdPixels) {
      // how many "thresholds" past the threshold we are. 1 = the threshold 2
      // = two thresholds.
      final n = _dragExtent.abs() / movePastThresholdPixels;

      // Take the number of thresholds past the threshold, and reduce this
      // number
      final reducedThreshold = pow(n, 0.3);

      final adjustedPixelPos = movePastThresholdPixels * reducedThreshold;
      newPos = adjustedPixelPos / width;
    }

    setState(() {
      _backgroundWidgetOpacity = min(_dragExtent.abs() / widget.threshold, 1);
    });
    _moveController.value = newPos;
  }

  void _handleDragEnd(DragEndDetails details) {
    setState(() {
      _backgroundWidgetOpacity = 0;
    });

    final movePastThresholdPixels = widget.threshold;

    if (_dragExtent.abs() > movePastThresholdPixels) {
      if (_swipingRight) {
        if (widget.onSwipeRight != null) {
          widget.onSwipeRight?.call();
        }
      } else if (_swipingLeft) {
        if (widget.onSwipeLeft != null) {
          widget.onSwipeLeft?.call();
        }
      }
    } else {
      if (widget.onSwipeCancel != null) {
        widget.onSwipeCancel?.call();
      }
    }

    _moveController.animateTo(0.0, duration: const Duration(milliseconds: 200));
    _dragExtent = 0.0;

    if (widget.onSwipeEnd != null) {
      widget.onSwipeEnd?.call();
    }
  }

  void _updateMoveAnimation() {
    final sign = _dragExtent.sign;
    final end = _swipingRight
        ? max(0.0, sign)
        : _swipingLeft
            ? min(0.0, sign)
            : 0.0;

    _moveAnimation = Tween<Offset>(begin: Offset.zero, end: Offset(end, 0.0))
        .animate(_moveController);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: _swipingRight ? Alignment.centerLeft : Alignment.centerRight,
        children: [
          if (_swipingRight || _swipingLeft)
            AnimatedOpacity(
                opacity: _backgroundWidgetOpacity,
                duration: const Duration(milliseconds: 200),
                child: widget.backgroundWidget),
          SlideTransition(
            position: _moveAnimation,
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
