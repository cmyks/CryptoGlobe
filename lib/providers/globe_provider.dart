import 'package:flutter/material.dart';
import 'dart:math' as math;

class GlobeProvider extends ChangeNotifier {
  double _rotationX = 0.0;
  double _rotationY = 0.0;
  double _zoom = 1.0;
  bool _isRotating = true;
  String? _selectedCountry;
  List<MapMarker> _markers = [];
  
  double get rotationX => _rotationX;
  double get rotationY => _rotationY;
  double get zoom => _zoom;
  bool get isRotating => _isRotating;
  String? get selectedCountry => _selectedCountry;
  List<MapMarker> get markers => _markers;

  void updateRotation(double dx, double dy) {
    _rotationX += dx * 0.01;
    _rotationY = (_rotationY + dy * 0.01).clamp(-math.pi / 2, math.pi / 2);
    notifyListeners();
  }

  void autoRotate() {
    if (_isRotating) {
      _rotationX += 0.002;
      notifyListeners();
    }
  }

  void toggleRotation() {
    _isRotating = !_isRotating;
    notifyListeners();
  }

  void updateZoom(double delta) {
    _zoom = (_zoom + delta).clamp(0.5, 3.0);
    notifyListeners();
  }

  void selectCountry(String? country) {
    _selectedCountry = country;
    notifyListeners();
  }

  void addMarker(MapMarker marker) {
    _markers.add(marker);
    notifyListeners();
  }

  void clearMarkers() {
    _markers.clear();
    notifyListeners();
  }

  void resetView() {
    _rotationX = 0.0;
    _rotationY = 0.0;
    _zoom = 1.0;
    _isRotating = true;
    notifyListeners();
  }
}

class MapMarker {
  final double latitude;
  final double longitude;
  final String label;
  final Color color;
  final IconData icon;

  MapMarker({
    required this.latitude,
    required this.longitude,
    required this.label,
    this.color = Colors.blue,
    this.icon = Icons.place,
  });
}