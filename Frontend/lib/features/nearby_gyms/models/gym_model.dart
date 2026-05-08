import 'package:geolocator/geolocator.dart';

class Gym {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double rating;
  final int totalReviews;
  final String address;
  final double distanceKm;
  final String? imageUrl;
  final bool? openNow;

  const Gym({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.totalReviews,
    required this.address,
    required this.distanceKm,
    required this.imageUrl,
    required this.openNow,
  });

  factory Gym.fromGooglePlace({
    required Map<String, dynamic> json,
    required double userLatitude,
    required double userLongitude,
    required String apiKey,
  }) {
    final geometry = json['geometry'] is Map
        ? Map<String, dynamic>.from(json['geometry'] as Map)
        : <String, dynamic>{};
    final location = geometry['location'] is Map
        ? Map<String, dynamic>.from(geometry['location'] as Map)
        : <String, dynamic>{};
    final latitude = _readDouble(location['lat']);
    final longitude = _readDouble(location['lng']);
    final distanceMeters = Geolocator.distanceBetween(
      userLatitude,
      userLongitude,
      latitude,
      longitude,
    );
    final photos = json['photos'] is List ? json['photos'] as List : const [];
    final firstPhoto = photos.isNotEmpty && photos.first is Map
        ? Map<String, dynamic>.from(photos.first as Map)
        : <String, dynamic>{};
    final photoRef = firstPhoto['photo_reference']?.toString();
    final openingHours = json['opening_hours'] is Map
        ? Map<String, dynamic>.from(json['opening_hours'] as Map)
        : null;

    return Gym(
      id: (json['place_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Unnamed gym').toString(),
      latitude: latitude,
      longitude: longitude,
      rating: _readDouble(json['rating']),
      totalReviews: _readInt(json['user_ratings_total']),
      address:
          (json['vicinity'] ?? json['formatted_address'] ?? 'No address found')
              .toString(),
      distanceKm: distanceMeters / 1000,
      imageUrl: photoRef == null || photoRef.isEmpty
          ? null
          : 'https://maps.googleapis.com/maps/api/place/photo'
                '?maxwidth=700&photo_reference=$photoRef&key=$apiKey',
      openNow: openingHours?['open_now'] is bool
          ? openingHours!['open_now'] as bool
          : null,
    );
  }

  static double _readDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
