
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationNotifier extends ChangeNotifier {
  LatLng _currentLocation = LatLng(0, 0);
  LatLng? _currentTargetLocation;
  bool _showLineAndTargetMarker = false;
  bool _locationSubmitted = false;
  double? _distance;
  LatLngBounds? _mapBounds;
  double _zoomLevel = 10.0; // Default zoom level
  LatLng _mapCenter = LatLng(0, 0); // Default map 
  int _points = 0;

  LatLng get currentLocation => _currentLocation;
  LatLng? get currentTargetLocation => _currentTargetLocation;
  bool get showLineAndTargetMarker => _showLineAndTargetMarker;
  bool get locationSubmitted => _locationSubmitted;
  LatLngBounds? get mapBounds => _mapBounds;
  double get zoomLevel => _zoomLevel;
  double? get distance => _distance;
  LatLng get mapCenter => _mapCenter;
  int get points => _points;

  void setCurrentLocation(LatLng location) {
    _currentLocation = location;
    notifyListeners();
  }
    void resetCurrentLocation() {
   _currentLocation = LatLng(0, 0);
    notifyListeners();
      print("location submitted$_locationSubmitted");
  }

    void setPoints(int points) {
    _points = points;
    notifyListeners();
  }
     void setDistance(double distance) {
    _distance = distance;
    notifyListeners();
  }



  

  void setCurrentTargetLocation(LatLng? location) {
    _currentTargetLocation = location;
    notifyListeners();
  }

  void setShowLineAndTargetMarker(bool value) {
    _showLineAndTargetMarker = value;
    notifyListeners();
  }

  void setLocationSubmitted(bool value) {
    _locationSubmitted = value;
    notifyListeners();
    print("location submitted$_locationSubmitted");
  }

   void resetMapState() {
    _currentLocation = LatLng(0, 0);
    _showLineAndTargetMarker = false;
    _locationSubmitted = false;
    _mapBounds = null;
    _distance = 0;
    _zoomLevel = 10.0; // or any default zoom level you prefer
    _mapCenter = LatLng(0, 0); // or any default map center you prefer
    _points = 0;
    notifyListeners();
  }

   void resetLocationSubmission() {
    _locationSubmitted = false;
    notifyListeners();
      print("location submitted$_locationSubmitted");
  }

  void updateMapBounds(LatLngBounds bounds) {
    _mapBounds = bounds;
    notifyListeners();
  }

  void updateMapZoomLevel(double zoomLevel) {
    _zoomLevel = zoomLevel;
    notifyListeners();
  }

  void updateMapCenter(LatLng center) {
    _mapCenter = center;
    notifyListeners();
  }
}