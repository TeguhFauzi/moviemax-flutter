import 'dart:math';
import 'package:flutter/material.dart';
import '../providers/settings_provider.dart';

class GalaxyParticle {
  double angle;
  double radiusFactor;
  double speed;
  double size;
  double opacity;
  double z;
  Color color;
  double orbitXScale;
  double orbitYScale;
  double tiltAngle;

  GalaxyParticle({
    required this.angle,
    required this.radiusFactor,
    required this.speed,
    required this.size,
    required this.opacity,
    required this.z,
    required this.color,
    required this.orbitXScale,
    required this.orbitYScale,
    required this.tiltAngle,
  });
}

class GravityBackgroundWidget extends StatefulWidget {
  final Widget child;
  final SettingsProvider settings;
  final int tabIndex;

  const GravityBackgroundWidget({
    Key? key,
    required this.child,
    required this.settings,
    this.tabIndex = 0,
  }) : super(key: key);

  @override
  State<GravityBackgroundWidget> createState() => _GravityBackgroundWidgetState();
}

class _GravityBackgroundWidgetState extends State<GravityBackgroundWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _tabTransitionController;
  late Animation<double> _rotationAnimation;
  final List<GalaxyParticle> _particles = [];
  final Random _random = Random();
  static const int _particleCount = 90;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();

    _tabTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: pi * 2).animate(
      CurvedAnimation(parent: _tabTransitionController, curve: Curves.easeOutCubic),
    );

    _controller.addListener(_updateParticles);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_particles.isEmpty) {
      _initParticles();
    }
  }

  @override
  void didUpdateWidget(GravityBackgroundWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings.isDarkMode != widget.settings.isDarkMode) {
      _initParticles();
    }
    if (oldWidget.tabIndex != widget.tabIndex) {
      _triggerTabEffect();
    }
  }

  void _triggerTabEffect() {
    _tabTransitionController.forward(from: 0.0);
    for (var p in _particles) {
      p.angle += (_random.nextDouble() * 0.4 + 0.3) * (_random.nextBool() ? 1 : -1);
    }
  }

  void _initParticles() {
    _particles.clear();
    final isDark = widget.settings.isDarkMode;

    // Professional creative color palette - Multi-spectral Aurora Fintech theme
    final List<Color> darkColors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF10B981), // Emerald
      const Color(0xFFEC4899), // Pink
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFF59E0B), // Amber Gold
    ];

    final List<Color> lightColors = [
      const Color(0xFF4F46E5), // Royal Indigo
      const Color(0xFF0284C7), // Sky Blue
      const Color(0xFF059669), // Emerald
      const Color(0xFFDB2777), // Rose Magenta
      const Color(0xFF7C3AED), // Purple Amethyst
      const Color(0xFFD97706), // Warm Amber
    ];

    final colors = isDark ? darkColors : lightColors;

    for (int i = 0; i < _particleCount; i++) {
      final double distFactor = _random.nextDouble();
      final double radFactor = (pow(distFactor, 1.3) * 0.9 + 0.1).toDouble();

      _particles.add(
        GalaxyParticle(
          angle: _random.nextDouble() * pi * 2,
          radiusFactor: radFactor,
          speed: (0.002 + (1.0 / (radFactor * 12 + 1)) * 0.003),
          size: _random.nextDouble() * 5.5 + 2.5,
          opacity: _random.nextDouble() * 0.7 + 0.3,
          z: _random.nextDouble(),
          color: colors[_random.nextInt(colors.length)],
          orbitXScale: 1.25 + (_random.nextDouble() - 0.5) * 0.5,
          orbitYScale: 0.65 + (_random.nextDouble() - 0.5) * 0.3,
          tiltAngle: _random.nextDouble() * pi / 2.2 - pi / 4.4,
        ),
      );
    }
  }

  void _updateParticles() {
    if (!mounted) return;
    setState(() {
      for (var p in _particles) {
        p.angle += p.speed;
        if (p.angle > pi * 2) {
          p.angle -= pi * 2;
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabTransitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _tabTransitionController]),
      builder: (context, child) {
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: GalaxyPainter(
                  particles: _particles,
                  isDarkMode: widget.settings.isDarkMode,
                  backgroundColor: widget.settings.backgroundColor,
                  primaryColor: widget.settings.primaryColor,
                  time: _controller.value,
                  extraRotation: _rotationAnimation.value,
                  burstValue: sin(_tabTransitionController.value * pi),
                ),
              ),
            ),
            widget.child,
          ],
        );
      },
    );
  }
}

class GalaxyPainter extends CustomPainter {
  final List<GalaxyParticle> particles;
  final bool isDarkMode;
  final Color backgroundColor;
  final Color primaryColor;
  final double time;
  final double extraRotation;
  final double burstValue;

  GalaxyPainter({
    required this.particles,
    required this.isDarkMode,
    required this.backgroundColor,
    required this.primaryColor,
    required this.time,
    this.extraRotation = 0.0,
    this.burstValue = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.42);
    final maxRadius = max(size.width, size.height) * 0.65;
    final rect = Offset.zero & size;

    // Rich Creative Gradient Background
    final bgPaint = Paint();
    if (isDarkMode) {
      bgPaint.shader = RadialGradient(
        center: const Alignment(0, -0.2),
        radius: 1.6,
        colors: [
          const Color(0xFF1E1B4B), // Deep Indigo
          const Color(0xFF0F172A), // Dark Slate
          const Color(0xFF030712), // Cosmic Black
        ],
      ).createShader(rect);
    } else {
      bgPaint.shader = RadialGradient(
        center: const Alignment(0, -0.2),
        radius: 1.6,
        colors: [
          const Color(0xFFF0F3FF), // Soft Crystal Blue
          const Color(0xFFF8FAFC), // Slate White
          const Color(0xFFE0E7FF), // Subtle Periwinkle
        ],
      ).createShader(rect);
    }
    canvas.drawRect(rect, bgPaint);

    // Multi-spectral Creative Core Aurora Glow
    final pulseScale = 1.0 + sin(time * pi * 2) * 0.12 + (burstValue * 0.35);
    final coreGlowRadius = maxRadius * 0.8 * pulseScale;

    final auroraColorsDark = [
      const Color(0xFF06B6D4).withValues(alpha: 0.35), // Cyan
      const Color(0xFF8B5CF6).withValues(alpha: 0.25), // Violet
      const Color(0xFFEC4899).withValues(alpha: 0.15), // Pink
      Colors.transparent,
    ];

    final auroraColorsLight = [
      const Color(0xFF3B82F6).withValues(alpha: 0.22), // Blue
      const Color(0xFF8B5CF6).withValues(alpha: 0.16), // Violet
      const Color(0xFF06B6D4).withValues(alpha: 0.10), // Cyan
      Colors.transparent,
    ];

    final coreGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: isDarkMode ? auroraColorsDark : auroraColorsLight,
        stops: const [0.0, 0.4, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: coreGlowRadius));

    canvas.drawCircle(center, coreGlowRadius, coreGlowPaint);

    // Vibrant Multi-color Atomic Orbital Rings
    final ringColors = isDarkMode
        ? [
            const Color(0xFF06B6D4), // Cyan ring
            const Color(0xFF8B5CF6), // Purple ring
            const Color(0xFFEC4899), // Pink ring
            const Color(0xFF10B981), // Emerald ring
          ]
        : [
            const Color(0xFF2563EB), // Sapphire ring
            const Color(0xFF7C3AED), // Amethyst ring
            const Color(0xFFDB2777), // Rose ring
            const Color(0xFF059669), // Emerald ring
          ];

    for (int r = 0; r < ringColors.length; r++) {
      final ringRadiusX = maxRadius * (0.35 + (r * 0.22)) * (1.0 + burstValue * 0.15);
      final ringRadiusY = ringRadiusX * 0.48;
      final dir = (r % 2 == 0 ? 1 : -1);
      final ringAngle = (r * pi / 3) + (time * pi * 0.15 * dir) + (extraRotation * dir * (1.0 + r * 0.2));

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(ringAngle);

      final orbitRingPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = ringColors[r].withValues(alpha: isDarkMode ? 0.28 : 0.22);

      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: ringRadiusX * 2, height: ringRadiusY * 2),
        orbitRingPaint,
      );

      canvas.restore();
    }

    // Creative Particle Connections & Glowing Nodes
    final linePaint = Paint()..strokeWidth = 1.1;
    final sorted = List<GalaxyParticle>.from(particles);

    for (int i = 0; i < sorted.length; i++) {
      final p1 = sorted[i];
      final currentAngle = p1.angle + extraRotation;
      final actualRadius = p1.radiusFactor * maxRadius * (1.0 + burstValue * 0.2);
      final rawX = cos(currentAngle) * actualRadius * p1.orbitXScale;
      final rawY = sin(currentAngle) * actualRadius * p1.orbitYScale;

      final rotatedX = rawX * cos(p1.tiltAngle) - rawY * sin(p1.tiltAngle);
      final rotatedY = rawX * sin(p1.tiltAngle) + rawY * cos(p1.tiltAngle);

      final pos1 = Offset(center.dx + rotatedX, center.dy + rotatedY);

      // Connect near particles with multi-color filament lines
      for (int j = i + 1; j < sorted.length; j++) {
        final p2 = sorted[j];
        final actualRadius2 = p2.radiusFactor * maxRadius;
        final rawX2 = cos(p2.angle) * actualRadius2 * p2.orbitXScale;
        final rawY2 = sin(p2.angle) * actualRadius2 * p2.orbitYScale;
        final rotatedX2 = rawX2 * cos(p2.tiltAngle) - rawY2 * sin(p2.tiltAngle);
        final rotatedY2 = rawX2 * sin(p2.tiltAngle) + rawY2 * cos(p2.tiltAngle);

        final pos2 = Offset(center.dx + rotatedX2, center.dy + rotatedY2);
        final dist = (pos1 - pos2).distance;

        if (dist < 135) {
          final threadAlpha = (1.0 - (dist / 135)) * (isDarkMode ? 0.40 : 0.30) * p1.opacity;
          linePaint.color = p1.color.withValues(alpha: threadAlpha);
          canvas.drawLine(pos1, pos2, linePaint);
        }
      }

      // Draw Particle Node with Outer Aura Glow
      final particlePaint = Paint()
        ..color = p1.color.withValues(alpha: p1.opacity)
        ..style = PaintingStyle.fill;

      // Glow effect
      final glowPaint = Paint()
        ..color = p1.color.withValues(alpha: p1.opacity * (isDarkMode ? 0.60 : 0.40))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
      canvas.drawCircle(pos1, p1.size * 2.2, glowPaint);

      // Main Particle Body
      canvas.drawCircle(pos1, p1.size, particlePaint);

      // Bright Core Center
      final coreHighlight = Paint()..color = Colors.white.withValues(alpha: p1.opacity * 0.9);
      canvas.drawCircle(pos1, p1.size * 0.38, coreHighlight);
    }
  }

  @override
  bool shouldRepaint(covariant GalaxyPainter oldDelegate) => true;
}
