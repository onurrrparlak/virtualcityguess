import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:virtualcityguess/provider/location_notifier_provider.dart';
import 'package:virtualcityguess/services/firestore_service.dart';
import 'package:virtualcityguess/services/game_service.dart';
import 'package:virtualcityguess/services/timer_service.dart';

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
  int points = 0;
  double? distanceInKm;
  bool _buttonClicked = false;

  @override
  void initState() {
    super.initState();
    final gameService = Provider.of<GameService>(context, listen: false);
    gameService.fetchCurrentTargetLatLng().then((latLng) {
      if (latLng != null) {
        Provider.of<LocationNotifier>(context, listen: false)
            .setCurrentTargetLocation(latLng);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationNotifier = Provider.of<LocationNotifier>(context);
    final timerService = Provider.of<TimerService>(context);
    final timerExpired = timerService.timerExpired;

    return Dialog(
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
                  if (locationNotifier.locationSubmitted)
                  Container(color: Colors.white,
                    child: Column(
                      children: [
                        Text('This round points: ${locationNotifier.points}'),
                        Text(
                          'You are ${locationNotifier.distance?.toStringAsFixed(2)} km away from the location',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
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
                      center: !timerExpired
                          ? locationNotifier.currentLocation
                          : locationNotifier.currentTargetLocation,
                      interactiveFlags:
                          locationNotifier.locationSubmitted || timerExpired
                              ? InteractiveFlag.none
                              : InteractiveFlag.all,
                      zoom: timerExpired && !locationNotifier.locationSubmitted
                          ? 6.0
                          : 1.0,
                      onTap: (tapPosition, point) {
                        if (!locationNotifier.locationSubmitted &&
                            !timerExpired) {
                          locationNotifier.setCurrentLocation(point);
                          locationNotifier.setShowLineAndTargetMarker(false);
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.app',
                        tileProvider: CancellableNetworkTileProvider(),
                      ),
                      MarkerLayer(
                        markers: [
                          if (!timerExpired ||
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
                              (locationNotifier.locationSubmitted ||
                                  timerExpired))
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
                      onPressed: _buttonClicked
                          ? null
                          : () async {
                              setState(() {
                                _buttonClicked = true; // Disable the button
                              });
                              if (!locationNotifier.locationSubmitted &&
                                  !timerExpired) {
                                try {
                                  final gameService = Provider.of<GameService>(
                                      context,
                                      listen: false);

                                  await gameService.userSubmitLocation(
                                      widget.roomId, widget.playerName, true);

                                  if (locationNotifier.currentTargetLocation !=
                                      null) {
                                    LatLngBounds bounds =
                                        LatLngBounds.fromPoints([
                                      locationNotifier.currentLocation,
                                      locationNotifier.currentTargetLocation!,
                                    ]);

                                    locationNotifier.updateMapBounds(
                                        bounds); // Update map bounds
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
                                  print(points);

                                  // Update points in Firestore
                                  final firestoreService =
                                      Provider.of<FirestoreService>(context,
                                          listen: false);
                                  await firestoreService.updatePoints(
                                      widget.roomId, widget.playerName, points);

                                  locationNotifier.setLocationSubmitted(true);
                                  locationNotifier.setPoints(points);
                                  locationNotifier.setDistance(distanceInKm);
                                  locationNotifier
                                      .setShowLineAndTargetMarker(true);
                                } catch (e) {
                                  print('Error during onPressed: $e');
                                }
                              }
                            },
                      child: Text(
                        locationNotifier.locationSubmitted || timerExpired
                            ? 'Show Results'
                            : 'Submit Location',
                      ),
                    ),
                  ),
              
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
