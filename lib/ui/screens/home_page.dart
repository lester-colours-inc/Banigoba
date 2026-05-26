import 'package:flutter/material.dart';
import 'notifications_page.dart';
import '../../data/services/weather_service.dart';
import '../../data/services/product_service.dart';
import '../../data/models/weather.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_detail_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// The main landing page after login, providing quick access to features
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedTabIndex = 0;
  static const Color primaryColor = Color(0xFF0D0140);

  final WeatherService _weatherService = WeatherService();
  final ProductService _productService = ProductService();
  Weather? _currentWeather;
  bool _isLoadingWeather = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Small delay to ensure the UI is ready to show the permission dialog
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _checkPermissionAndFetchWeather();
    });
  }

  Future<void> _checkPermissionAndFetchWeather() async {
    var status = await Permission.location.status;

    if (status.isDenied) {
      // Show our custom explanation dialog first before triggering system dialog
      if (mounted) {
        bool? shouldRequest = await _showLocationPermissionDialog();
        if (shouldRequest == true) {
          _fetchWeather();
        } else {
          setState(() {
            _isLoadingWeather = false;
            _errorMessage = 'Location permissions are denied';
          });
        }
      }
    } else {
      // Already granted, restricted, or permanently denied (handle in _determinePosition)
      _fetchWeather();
    }
  }

  Future<bool?> _showLocationPermissionDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.location_on, color: primaryColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Local Recommendations',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: const Text(
            'To suggest the perfect fashion for your current day, we need access to your location for real-time weather updates.',
            style: TextStyle(fontSize: 15, height: 1.4),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Not Now', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text('Allow Access', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchWeather() async {
    setState(() {
      _isLoadingWeather = true;
      _errorMessage = null;
    });
    try {
      final Position position = await _determinePosition();
      final String latLong = "${position.latitude},${position.longitude}";
      final weather = await _weatherService.fetchWeather(latLong);
      if (mounted) {
        setState(() {
          _currentWeather = weather;
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingWeather = false;
          _errorMessage = e.toString();
        });
      }
      debugPrint("Weather fetch error: $e");
    }
  }

  /// Determine the current position of the device.
  Future<Position> _determinePosition() async {
    // 1. Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Prompt user to enable location services
      await Geolocator.openLocationSettings();
      return Future.error('Location services are disabled.');
    }

    // 2. Request permission using permission_handler (more robust for triggering dialogs)
    var status = await Permission.location.status;
    if (status.isDenied) {
      status = await Permission.location.request();
      if (status.isDenied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (status.isPermanentlyDenied) {
      return Future.error('Location permissions are permanently denied');
    }

    // 3. Get current position
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        distanceFilter: 1000,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        actions: [
          _buildAppBarAction(Icons.shopping_bag_outlined, () {}),
          _buildAppBarAction(Icons.chat_bubble_outline, () {
             Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsPage()),
              );
          }, hasNotification: true),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'My Fashion Style',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            _buildTabs(),
            const SizedBox(height: 25),
            // Weather Recommendation Section
            _buildWeatherRecommendation(),
            const SizedBox(height: 25),
            // Promotional/AI styling card
            _buildPromoCard(),
            const SizedBox(height: 25),
            // Feature shortcuts
            _buildFeatureCard(
              title: "Idol Style Match",
              subtitle: "Discover your global style icon twin",
              icon: Icons.star,
              color: primaryColor,
            ),
            const SizedBox(height: 15),
            _buildFeatureCard(
              title: "Plan Ahead",
              subtitle: "Week planner, trip packer & event series",
              icon: Icons.calendar_today,
              color: Colors.pinkAccent,
            ),
            const SizedBox(height: 15),
            _buildFeatureCard(
              title: "Shopping Intelligence",
              subtitle: "Smart insights for your wardrobe",
              icon: Icons.add_shopping_cart,
              color: Colors.orange,
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /// AppBar action buttons helper
  Widget _buildAppBarAction(IconData icon, VoidCallback onTap, {bool hasNotification = false}) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.black, size: 28),
          onPressed: onTap,
        ),
        if (hasNotification)
          Positioned(
            right: 12,
            top: 12,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  /// Navigation tabs for Makeover/Community/Events
  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _tabButton("Makeover", 0),
          const SizedBox(width: 15),
          _tabButton("Community", 1),
          const SizedBox(width: 15),
          _tabButton("Events", 2),
        ],
      ),
    );
  }

  /// Individual tab button widget
  Widget _tabButton(String title, int index) {
    bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  /// Promotional card with AI styling info
  Widget _buildPromoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add 3+\nItems to Unlock\nAI Styling',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  'You have 0 items - add 3 more',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 40),
          ),
        ],
      ),
    );
  }

  /// Shortcut card for main app features
  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Weather Recommendation UI
  Widget _buildWeatherRecommendation() {
    if (_isLoadingWeather) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_currentWeather == null) {
      bool isPermanentlyDenied = _errorMessage?.contains('permanently denied') ?? false;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Column(
            children: [
              Icon(
                isPermanentlyDenied ? Icons.settings_suggest : Icons.location_off,
                color: Colors.grey,
                size: 40,
              ),
              const SizedBox(height: 10),
              Text(
                isPermanentlyDenied
                    ? "Location access is blocked.\nPlease enable it in your phone settings."
                    : "Unable to fetch weather data.\nPlease enable location services.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 10),
              if (isPermanentlyDenied)
                ElevatedButton(
                  onPressed: () => openAppSettings(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Open App Settings"),
                )
              else
                TextButton(
                  onPressed: _fetchWeather,
                  child: const Text("Retry"),
                ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                "Recommended for You",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "${_currentWeather!.temperatureC.round()}°C, ${_currentWeather!.locationName}",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _currentWeather!.clothingRecommendation,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 180,
          child: StreamBuilder<QuerySnapshot>(
            stream: _productService.getRecommendedProducts(_currentWeather!.weatherTags),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    "No items matching current weather.",
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                );
              }

              final products = snapshot.data!.docs;
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final data = products[index].data() as Map<String, dynamic>;
                  final name = data['name'] ?? 'No Name';
                  final imageUrl = data['imageUrl'] ?? '';

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailPage(
                            productId: products[index].id,
                            productData: data,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 130,
                      margin: const EdgeInsets.only(right: 15),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                              child: imageUrl.isNotEmpty
                                  ? Image.network(imageUrl, width: double.infinity, fit: BoxFit.cover)
                                  : Container(color: Colors.grey.shade200, child: const Icon(Icons.image)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
