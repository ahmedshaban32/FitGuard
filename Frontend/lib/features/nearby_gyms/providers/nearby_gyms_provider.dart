import 'dart:async';

import 'package:fit_guard_app/features/nearby_gyms/models/gym_model.dart';
import 'package:fit_guard_app/features/nearby_gyms/services/nearby_gyms_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart' as permissions;
import 'package:url_launcher/url_launcher.dart';

enum NearbyGymsStatus {
  initial,
  loading,
  ready,
  empty,
  permissionDenied,
  permissionPermanentlyDenied,
  gpsDisabled,
  error,
}

class NearbyGymsProvider extends ChangeNotifier {
  NearbyGymsProvider({NearbyGymsService? service})
    : _service = service ?? NearbyGymsService();

  final NearbyGymsService _service;

  NearbyGymsStatus status = NearbyGymsStatus.initial;
  Position? userPosition;
  List<Gym> gyms = [];
  String? errorMessage;
  String? focusedGymId;
  bool isRefreshing = false;

  bool get isBusy => status == NearbyGymsStatus.loading || isRefreshing;
  LatLng? get userLatLng => userPosition == null
      ? null
      : LatLng(userPosition!.latitude, userPosition!.longitude);

  Set<Marker> get markers {
    final current = userLatLng;
    return {
      if (current != null)
        Marker(
          markerId: const MarkerId('user-location'),
          position: current,
          infoWindow: const InfoWindow(title: 'You are here'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      ...gyms.map(
        (gym) => Marker(
          markerId: MarkerId(gym.id),
          position: LatLng(gym.latitude, gym.longitude),
          infoWindow: InfoWindow(
            title: gym.name,
            snippet: '${gym.distanceKm.toStringAsFixed(1)} km away',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            focusedGymId == gym.id
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueViolet,
          ),
          onTap: () => focusGym(gym.id),
        ),
      ),
    };
  }

  Future<void> load({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      _setStatus(NearbyGymsStatus.loading);
    } else {
      isRefreshing = true;
      notifyListeners();
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setStatus(NearbyGymsStatus.gpsDisabled);
        return;
      }

      final permission = await _ensureLocationPermission();
      if (permission == LocationPermission.denied) {
        _setStatus(NearbyGymsStatus.permissionDenied);
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        _setStatus(NearbyGymsStatus.permissionPermanentlyDenied);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      userPosition = position;
      final results = await _service.findNearbyGyms(
        position: position,
        forceRefresh: forceRefresh,
      );
      gyms = results;
      focusedGymId = results.isNotEmpty ? results.first.id : null;
      _setStatus(
        results.isEmpty ? NearbyGymsStatus.empty : NearbyGymsStatus.ready,
      );
    } on TimeoutException {
      errorMessage = 'Location or gym search timed out. Please retry.';
      _setStatus(NearbyGymsStatus.error);
    } on NearbyGymsException catch (error) {
      errorMessage = error.message;
      _setStatus(NearbyGymsStatus.error);
    } catch (error) {
      errorMessage = 'Could not load nearby gyms. Please retry.';
      _setStatus(NearbyGymsStatus.error);
    } finally {
      isRefreshing = false;
      notifyListeners();
    }
  }

  Future<LocationPermission> _ensureLocationPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  void focusGym(String gymId) {
    focusedGymId = gymId;
    notifyListeners();
  }

  Future<void> openInMaps(Gym gym) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${gym.latitude},${gym.longitude}'
      '&travelmode=driving',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      errorMessage = 'Could not open Google Maps.';
      _setStatus(NearbyGymsStatus.error);
    }
  }

  Future<void> openAppSettings() => permissions.openAppSettings();

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  void _setStatus(NearbyGymsStatus value) {
    status = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
