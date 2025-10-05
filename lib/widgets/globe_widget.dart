import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/globe_provider.dart';
import '../providers/crypto_provider.dart';

// 1. Placeholder for the Crypto Data structure for type safety
class CryptoData {
  final String symbol;
  final double change24h;
  final double price;

  CryptoData({required this.symbol, required this.change24h, required this.price});

  // Example factory constructor for testing/dummy data
  factory CryptoData.fromDynamic(dynamic data) {
    // Assuming the dynamic object has these properties
    return CryptoData(
      symbol: data.symbol as String? ?? '???',
      change24h: data.change24h as double? ?? 0.0,
      price: data.price as double? ?? 0.0,
    );
  }
}

// NOTE: Since I don't have access to the actual GlobeProvider and CryptoProvider 
// implementations, I will assume that CryptoProvider.cryptos provides objects 
// that can be converted to CryptoData or are already of that type.
// For the purpose of making the CustomPainter type-safe, I will cast the list 
// from the provider (which is List<dynamic> in the original code) into 
// List<CryptoData> in the build method.
// I will also assume GlobeProvider and CryptoProvider are implemented correctly.

class GlobeWidget extends StatefulWidget {
  const GlobeWidget({super.key});

  @override
  State<GlobeWidget> createState() => _GlobeWidgetState();
}

class _GlobeWidgetState extends State<GlobeWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Offset? _lastPosition;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<GlobeProvider, CryptoProvider>(
      builder: (context, globeProvider, cryptoProvider, child) {
        // Correcting the type of topCryptos passed to the painter
        // Note: This still relies on the dynamic objects in cryptoProvider.cryptos
        // having the correct structure to be implicitly used by the painter.
        // For actual runtime safety, you'd map/convert them to CryptoData.
        final List<CryptoData> topCryptos = cryptoProvider.cryptos
            .take(10)
            .map((e) => e as CryptoData) // Assuming 'e' is already or can be cast to CryptoData
            .toList();
            
        return GestureDetector(
          onPanStart: (details) {
            _lastPosition = details.localPosition;
            globeProvider.toggleRotation();
          },
          onPanUpdate: (details) {
            if (_lastPosition != null) {
              final delta = details.localPosition - _lastPosition!;
              globeProvider.updateRotation(delta.dx, delta.dy);
              _lastPosition = details.localPosition;
            }
          },
          onPanEnd: (_) {
            _lastPosition = null;
          },
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C5CE7).withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: -10,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CustomPaint(
                painter: Globe3DPainter(
                  rotationX: globeProvider.rotationX,
                  rotationY: globeProvider.rotationY,
                  zoom: globeProvider.zoom,
                  markers: globeProvider.markers,
                  animationValue: _animController.value,
                  topCryptos: topCryptos, // Use the now-typed list
                ),
                child: Container(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class Globe3DPainter extends CustomPainter {
  final double rotationX;
  final double rotationY;
  final double zoom;
  final List<dynamic> markers;
  final double animationValue;
  // 2. Change type from List<dynamic> to List<CryptoData>
  final List<CryptoData> topCryptos; 

  Globe3DPainter({
    required this.rotationX,
    required this.rotationY,
    required this.zoom,
    required this.markers,
    required this.animationValue,
    required this.topCryptos,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 * 0.8 * zoom;

    // Draw space background
    _drawSpaceBackground(canvas, size);

    // Draw globe sphere
    _drawGlobeSphere(canvas, center, radius);

    // Draw grid lines (latitude/longitude)
    _drawGridLines(canvas, center, radius);

    // Draw continents outline
    _drawContinents(canvas, center, radius);

    // Draw crypto markers
    _drawCryptoMarkers(canvas, center, radius);

    // Draw glow effect
    _drawGlowEffect(canvas, center, radius);

    // Draw info text
    _drawInfoOverlay(canvas, size);
  }

  void _drawSpaceBackground(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF1A1F3A),
          const Color(0xFF0A0E27),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw stars
    final starPaint = Paint()..color = Colors.white;
    for (int i = 0; i < 200; i++) {
      final x = (i * 37.5) % size.width;
      final y = (i * 73.2) % size.height;
      final opacity = ((i % 10) / 10) * 0.6 + 0.4;
      starPaint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), (i % 3) * 0.3 + 0.5, starPaint);
    }
  }

  void _drawGlobeSphere(Canvas canvas, Offset center, double radius) {
    // Base sphere
    final spherePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF2D3561),
          const Color(0xFF1A1F3A),
          const Color(0xFF0F1429),
        ],
        stops: const [0.3, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    
    canvas.drawCircle(center, radius, spherePaint);

    // Atmosphere glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF6C5CE7).withOpacity(0.0),
          const Color(0xFF6C5CE7).withOpacity(0.3),
          const Color(0xFF9B8CEE).withOpacity(0.1),
        ],
        stops: const [0.7, 0.85, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.1));
    
    canvas.drawCircle(center, radius * 1.1, glowPaint);
  }

  void _drawGridLines(Canvas canvas, Offset center, double radius) {
    final gridPaint = Paint()
      ..color = const Color(0xFF6C5CE7).withOpacity(0.2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Latitude lines (parallel to the equator)
    // These circles appear as ellipses in 3D projection (simplified).
    for (int lat = -80; lat <= 80; lat += 20) {
      final latRad = lat * math.pi / 180;
      final y = center.dy - radius * math.sin(latRad); // Note: Flutter y-axis is inverted
      final r = radius * math.cos(latRad);
      
      if (r > 0) {
        // Simplified: just draw a flattened circle/ellipse for latitude
        // This is not strictly correct 3D projection but common for globe visuals.
        canvas.drawOval(
          Rect.fromCenter(center: Offset(center.dx, y), width: r * 2, height: r * 2 * 0.3),
          gridPaint,
        );
      }
    }

    // Longitude lines (meridians)
    for (int lon = 0; lon < 360; lon += 30) {
      final path = Path();
      bool started = false;
      
      for (double lat = -90; lat <= 90; lat += 5) {
        // rotationX is applied to the longitude for a simple globe spin effect
        final point = _project3DPoint(lat, lon + rotationX * 180 / math.pi, center, radius); 
        if (point != null) {
          if (!started) {
            path.moveTo(point.dx, point.dy);
            started = true;
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
      }
      canvas.drawPath(path, gridPaint);
    }
  }

  void _drawContinents(Canvas canvas, Offset center, double radius) {
    final continentPaint = Paint()
      ..color = const Color(0xFF00B894).withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Simplified continent data points (latitude, longitude pairs)
    final continents = [
      // North America
      [40.0, -100.0, 50.0, -100.0, 60.0, -110.0, 50.0, -120.0, 40.0, -110.0],
      // South America
      [0.0, -60.0, -10.0, -70.0, -20.0, -70.0, -30.0, -60.0, -20.0, -50.0, 0.0, -50.0],
      // Europe
      [50.0, 10.0, 60.0, 20.0, 60.0, 30.0, 50.0, 30.0, 45.0, 20.0, 50.0, 10.0],
      // Africa
      [10.0, 20.0, 0.0, 30.0, -10.0, 30.0, -20.0, 25.0, -30.0, 20.0, -20.0, 10.0, 0.0, 10.0, 10.0, 20.0],
      // Asia
      [30.0, 80.0, 40.0, 100.0, 50.0, 120.0, 40.0, 130.0, 30.0, 120.0, 20.0, 100.0, 30.0, 80.0],
      // Australia
      [-20.0, 130.0, -30.0, 140.0, -35.0, 145.0, -30.0, 150.0, -20.0, 145.0, -20.0, 130.0],
    ];

    for (final continent in continents) {
      final path = Path();
      bool started = false;
      
      for (int i = 0; i < continent.length - 1; i += 2) {
        final lat = continent[i];
        final lon = continent[i + 1];
        // rotationX is applied to the longitude for a simple globe spin effect
        final point = _project3DPoint(lat, lon + rotationX * 180 / math.pi, center, radius);
        
        if (point != null) {
          if (!started) {
            path.moveTo(point.dx, point.dy);
            started = true;
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
      }
      
      if (started) {
        path.close();
        canvas.drawPath(path, continentPaint);
      }
    }
  }

  void _drawCryptoMarkers(Canvas canvas, Offset center, double radius) {
    if (topCryptos.isEmpty) return;

    // Distribute top cryptos around the globe
    for (int i = 0; i < topCryptos.length; i++) {
      final crypto = topCryptos[i];
      final angle = (i / 10) * 2 * math.pi;
      final lat = math.sin(angle) * 40;
      final lon = (math.cos(angle) * 180).abs(); // Simplified distribution

      final point = _project3DPoint(
        lat,
        lon + rotationX * 180 / math.pi,
        center,
        radius,
      );

      // _isVisiblePoint is called with the *untransformed* latitude and the *transformed* longitude
      if (point != null && _isVisiblePoint(lat, lon + rotationX * 180 / math.pi)) {
        // Animated pulse effect
        final pulseSize = 8 + math.sin(animationValue * 2 * math.pi + i) * 3;
        
        // Outer glow
        final glowPaint = Paint()
          ..color = (crypto.change24h >= 0)
              ? const Color(0xFF00B894).withOpacity(0.3)
              : const Color(0xFFFF6B6B).withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        
        canvas.drawCircle(point, pulseSize + 4, glowPaint);

        // Main marker
        final markerPaint = Paint()
          ..color = (crypto.change24h >= 0) ? const Color(0xFF00B894) : const Color(0xFFFF6B6B)
          ..style = PaintingStyle.fill;
        
        canvas.drawCircle(point, pulseSize, markerPaint);

        // Border
        final borderPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        
        canvas.drawCircle(point, pulseSize, borderPaint);

        // Symbol text
        final textSpan = TextSpan(
          text: crypto.symbol,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        );
        
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(point.dx - textPainter.width / 2, point.dy + pulseSize + 6),
        );
      }
    }
  }

  void _drawGlowEffect(Canvas canvas, Offset center, double radius) {
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF6C5CE7).withOpacity(0.1),
          const Color(0xFF6C5CE7).withOpacity(0.3),
        ],
        stops: const [0.5, 0.8, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.2));
    
    canvas.drawCircle(center, radius * 1.2, glowPaint);
  }

  void _drawInfoOverlay(Canvas canvas, Size size) {
    final textSpan = TextSpan(
      text: 'Live Cryptocurrency Tracking',
      style: TextStyle(
        color: Colors.white.withOpacity(0.5),
        fontSize: 12,
        fontWeight: FontWeight.w300,
      ),
    );
    
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.width / 2 - textPainter.width / 2, size.height - 30),
    );
  }

  Offset? _project3DPoint(double lat, double lon, Offset center, double radius) {
    final latRad = lat * math.pi / 180;
    final lonRad = lon * math.pi / 180; // Lon now includes rotationX shift

    // Spherical to Cartesian coordinates (x, y, z)
    final cosLat = math.cos(latRad);
    final sinLat = math.sin(latRad);
    final cosLon = math.cos(lonRad);
    final sinLon = math.sin(lonRad);

    // Initial 3D coordinates on the sphere
    final x = radius * cosLat * sinLon;
    final y = radius * sinLat;
    final z = radius * cosLat * cosLon;

    // Apply PITCH (X-axis rotation) based on rotationY input (which controls up/down tilt)
    final cosRotY = math.cos(-rotationY); // Use negative rotationY for pitch
    final sinRotY = math.sin(-rotationY);
    
    // Rotation about the X-axis (Pitch)
    final y2 = y * cosRotY - z * sinRotY;
    final z2 = y * sinRotY + z * cosRotY;
    
    final x2 = x; // X is unchanged by X-axis rotation

    // Check if point is visible (front of sphere)
    // The z-coordinate must be positive after all transformations
    if (z2 > 0) {
      // Project the (x2, y2) onto the 2D plane
      // Note: Flutter's y-axis is inverted, so y2 is subtracted.
      return Offset(center.dx + x2, center.dy - y2);
    }
    
    return null;
  }

  bool _isVisiblePoint(double lat, double lon) {
    final latRad = lat * math.pi / 180;
    final lonRad = lon * math.pi / 180;
    
    // Initial 3D coordinates on the sphere (we only need Z)
    final cosLat = math.cos(latRad);
    final sinLat = math.sin(latRad);
    final z = math.cos(lonRad) * cosLat;
    final y = sinLat;
    
    // Apply PITCH (X-axis rotation) based on rotationY input
    final cosRotY = math.cos(-rotationY); // Use negative rotationY for pitch
    final sinRotY = math.sin(-rotationY);
    
    // Only need the transformed Z-coordinate (z2) for visibility check
    final z2 = y * sinRotY + z * cosRotY;
    
    return z2 > 0;
  }

  @override
  bool shouldRepaint(Globe3DPainter oldDelegate) {
    return oldDelegate.rotationX != rotationX ||
        oldDelegate.rotationY != rotationY ||
        oldDelegate.zoom != zoom ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.topCryptos != topCryptos;
  }
}