import 'package:cloud_firestore/cloud_firestore.dart';

class LocationModel {
  final String name;
  final double latitude;
  final double longitude;
  final String videoUrl;

  LocationModel({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.videoUrl,
  });

  factory LocationModel.fromDocumentSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    return LocationModel(
      name: data['name'],
      latitude: data['latitude'],
      longitude: data['longitude'],
      videoUrl: data['videoUrl'],
    );
  }
}


