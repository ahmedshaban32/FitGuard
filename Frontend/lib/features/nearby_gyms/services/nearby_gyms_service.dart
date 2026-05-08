import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fit_guard_app/features/nearby_gyms/models/gym_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class NearbyGymsException implements Exception {
  final String message;
  const NearbyGymsException(this.message);

  @override
  String toString() => message;
}

class NearbyGymsService {
  NearbyGymsService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const int radiusMeters = 5000;
  static const Duration _cacheDuration = Duration(minutes: 10);
  static List<Gym>? _cachedGyms;
  static Position? _cachedPosition;
  static DateTime? _cacheTime;

  String get apiKey {
    return dotenv.env['GOOGLE_PLACES_API_KEY']?.trim().isNotEmpty == true
        ? dotenv.env['GOOGLE_PLACES_API_KEY']!.trim()
        : (dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '').trim();
  }

  Future<List<Gym>> findNearbyGyms({
    required Position position,
    bool forceRefresh = false,
  }) async {
    final key = apiKey;
    if (key.isEmpty) {
      throw const NearbyGymsException(
        'Google API key is missing. Add it to Frontend/.env.',
      );
    }

    if (!forceRefresh && _isCacheValid(position)) {
      return _cachedGyms!;
    }

    try {
      final responses = await Future.wait([
        _nearbySearch(position: position, keyword: 'gym', apiKey: key),
        _nearbySearch(
          position: position,
          keyword: 'fitness center',
          apiKey: key,
        ),
      ]);
      final byId = <String, Gym>{};
      for (final list in responses) {
        for (final gym in list) {
          if (gym.id.isNotEmpty) byId[gym.id] = gym;
        }
      }

      final gyms = byId.values.toList()
        ..sort((a, b) {
          final distance = a.distanceKm.compareTo(b.distanceKm);
          if (distance != 0) return distance;
          return b.rating.compareTo(a.rating);
        });

      _cachedGyms = gyms;
      _cachedPosition = position;
      _cacheTime = DateTime.now();
      return gyms;
    } on SocketException {
      throw const NearbyGymsException('No internet connection.');
    } on TimeoutException {
      throw const NearbyGymsException(
        'Google Places took too long to respond.',
      );
    }
  }

  Future<List<Gym>> _nearbySearch({
    required Position position,
    required String keyword,
    required String apiKey,
  }) async {
    final uri =
        Uri.https('maps.googleapis.com', '/maps/api/place/nearbysearch/json', {
          'location': '${position.latitude},${position.longitude}',
          'radius': '$radiusMeters',
          'keyword': keyword,
          'type': 'gym',
          'key': apiKey,
        });

    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw NearbyGymsException(
        'Google Places failed (${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const NearbyGymsException('Invalid Google Places response.');
    }

    final status = decoded['status']?.toString() ?? 'UNKNOWN';
    if (status == 'ZERO_RESULTS') return const [];
    if (status == 'OVER_QUERY_LIMIT') {
      throw const NearbyGymsException(
        'Google Places quota exceeded. Try again later.',
      );
    }
    if (status == 'REQUEST_DENIED') {
      final detail = decoded['error_message']?.toString();
      throw NearbyGymsException(
        detail == null || detail.isEmpty
            ? 'Google Places request was denied. Check your API key.'
            : detail,
      );
    }
    if (status != 'OK') {
      throw NearbyGymsException('Google Places error: $status');
    }

    final results = decoded['results'] is List
        ? decoded['results'] as List
        : const [];
    return results
        .whereType<Map>()
        .map(
          (item) => Gym.fromGooglePlace(
            json: Map<String, dynamic>.from(item),
            userLatitude: position.latitude,
            userLongitude: position.longitude,
            apiKey: apiKey,
          ),
        )
        .where((gym) => gym.latitude != 0 && gym.longitude != 0)
        .toList();
  }

  bool _isCacheValid(Position position) {
    final gyms = _cachedGyms;
    final cachedAt = _cacheTime;
    final cachedPosition = _cachedPosition;
    if (gyms == null || cachedAt == null || cachedPosition == null) {
      return false;
    }
    if (DateTime.now().difference(cachedAt) > _cacheDuration) return false;

    final movedMeters = Geolocator.distanceBetween(
      cachedPosition.latitude,
      cachedPosition.longitude,
      position.latitude,
      position.longitude,
    );
    return movedMeters < 500;
  }

  void dispose() {
    _client.close();
  }
}
