import 'dart:async';

import 'package:fit_guard_app/Core/constants/app_colors.dart';
import 'package:fit_guard_app/features/nearby_gyms/models/gym_model.dart';
import 'package:fit_guard_app/features/nearby_gyms/providers/nearby_gyms_provider.dart';
import 'package:fit_guard_app/features/nearby_gyms/widgets/empty_gyms_widget.dart';
import 'package:fit_guard_app/features/nearby_gyms/widgets/gym_card.dart';
import 'package:fit_guard_app/features/nearby_gyms/widgets/gyms_loading_shimmer.dart';
import 'package:fit_guard_app/features/nearby_gyms/widgets/permission_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NearbyGymsScreen extends StatefulWidget {
  const NearbyGymsScreen({super.key});

  @override
  State<NearbyGymsScreen> createState() => _NearbyGymsScreenState();
}

class _NearbyGymsScreenState extends State<NearbyGymsScreen> {
  late final NearbyGymsProvider _provider;
  final ScrollController _scrollController = ScrollController();
  GoogleMapController? _mapController;
  String? _lastFocusedGymId;

  @override
  void initState() {
    super.initState();
    _provider = NearbyGymsProvider()..addListener(_onProviderChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _provider.load());
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChanged);
    _provider.dispose();
    _mapController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onProviderChanged() {
    if (!mounted) return;
    final focusedId = _provider.focusedGymId;
    if (focusedId != null && focusedId != _lastFocusedGymId) {
      _lastFocusedGymId = focusedId;
      final index = _provider.gyms.indexWhere((gym) => gym.id == focusedId);
      if (index >= 0 && _scrollController.hasClients) {
        final target = 330.0 + (index * 318.0);
        _scrollController.animateTo(
          target.clamp(0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
        );
      }
      final gym = _provider.gyms.cast<Gym?>().firstWhere(
        (gym) => gym?.id == focusedId,
        orElse: () => null,
      );
      if (gym != null) _animateToGym(gym);
    }
    setState(() {});
  }

  Future<void> _animateToGym(Gym gym) async {
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(gym.latitude, gym.longitude), 15),
    );
  }

  Future<void> _refresh() => _provider.load(forceRefresh: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          'Nearby Gyms',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _provider.isBusy ? null : _refresh,
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: _body(),
      ),
    );
  }

  Widget _body() {
    switch (_provider.status) {
      case NearbyGymsStatus.initial:
      case NearbyGymsStatus.loading:
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: const [
            _MapPlaceholder(),
            SizedBox(height: 18),
            GymsLoadingShimmer(),
          ],
        );
      case NearbyGymsStatus.permissionDenied:
        return _stateList(
          PermissionWidget(
            icon: Icons.location_off,
            title: 'Location permission needed',
            message:
                'Allow FitGuard to use your location so we can find gyms near you.',
            primaryLabel: 'Try Again',
            onPrimary: () => _provider.load(forceRefresh: true),
          ),
        );
      case NearbyGymsStatus.permissionPermanentlyDenied:
        return _stateList(
          PermissionWidget(
            icon: Icons.settings,
            title: 'Permission blocked',
            message:
                'Location permission is permanently denied. Open app settings and enable location access.',
            primaryLabel: 'Open Settings',
            onPrimary: _provider.openAppSettings,
            secondaryLabel: 'Retry',
            onSecondary: () => _provider.load(forceRefresh: true),
          ),
        );
      case NearbyGymsStatus.gpsDisabled:
        return _stateList(
          PermissionWidget(
            icon: Icons.gps_off,
            title: 'GPS is disabled',
            message:
                'Turn on location services to detect where you are and sort nearby gyms by distance.',
            primaryLabel: 'Open Location Settings',
            onPrimary: _provider.openLocationSettings,
            secondaryLabel: 'Retry',
            onSecondary: () => _provider.load(forceRefresh: true),
          ),
        );
      case NearbyGymsStatus.empty:
        return _stateList(EmptyGymsWidget(onRetry: _refresh));
      case NearbyGymsStatus.error:
        return _stateList(
          PermissionWidget(
            icon: Icons.warning_amber_rounded,
            title: 'Could not load gyms',
            message:
                _provider.errorMessage ??
                'Something went wrong while searching nearby gyms.',
            primaryLabel: 'Retry',
            onPrimary: () => _provider.load(forceRefresh: true),
          ),
        );
      case NearbyGymsStatus.ready:
        return _readyList();
    }
  }

  Widget _stateList(Widget child) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [child],
    );
  }

  Widget _readyList() {
    return ListView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        _buildMap(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                '${_provider.gyms.length} gyms within 5 km',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_provider.isRefreshing)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Sorted by nearest distance, then highest rating.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 16),
        ..._provider.gyms.asMap().entries.map((entry) {
          final gym = entry.value;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 240 + (entry.key * 45)),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 18 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: GymCard(
              gym: gym,
              focused: _provider.focusedGymId == gym.id,
              onTap: () => _provider.focusGym(gym.id),
              onOpenMaps: () => _provider.openInMaps(gym),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMap() {
    final current = _provider.userLatLng;
    if (current == null) return const _MapPlaceholder();

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 300,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: current, zoom: 14),
          onMapCreated: (controller) => _mapController = controller,
          markers: _provider.markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: true,
          onTap: (_) => _provider.focusGym(''),
        ),
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 14),
            Text(
              'Finding gyms near you...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
