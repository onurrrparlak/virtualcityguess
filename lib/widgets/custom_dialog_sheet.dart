import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:virtualcityguess/services/game_service.dart';
import 'package:virtualcityguess/services/timer_service.dart';

class LocationNotifier extends ChangeNotifier {
  LatLng _currentLocation = LatLng(0, 0);
  LatLng? _currentTargetLocation;
  bool _showLineAndTargetMarker = false;
  bool _locationSubmitted = false;
  LatLngBounds? _mapBounds; // New field for storing map bounds

  LatLng get currentLocation => _currentLocation;
  LatLng? get currentTargetLocation => _currentTargetLocation;
  bool get showLineAndTargetMarker => _showLineAndTargetMarker;
  bool get locationSubmitted => _locationSubmitted;
  LatLngBounds? get mapBounds => _mapBounds; // Getter for map bounds

  void setCurrentLocation(LatLng location) {
    _currentLocation = location;
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
  }

  // Method to update map bounds
  void updateMapBounds(LatLngBounds bounds) {
    _mapBounds = bounds;
    notifyListeners();
  }

  // Method to update map zoom level
}

class CustomDialogSheet extends StatefulWidget {
  final String roomId;
  final String playerName;

  const CustomDialogSheet({
    required this.roomId,
    required this.playerName,
  });

  @override
  _CustomDialogSheetState createState() => _CustomDialogSheetState();
}

class _CustomDialogSheetState extends State<CustomDialogSheet> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    final gameService = Provider.of<GameService>(context, listen: false);
    gameService.fetchCurrentTargetLatLng().then((latLng) {
      if (latLng != null) {
        setState(() {
          Provider.of<LocationNotifier>(context, listen: false)
              .setCurrentTargetLocation(latLng);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationNotifier = Provider.of<LocationNotifier>(context);
    final timerNotifier = Provider.of<TimerService>(context);

    // Check if map bounds and zoom level are available
    LatLngBounds? bounds = locationNotifier.mapBounds;

    if (timerNotifier.timerExpired) {
      setState(() {});
    }

    return Dialog(
      key: UniqueKey(), //
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        width: MediaQuery.of(context).size.width * 0.8,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      bounds: locationNotifier.mapBounds,
                      boundsOptions: FitBoundsOptions(
                        padding: EdgeInsets.all(
                          MediaQuery.of(context).size.height * 0.045,
                        ),
                      ),
                      center: !timerNotifier.timerExpired
                          ? locationNotifier.currentLocation
                          : locationNotifier.currentTargetLocation,
                      interactiveFlags: locationNotifier.locationSubmitted ||
                              timerNotifier.timerExpired
                          ? InteractiveFlag.none
                          : InteractiveFlag.all,
                      zoom: timerNotifier.timerExpired &&
                              !locationNotifier.locationSubmitted
                          ? 7.0
                          : 1.0,
                      onTap: (tapPosition, point) {
                        if (!locationNotifier.locationSubmitted &&
                            !timerNotifier.timerExpired) {
                          locationNotifier.setCurrentLocation(point);
                          locationNotifier.setShowLineAndTargetMarker(false);
                        }
                      },
                      onPositionChanged: (position, hasGesture) {
                        if (!locationNotifier.locationSubmitted &&
                            !timerNotifier.timerExpired) {
                          locationNotifier
                              .updateMapBounds(_mapController.bounds!);
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.app',
                      ),
                      MarkerLayer(
                        markers: [
                          if (!timerNotifier.timerExpired ||
                              locationNotifier.locationSubmitted)
                            Marker(
                              point: locationNotifier.currentLocation,
                              width: 80,
                              height: 80,
                              child: Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 30,
                              ),
                            ),
                          if (locationNotifier.currentTargetLocation != null &&
                                  locationNotifier.locationSubmitted ||
                              timerNotifier.timerExpired)
                            Marker(
                              point: locationNotifier.currentTargetLocation!,
                              width: 80,
                              height: 80,
                              child: Icon(
                                Icons.location_on,
                                color: Colors.green[700],
                                size: 30,
                              ),
                            ),
                        ],
                      ),
                      if (locationNotifier.locationSubmitted &&
                          locationNotifier.currentTargetLocation != null)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: [
                                locationNotifier.currentLocation,
                                locationNotifier.currentTargetLocation!,
                              ],
                              strokeWidth: 4.0,
                              color: Colors.blue,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (!locationNotifier.locationSubmitted)
                  Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: ElevatedButton(
                        onPressed: () {
                          if (!locationNotifier.locationSubmitted &&
                              !timerNotifier.timerExpired) {
                            final gameService = Provider.of<GameService>(
                                context,
                                listen: false);
                            locationNotifier.setLocationSubmitted(true);
                            gameService.userSubmitLocation(
                              widget.roomId,
                              widget.playerName,
                              locationNotifier.currentLocation,
                            );

                            if (locationNotifier.currentTargetLocation !=
                                null) {
                              LatLngBounds bounds = LatLngBounds.fromPoints([
                                locationNotifier.currentLocation,
                                locationNotifier.currentTargetLocation!,
                              ]);

                              locationNotifier
                                  .updateMapBounds(bounds); // Update map bounds
                              _mapController.fitBounds(
                                bounds,
                                options: FitBoundsOptions(
                                  padding: EdgeInsets.all(
                                      MediaQuery.of(context).size.height *
                                          0.045),
                                ),
                              );
                            }

                            final distance = Distance().as(
                              LengthUnit.Meter,
                              locationNotifier.currentLocation,
                              locationNotifier.currentTargetLocation!,
                            );

                            double distanceInKm = distance /
                                1000; // Convert distance to kilometers

                            int points;

                            if (distanceInKm <= 0.5) {
                              points = 600;
                            } else if (distanceInKm > 0.5 &&
                                distanceInKm <= 10) {
                              points = (500 - (distanceInKm - 0.5) * 8)
                                  .round()
                                  .clamp(200, 500);
                            } else if (distanceInKm > 10 &&
                                distanceInKm <= 100) {
                              points = (400 - (distanceInKm - 10) * 2)
                                  .round()
                                  .clamp(200, 400);
                            } else if (distanceInKm > 100 &&
                                distanceInKm <= 500) {
                              points = (200 - (distanceInKm - 100) * 0.2)
                                  .round()
                                  .clamp(100, 200);
                            } else if (distanceInKm > 500 &&
                                distanceInKm <= 2000) {
                              points = (100 - (distanceInKm - 500) * 0.05)
                                  .round()
                                  .clamp(0, 100);
                            } else {
                              points = 0;
                            }

                            locationNotifier.setLocationSubmitted(true);
                            locationNotifier.setShowLineAndTargetMarker(true);
                          } else {}
                        },
                        child: Text(
                          locationNotifier.locationSubmitted ||
                                  timerNotifier.timerExpired
                              ? 'Show Results'
                              : 'Submit Location',
                        ),
                      )),
              ],
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.close),
                  color: Colors.black,
                  onPressed: () {
                    Navigator.of(context).pop();
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
