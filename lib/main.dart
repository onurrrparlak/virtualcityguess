import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:virtualcityguess/services/game_service.dart';
import 'package:virtualcityguess/views/game_screen.dart';
import 'package:virtualcityguess/services/timer_service.dart';
import 'package:virtualcityguess/widgets/custom_dialog_sheet.dart';
import 'firebase_options.dart';
import 'package:virtualcityguess/services/firestore_service.dart';
import 'package:virtualcityguess/views/home_screen.dart';
import 'package:virtualcityguess/widgets/videoplayer.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter binding is initialized
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TimerService()),
        ChangeNotifierProvider(create: (_) => GameService()),
         ChangeNotifierProvider(create: (_) => LocationNotifier()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Map Guessing Game',
      home: SafeArea(child: HomeScreen()),
    );
  }
}

class MapScreen extends StatefulWidget {
  final String roomId;
  final String playerName;
  final bool isHost;

  MapScreen(
      {required this.roomId, required this.playerName, required this.isHost});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final FirestoreService _firestoreService = FirestoreService();
  late Stream<DocumentSnapshot> _roomStream;
  int _timerDuration = 60;
  Timer? _timer;
  bool _timerExpired = false;
  bool _locationSubmitted = false;

  final List<LatLng> _locations = [
    LatLng(51.5074, -0.1278), // London
    LatLng(41.0082, 28.9784), // Istanbul
    LatLng(40.7128, -74.0060), // New York
    LatLng(48.8566, 2.3522), // Paris
    LatLng(34.0522, -118.2437), // Los Angeles
    LatLng(52.3676, 4.9041), // Amsterdam
    LatLng(35.6895, 139.6917), // Tokyo
    LatLng(59.3293, 18.0686), // Stockholm
    LatLng(25.2048, 55.2708), // Dubai
    LatLng(55.7558, 37.6173) // Moscow
  ];

  final List<String> _locationVideoUrls = [
    'https://firebasestorage.googleapis.com/v0/b/filmprojesi-cf2a0.appspot.com/o/London.mp4?alt=media&token=3b129364-96e4-47ba-a38d-de4fda53fa96',
    'https://firebasestorage.googleapis.com/v0/b/filmprojesi-cf2a0.appspot.com/o/Istanbul.mp4?alt=media&token=27afb2d3-41cb-437f-a6a6-a4492f461386'
    // Add other video URLs here
  ];

  bool _isHost = false;
  bool _gameStarted = false;
  int _currentTargetIndex = 0;
  bool _showLineAndTargetMarker = false;
  LatLngBounds? _storedBounds;
  bool _showNextButton = false;
  MapController _mapController = MapController();
  int _playerPoint = 0; // Store total points
  LatLng _currentLocation = LatLng(15, 15);
  LatLng _initialLocation = LatLng(15, 15);

  LatLng get _currentTargetLocation => _locations[_currentTargetIndex];

  @override
  void initState() {
    super.initState();
    _roomStream = _firestoreService.getRoomStream(widget.roomId);
    _isHost = widget.isHost;
  }

  @override
  void deactivate() {
    if (_isHost) {
      _firestoreService.deleteRoom(widget.roomId);
    }
    super.deactivate();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel timer to avoid memory leaks
    print(_isHost);
    if (_isHost) {
      _firestoreService.deleteRoom(widget.roomId);
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
 void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print(_isHost);
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.detached) {
      if (_isHost) {
        
        _firestoreService.deleteRoom(widget.roomId);
      }
    }
  }

  void startTimer() {
    const oneSecond = Duration(seconds: 1);
    _timer?.cancel();
    _timer = Timer.periodic(oneSecond, (timer) {
      setState(() {
        if (_timerDuration < 1) {
          _timer?.cancel();
          if (!_timerExpired) {
            _timerExpired = true;
            _showOrRefreshMapPopup(context);
          }
        } else {
          _timerDuration--;
        }
      });
    });
  }

  

  void _submitLocation(StateSetter updateState) async {
    final distance = Distance().as(
      LengthUnit.Meter,
      _currentLocation,
      _currentTargetLocation,
    );

    double distanceInKm = distance / 1000; // Convert distance to kilometers

    int points;

    if (distanceInKm <= 0.5) {
      points = 600;
    } else if (distanceInKm > 0.5 && distanceInKm <= 10) {
      points = (500 - (distanceInKm - 0.5) * 8).round().clamp(200, 500);
    } else if (distanceInKm > 10 && distanceInKm <= 100) {
      points = (400 - (distanceInKm - 10) * 2).round().clamp(200, 400);
    } else if (distanceInKm > 100 && distanceInKm <= 500) {
      points = (200 - (distanceInKm - 100) * 0.2).round().clamp(100, 200);
    } else if (distanceInKm > 500 && distanceInKm <= 2000) {
      points = (100 - (distanceInKm - 500) * 0.05).round().clamp(0, 100);
    } else {
      points = 0;
    }

    // Update total points
    setState(() {
      _playerPoint += points;
    });

    // Update submittedPlayers in Firestore
  await _firestoreService.updatePlayerSubmissionStatus(widget.roomId, widget.playerName, true);

  // Check if all players have submitted their locations
  final allPlayersSubmitted = await _firestoreService.checkAllPlayersSubmitted(widget.roomId);
  if (allPlayersSubmitted || _timerDuration == 0) {
    
  }

    await _firestoreService.updatePoints(
        widget.roomId, widget.playerName, _playerPoint);
    if (mounted) {
      // Check if the widget is still mounted
      updateState(() {
        _showLineAndTargetMarker = true;
        _showNextButton =
            true; // Set _showNextButton to true after submitting location
      });
    }

    // Set locationSubmitted to true
    _locationSubmitted = true;

    // Calculate bounds to fit both locations

    LatLngBounds bounds =
        LatLngBounds.fromPoints([_currentLocation, _currentTargetLocation]);
    _storedBounds = bounds;
    _mapController.fitBounds(
      bounds,
      options: FitBoundsOptions(
          padding: EdgeInsets.all(MediaQuery.of(context).size.height *
              0.045)), // Add some padding around the bounds
    );

    // Show SnackBar above the popup
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: points == 0
            ? Text(
                'You are ${(distanceInKm).toStringAsFixed(2)} km away from the location. You earned 0 points.')
            : Text(
                'You are ${(distanceInKm).toStringAsFixed(2)} km away from the location. You earned $points points!'),
        duration: Duration(seconds: 3),
      ),
    );
  }

 void _nextLocation() async {
  // Check if all players have submitted their locations
  final allPlayersSubmitted = await _firestoreService.checkAllPlayersSubmitted(widget.roomId);
  
  if (!allPlayersSubmitted) {
    // Show a message indicating that all players need to submit their locations
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Not all players have submitted their locations yet.'),
        duration: Duration(seconds: 3),
      ),
    );
    return; // Exit the function without advancing to the next round
  }
  
  // Update submittedPlayers in Firestore to mark the current player as not submitted
  await _firestoreService.updatePlayerSubmissionStatus(widget.roomId, widget.playerName, false);
  
  setState(() {
    // Reset various states
    _showLineAndTargetMarker = false;
    _currentTargetIndex = (_currentTargetIndex + 1) % _locations.length;
    _currentLocation = _initialLocation;
    _showNextButton = false;
    _timerExpired = false; // Reset timer expired status
    _locationSubmitted = false; // Reset location submitted status
    _timerDuration = 60; // Reset timer duration
  });

  // Restart the timer
  startTimer();

  // Show SnackBar indicating the next location guess
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Now guess where the next location is!'),
      duration: Duration(seconds: 3),
    ),
  );
  _storedBounds = null;

  // Close the popup if it's open
  if (Navigator.of(context).canPop()) {
    Navigator.of(context).pop();
  }

  // Move map only if the map controller is active
  if (_showLineAndTargetMarker || _timerExpired) {
    _mapController.move(
      _initialLocation,
      1,
    );
  }
}


  void _showSnackBar(String message) {
    // Show SnackBar with the provided message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      ),
    );
  }

  _showOrRefreshMapPopup(BuildContext context) {
    if (_scaffoldKey.currentState!.isDrawerOpen) {
      // If a bottom sheet is currently open, refresh its content
      Navigator.of(context).pop();
      _openMapPopup(context);
    } else {
      // If no bottom sheet is open, open a new one
      _openMapPopup(context);
    }
  }

  void _openMapPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return WillPopScope(
              onWillPop: () async {
                if (_timerExpired) {
                  return true;
                } else {
                  return false;
                }
              },
              child: Container(
                height: MediaQuery.of(context).size.height * 0.8,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                    Expanded(
                      child: AbsorbPointer(
                        absorbing: false,
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            bounds: _storedBounds != null
                                ? _storedBounds
                                : null, // Remove bounds
                            boundsOptions: FitBoundsOptions(
                                padding: EdgeInsets.all(
                                    MediaQuery.of(context).size.height *
                                        0.045)), // Remove bounds options
                            center: _timerExpired && !_locationSubmitted
                                ? _currentTargetLocation
                                : _initialLocation,
                            zoom: _timerExpired && !_locationSubmitted
                                ? 10.0
                                : 1.0,
                            onTap: _timerExpired
                                ? null
                                : (tapPosition, point) {
                                    setState(() {
                                      _currentLocation = point;
                                      _showLineAndTargetMarker = false;
                                    });
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
                                if ((_locationSubmitted ||
                                        (!_timerExpired &&
                                            !_locationSubmitted)) ||
                                    (_timerExpired &&
                                        !_locationSubmitted)) // Show red marker if location is submitted or if timer expired and location is not submitted
                                  Marker(
                                    point: _currentLocation,
                                    width: 80,
                                    height: 80,
                                    child: Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 30,
                                    ),
                                  ),
                                if (_showLineAndTargetMarker ||
                                    _timerExpired) // Show target marker when timer expires
                                  Marker(
                                    point: _currentTargetLocation,
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
                            if ((_locationSubmitted || !_timerExpired) &&
                                _showLineAndTargetMarker) // Show polyline layer conditionally
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: [
                                      _currentLocation,
                                      _currentTargetLocation
                                    ],
                                    strokeWidth: 4.0,
                                    color: Colors.blue,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (!_showNextButton && !_timerExpired)
                      Padding(
                        padding: EdgeInsets.all(
                            MediaQuery.of(context).size.height * 0.005),
                        child: ElevatedButton(
                          onPressed: () => _submitLocation(setState),
                          child: Text('Submit Location'),
                        ),
                      ),
                    if (_showNextButton || _timerExpired)
                      Padding(
                        padding: EdgeInsets.all(
                            MediaQuery.of(context).size.height * 0.005),
                        child: ElevatedButton(
                          onPressed: _nextLocation,
                          child: Text('Next'),
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.all(
                          MediaQuery.of(context).size.height * 0.005),
                      child: Text(
                        'Total Points: $_playerPoint',
                        style: TextStyle(
                            fontSize:
                                MediaQuery.of(context).size.height * 0.020,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _roomStream,
      builder: (context, snapshot) {
        List<MapEntry<String, dynamic>> sortedPoints = [];
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            var roomData = snapshot.data!.data() as Map<String, dynamic>;
            //_currentTargetIndex = roomData['currentTargetIndex'];

            Map<String, dynamic> players = roomData['players'] ?? {};
            sortedPoints = players.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            _gameStarted = roomData['gameStarted'];

            if (_gameStarted && _timer == null) {
              // Start the timer and video when the game starts
              startTimer();
            }
          }
        }

        return SafeArea(
          child: Scaffold(
            key: _scaffoldKey,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      if (!_gameStarted)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           
                          SelectableText(
                            'Room ID: ${widget.roomId}',
                            style: TextStyle(fontSize: 16),
                          ),
                          IconButton(
                            icon: Icon(Icons.copy),
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: widget.roomId));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Room ID copied to clipboard')),
                              );
                            },
                          ),
                        ],
                      ),
                      if (_isHost && !_gameStarted)
                        ElevatedButton(
                          onPressed: (){
                            
                          },
                          child: Text('Start Game'),
                        ),
                      if (_gameStarted) // Show game components when the game has started
                        Text('Game has started!'),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            vertical:
                                MediaQuery.of(context).size.height * 0.005),
                        child: Text(
                          _timerDuration == 0
                              ? 'Time Expired'
                              : 'Time Left: $_timerDuration seconds',
                          style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.height * 0.020,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical:
                                        MediaQuery.of(context).size.height *
                                            0.005),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Text(
                                      'Scoreboard',
                                      style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.020,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    ...sortedPoints
                                        .map((entry) => Text(
                                              '${entry.key}: ${entry.value} Points',
                                              style: TextStyle(
                                                fontSize: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.018,
                                              ),
                                            ))
                                        .toList(),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 19,
                              child: Center(
                                child: _gameStarted
                                    ? VideoPlayerWidget(
                                        videoUrl: _locationVideoUrls[
                                            _currentTargetIndex],
                                      )
                                    : Text(
                                        _isHost
                                            ? 'Players waiting for you to start the game..'
                                            : 'Waiting for the host to start the game...',
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: EdgeInsets.all(
                        MediaQuery.of(context).size.height * 0.001),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_gameStarted)
                          ElevatedButton(
                            onPressed: () => _showOrRefreshMapPopup(context),
                            child: Text(_locationSubmitted || _timerExpired
                                ? 'Show Results'
                                : 'Guess Location'),
                          ),
                        if (_timerExpired == true)
                          ElevatedButton(
                            onPressed: _nextLocation,
                            child: Text('Next'),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
