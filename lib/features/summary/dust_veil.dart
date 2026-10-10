import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Telegram-style « spoiler » dust: when [covered] turns true, [child]
/// dissolves into twinkling dust; when it turns false, the dust scatters from
/// the centre and reveals the (new) child.
///
/// The Summary screen wraps the Reddit page, then the summary, in one veil so
/// the thread visibly turns into its summary. With reduced motion the dust
/// stays still and the reveal is instant.
class DustVeil extends StatefulWidget {
  const DustVeil({super.key, required this.covered, required this.child});

  final bool covered;
  final Widget child;

  @override
  State<DustVeil> createState() => _DustVeilState();
}

class _DustVeilState extends State<DustVeil> with TickerProviderStateMixin {
  late final AnimationController _cover =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final AnimationController _reveal =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  final _time = ValueNotifier<double>(0);
  late final Ticker _ticker = createTicker((elapsed) {
    _time.value = elapsed.inMicroseconds / 1e6;
  });
  _Dust? _dust;

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    _reveal.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _cover.value = 0;
        _reveal.value = 0;
        _ticker.stop();
        setState(() {});
      }
    });
    if (widget.covered) WidgetsBinding.instance.addPostFrameCallback((_) => _coverUp());
  }

  @override
  void didUpdateWidget(DustVeil old) {
    super.didUpdateWidget(old);
    if (widget.covered && !old.covered) _coverUp();
    if (!widget.covered && old.covered) _clear();
  }

  void _coverUp() {
    if (!mounted) return;
    _reveal.value = 0;
    if (_reduceMotion) {
      _cover.value = 1;
    } else {
      if (!_ticker.isActive) _ticker.start();
      _cover.forward(from: _cover.value);
    }
    setState(() {});
  }

  void _clear() {
    if (_reduceMotion || _cover.value == 0) {
      _cover.value = 0;
      _ticker.stop();
      return;
    }
    if (!_ticker.isActive) _ticker.start();
    _reveal.forward(from: 0);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _cover.dispose();
    _reveal.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = widget.covered || _cover.value > 0 || _reveal.isAnimating;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (active)
          IgnorePointer(
            child: LayoutBuilder(builder: (context, constraints) {
              final size = constraints.biggest;
              final dust = _dust = _dust != null && _dust!.size == size ? _dust : _Dust(size);
              return CustomPaint(
                size: size,
                painter: _DustPainter(
                  dust: dust!,
                  time: _time,
                  cover: _cover,
                  reveal: _reveal,
                  veil: scheme.surface,
                  grain: scheme.onSurface,
                ),
              );
            }),
          ),
      ],
    );
  }
}

/// Particle field for one size, in flat arrays so a frame stays cheap.
class _Dust {
  _Dust(this.size) : count = math.min(6000, (size.width * size.height / 40).round()) {
    final random = math.Random(7);
    x = Float32List(count);
    y = Float32List(count);
    vx = Float32List(count);
    vy = Float32List(count);
    phase = Float32List(count);
    speed = Float32List(count);
    threshold = Float32List(count);
    for (var i = 0; i < count; i++) {
      x[i] = random.nextDouble() * size.width;
      y[i] = random.nextDouble() * size.height;
      final angle = random.nextDouble() * math.pi * 2;
      final drift = 4 + random.nextDouble() * 14;
      vx[i] = math.cos(angle) * drift;
      vy[i] = math.sin(angle) * drift;
      phase[i] = random.nextDouble() * math.pi * 2;
      speed[i] = 2 + random.nextDouble() * 5;
      threshold[i] = random.nextDouble();
    }
  }

  final Size size;
  final int count;
  late final Float32List x, y, vx, vy, phase, speed, threshold;
}

class _DustPainter extends CustomPainter {
  _DustPainter({
    required this.dust,
    required this.time,
    required this.cover,
    required this.reveal,
    required this.veil,
    required this.grain,
  }) : super(repaint: Listenable.merge([time, cover, reveal]));

  final _Dust dust;
  final ValueNotifier<double> time;
  final Animation<double> cover;
  final Animation<double> reveal;
  final Color veil;
  final Color grain;

  static const _buckets = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Curves.easeOut.transform(cover.value);
    final r = Curves.easeIn.transform(reveal.value);
    final t = time.value;
    final w = size.width, h = size.height;

    // The page fades under the dust, then the dust lifts off the summary.
    final veilAlpha = Curves.easeInOut.transform(c) * (1 - Curves.easeOut.transform(reveal.value));
    canvas.drawRect(Offset.zero & size, Paint()..color = veil.withValues(alpha: veilAlpha));

    final points = List.generate(_buckets, (_) => Float32List(dust.count * 2));
    final counts = List.filled(_buckets, 0);
    final cx = w / 2, cy = h / 2;
    final scatter = r * r * (w + h) * 0.6;
    for (var i = 0; i < dust.count; i++) {
      // Grains appear in random order while the page dissolves.
      final appear = ((c - dust.threshold[i] * 0.7) / 0.3).clamp(0.0, 1.0);
      final twinkle = 0.55 + 0.45 * math.sin(t * dust.speed[i] + dust.phase[i]);
      final alpha = appear * twinkle * (1 - r);
      if (alpha < 0.05) continue;
      var px = (dust.x[i] + dust.vx[i] * t) % w;
      var py = (dust.y[i] + dust.vy[i] * t) % h;
      if (scatter > 0) {
        final dx = px - cx, dy = py - cy;
        final d = math.max(1.0, math.sqrt(dx * dx + dy * dy));
        final push = scatter * (0.5 + dust.threshold[i]);
        px += dx / d * push;
        py += dy / d * push;
      }
      final b = math.min(_buckets - 1, (alpha * _buckets).floor());
      points[b][counts[b] * 2] = px;
      points[b][counts[b] * 2 + 1] = py;
      counts[b]++;
    }
    final paint = Paint()
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var b = 0; b < _buckets; b++) {
      if (counts[b] == 0) continue;
      paint.color = grain.withValues(alpha: (b + 1) / _buckets * 0.85);
      canvas.drawRawPoints(
          PointMode.points, Float32List.sublistView(points[b], 0, counts[b] * 2), paint);
    }
  }

  @override
  bool shouldRepaint(_DustPainter old) =>
      old.dust != dust || old.veil != veil || old.grain != grain;
}
