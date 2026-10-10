import 'dart:async';

import 'package:flutter/material.dart';

/// A premium, native music-player marquee title widget (matching Spotify & Apple Music standards).
///
/// - Automatically inherits the ambient typography ([DefaultTextStyle], font family, scaling).
/// - If [text] fits within the container width, it stays stationary.
/// - If [text] exceeds the width:
///   1. Pauses at the start for [pauseDuration] so the user can comfortably read the beginning.
///   2. Smoothly scrolls leftwards with a gentle curve, bringing trailing words into full view.
///      An extra scroll buffer guarantees that the final word (e.g. "Sahib") is 100% visible
///      and never cut off or clipped.
///   3. Pauses at the end for [pauseDuration] so the user can comfortably read the trailing words.
///   4. Smoothly glides back to the start and repeats.
/// - Includes a delicate, subtle edge blur fade animation on the outer boundaries (Spotify practice).
class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final double velocity; // pixels per second
  final Duration pauseDuration;

  const MarqueeText({
    super.key,
    required this.text,
    required this.style,
    this.textAlign = TextAlign.center,
    this.velocity = 24.0, // Natural, legible reading pace
    this.pauseDuration = const Duration(milliseconds: 2000),
  });

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  double _textWidth = 0.0;
  double _containerWidth = 0.0;
  bool _isOverflowing = false;
  Timer? _pauseTimer;

  static const double _trailingBuffer =
      40.0; // Extra room ensuring trailing word is 100% visible

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Reached the end: pause so user can comfortably read the trailing words
        _pauseTimer?.cancel();
        _pauseTimer = Timer(widget.pauseDuration, () {
          if (mounted && _isOverflowing) {
            _controller.reverse();
          }
        });
      } else if (status == AnimationStatus.dismissed) {
        // Returned to start: pause so user can read the beginning
        _pauseTimer?.cancel();
        _pauseTimer = Timer(widget.pauseDuration, () {
          if (mounted && _isOverflowing) {
            _controller.forward();
          }
        });
      }
    });
  }

  @override
  void didUpdateWidget(MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.style != widget.style ||
        oldWidget.velocity != widget.velocity) {
      _pauseTimer?.cancel();
      _controller.reset();
      _isOverflowing = false;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _calculateAndAnimate(),
      );
    }
  }

  @override
  void dispose() {
    _pauseTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _calculateAndAnimate() {
    if (!mounted || _containerWidth <= 0) return;

    // Inherit the exact ambient text style and font family from the theme
    final defaultStyle = DefaultTextStyle.of(context).style;
    final effectiveStyle = defaultStyle.merge(widget.style);

    final textScaler =
        MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling;
    final textPainter = TextPainter(
      text: TextSpan(text: widget.text, style: effectiveStyle),
      maxLines: 1,
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      textScaler: textScaler,
    )..layout();

    // Actual rendered text width plus safety buffer
    final textWidth = textPainter.width + 16.0;
    final isOverflowing = (textPainter.width + 4.0) > _containerWidth;

    if (isOverflowing != _isOverflowing ||
        (textWidth - _textWidth).abs() > 1.0) {
      _textWidth = textWidth;
      _isOverflowing = isOverflowing;

      if (_isOverflowing) {
        final overflowDistance =
            (_textWidth - _containerWidth + _trailingBuffer).clamp(
              10.0,
              2000.0,
            );
        final durationMs = ((overflowDistance / widget.velocity) * 1000)
            .toInt()
            .clamp(800, 30000);
        _controller.duration = Duration(milliseconds: durationMs);
        _controller.reset();
        _pauseTimer?.cancel();
        // Initial pause at start before first forward scroll
        _pauseTimer = Timer(widget.pauseDuration, () {
          if (mounted && _isOverflowing) {
            _controller.forward();
          }
        });
      } else {
        _pauseTimer?.cancel();
        _controller.stop();
        _controller.reset();
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width != _containerWidth && width > 0) {
          _containerWidth = width;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _calculateAndAnimate(),
          );
        }

        if (!_isOverflowing) {
          return SizedBox(
            width: double.infinity,
            child: Text(
              widget.text,
              style: widget.style,
              textAlign: widget.textAlign,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
            ),
          );
        }

        final maxScroll = (_textWidth - _containerWidth + _trailingBuffer)
            .clamp(0.0, double.infinity);

        return ClipRect(
          // Subtle, delicate edge fade (Spotify style - not too much, just a soft 12px feather)
          child: ShaderMask(
            shaderCallback: (bounds) {
              final fadePercent = (12.0 / bounds.width).clamp(0.015, 0.06);
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: const [
                  Colors.transparent,
                  Colors.white,
                  Colors.white,
                  Colors.transparent,
                ],
                stops: [0.0, fadePercent, 1.0 - fadePercent, 1.0],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final offset = _animation.value * maxScroll;
                return Transform.translate(
                  offset: Offset(-offset, 0),
                  child: child,
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(right: _trailingBuffer),
                child: Text(
                  widget.text,
                  style: widget.style,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
