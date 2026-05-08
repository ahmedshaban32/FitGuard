import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class NearbyGymsScreen extends StatefulWidget {
  const NearbyGymsScreen({super.key});

  @override
  State<NearbyGymsScreen> createState() => _NearbyGymsScreenState();
}

class _NearbyGymsScreenState extends State<NearbyGymsScreen> {
  bool isLoading = true;
  bool showMap = false;
  Position? currentPosition;
  List<GymModel> gyms = [];
  String selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    await _getCurrentLocation();
    await _fetchNearbyGyms();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: ${e.toString()}')),
        );
      }
      // Use default location (Cairo, Egypt as example)
      currentPosition = Position(
        latitude: 30.0444,
        longitude: 31.2357,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }
  }

  Future<void> _fetchNearbyGyms() async {
    setState(() => isLoading = true);

    // Simulate API call - Replace with your actual API
    await Future.delayed(const Duration(seconds: 1));

    // Sample gym data - Replace with actual API data
    gyms = [
      GymModel(
        id: '1',
        name: 'Gold\'s Gym',
        address: '123 Fitness St, Downtown',
        distance: 0.8,
        rating: 4.5,
        reviewCount: 256,
        price: '\$50/month',
        amenities: ['Pool', 'Sauna', 'Cardio', 'Weights'],
        image:
            'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=500',
        phoneNumber: '+201234567890',
        isOpen: true,
        openingHours: '6:00 AM - 11:00 PM',
        latitude: currentPosition!.latitude + 0.005,
        longitude: currentPosition!.longitude + 0.005,
      ),
      GymModel(
        id: '2',
        name: 'FitLife Center',
        address: '456 Health Ave, Uptown',
        distance: 1.2,
        rating: 4.7,
        reviewCount: 189,
        price: '\$45/month',
        amenities: ['Yoga', 'CrossFit', 'Personal Training'],
        image:
            'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=500',
        phoneNumber: '+201234567891',
        isOpen: true,
        openingHours: '5:00 AM - 10:00 PM',
        latitude: currentPosition!.latitude - 0.008,
        longitude: currentPosition!.longitude + 0.003,
      ),
      GymModel(
        id: '3',
        name: 'PowerHouse Gym',
        address: '789 Muscle Rd, City Center',
        distance: 2.1,
        rating: 4.3,
        reviewCount: 342,
        price: '\$60/month',
        amenities: ['Boxing', 'MMA', 'Weights', 'Cardio'],
        image:
            'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=500',
        phoneNumber: '+201234567892',
        isOpen: false,
        openingHours: '7:00 AM - 9:00 PM',
        latitude: currentPosition!.latitude + 0.012,
        longitude: currentPosition!.longitude - 0.006,
      ),
      GymModel(
        id: '4',
        name: 'Fitness First',
        address: '321 Wellness Blvd, Suburbs',
        distance: 3.5,
        rating: 4.6,
        reviewCount: 412,
        price: '\$55/month',
        amenities: ['Pool', 'Spa', 'Yoga', 'Pilates'],
        image:
            'https://images.unsplash.com/photo-1593079831268-3381b0db4a77?w=500',
        phoneNumber: '+201234567893',
        isOpen: true,
        openingHours: '24/7',
        latitude: currentPosition!.latitude - 0.015,
        longitude: currentPosition!.longitude - 0.010,
      ),
      GymModel(
        id: '5',
        name: 'Iron Paradise',
        address: '654 Champion Way, East Side',
        distance: 4.2,
        rating: 4.8,
        reviewCount: 523,
        price: '\$70/month',
        amenities: ['Powerlifting', 'Olympic Lifting', 'Cardio'],
        image:
            'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=500',
        phoneNumber: '+201234567894',
        isOpen: true,
        openingHours: '5:00 AM - 11:00 PM',
        latitude: currentPosition!.latitude + 0.020,
        longitude: currentPosition!.longitude + 0.015,
      ),
    ];

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Nearby Gyms',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(showMap ? Icons.list : Icons.map, color: Colors.blue),
            onPressed: () {
              setState(() => showMap = !showMap);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: _fetchNearbyGyms,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter chips
                _buildFilterChips(),
                const SizedBox(height: 10),

                // Gym list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    itemCount: gyms.length,
                    itemBuilder: (context, index) {
                      return _buildGymCard(gyms[index]);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Nearby', 'Top Rated', 'Open Now'];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => selectedFilter = filter);
              },
              backgroundColor: Colors.grey.shade100,
              selectedColor: Colors.blue.shade100,
              labelStyle: TextStyle(
                color: isSelected ? Colors.blue.shade700 : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGymCard(GymModel gym) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gym Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Image.network(
                  gym.image,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 180,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.fitness_center, size: 50),
                    );
                  },
                ),
              ),
              Positioned(
                top: 15,
                right: 15,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: gym.isOpen ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    gym.isOpen ? 'Open' : 'Closed',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 15,
                left: 15,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${gym.distance.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Gym Info
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and Rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        gym.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.orange,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            gym.rating.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            ' (${gym.reviewCount})',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Address
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        gym.address,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Opening Hours
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      gym.openingHours,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Price
                Row(
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      gym.price,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Amenities
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: gym.amenities.map((amenity) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        amenity,
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 15),

                // Action Buttons
                Row(
                  children: [
                    const SizedBox(width: 10),

                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () {
                          _showGymDetails(gym);
                        },
                        icon: const Icon(Icons.info_outline),
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showGymDetails(GymModel gym) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gym.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow(Icons.location_on, 'Address', gym.address),
                  _buildDetailRow(Icons.access_time, 'Hours', gym.openingHours),
                  _buildDetailRow(Icons.phone, 'Phone', gym.phoneNumber),
                  _buildDetailRow(Icons.payments, 'Price', gym.price),
                  _buildDetailRow(
                    Icons.navigation,
                    'Distance',
                    '${gym.distance.toStringAsFixed(1)} km away',
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Amenities',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: gym.amenities.map((amenity) {
                      return Chip(
                        label: Text(amenity),
                        backgroundColor: Colors.blue.shade50,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Gym Model
class GymModel {
  final String id;
  final String name;
  final String address;
  final double distance;
  final double rating;
  final int reviewCount;
  final String price;
  final List<String> amenities;
  final String image;
  final String phoneNumber;
  final bool isOpen;
  final String openingHours;
  final double latitude;
  final double longitude;

  GymModel({
    required this.id,
    required this.name,
    required this.address,
    required this.distance,
    required this.rating,
    required this.reviewCount,
    required this.price,
    required this.amenities,
    required this.image,
    required this.phoneNumber,
    required this.isOpen,
    required this.openingHours,
    required this.latitude,
    required this.longitude,
  });

  factory GymModel.fromJson(Map<String, dynamic> json) {
    return GymModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      distance: (json['distance'] ?? 0).toDouble(),
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      price: json['price'] ?? '',
      amenities: List<String>.from(json['amenities'] ?? []),
      image: json['image'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      isOpen: json['isOpen'] ?? false,
      openingHours: json['openingHours'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
    );
  }
}
