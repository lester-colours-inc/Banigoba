// Builds the primary dashboard with weather recommendations, products, and makeover entry points.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/services/weather_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/product_service.dart';
import '../../../data/models/weather.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/app_routes.dart';
import '../makeover/ai_upload_page.dart';
import '../shop/product_detail_page.dart';

/// The main landing page after login, providing quick access to features
/// Primary landing screen for users, featuring AI makeover options,
/// weather-based recommendations, and style categories.
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
    // Check for location permissions and fetch weather data after a brief delay
    // to allow the UI to settle.
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _checkPermissionAndFetchWeather();
    });
  }

  /// Evaluates location permission status and handles user interaction for permission requests
  Future<void> _checkPermissionAndFetchWeather() async {
    var status = await Geolocator.checkPermission();

    if (status == LocationPermission.deniedForever) {
      setState(() {
        _isLoadingWeather = false;
        _errorMessage = 'Location permissions are permanently denied';
      });
      return;
    }

    if (status == LocationPermission.denied) {
      if (mounted) {
        bool? shouldRequest = await _showLocationPermissionDialog();
        if (shouldRequest == true) {
          status = await Geolocator.requestPermission();
          if (status == LocationPermission.whileInUse || status == LocationPermission.always) {
            _fetchWeather();
          } else if (status == LocationPermission.deniedForever) {
            setState(() {
              _isLoadingWeather = false;
              _errorMessage = 'Location permissions are permanently denied';
            });
          } else {
            setState(() {
              _isLoadingWeather = false;
              _errorMessage = 'Location permissions are denied';
            });
          }
        } else {
          setState(() {
            _isLoadingWeather = false;
            _errorMessage = 'Location permissions are denied';
          });
        }
      }
    } else {
      _fetchWeather();
    }
  }

  /// Displays an in-app dialog explaining why location access is needed
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
                  style: const TextStyle(fontSize: 18),
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

  /// Core logic to fetch weather from service using device coordinates
  Future<void> _fetchWeather() async {
    setState(() {
      _isLoadingWeather = true;
      _errorMessage = null;
    });
    try {
      // Early check for permanently denied permissions before attempting fetch
      final permStatus = await Geolocator.checkPermission();
      if (permStatus == LocationPermission.deniedForever) {
        setState(() {
          _isLoadingWeather = false;
          _errorMessage = 'Location permissions are permanently denied';
        });
        return;
      }

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

  /// Verifies location services and permissions, returning current Position
  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return Future.error('Location services are disabled.');
    }

    var status = await Geolocator.checkPermission();
    if (status == LocationPermission.denied) {
      status = await Geolocator.requestPermission();
      if (status == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (status == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

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
        title: Row(
          children: [
            const Expanded(
              child: Text(
                'My Fashion Style',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            _buildAppBarAction(Icons.shopping_bag_outlined, () => Navigator.pushNamed(context, AppRoutes.cart), hasNotification: true),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.black),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildTabs(),
            const SizedBox(height: 25),
            // AI Makeover Card
            _buildAiMakeoverCard(),
            const SizedBox(height: 25),
            // Main Content Area (Light Background)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5), // Light peach/pink background
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                children: [
                  // Style By Occasion
                  _buildStyleByOccasion(),
                  const SizedBox(height: 25),
                  // Feature shortcuts
                  _buildFeatureCard(
                    title: "Idol Style Match",
                    subtitle: "Discover your global style icon twin",
                    icon: Icons.star,
                    color: primaryColor,
                    onTap: () {},
                  ),
                  const SizedBox(height: 15),
                  _buildFeatureCard(
                    title: "Plan Ahead",
                    subtitle: "Week planner, trip packer & event series",
                    icon: Icons.calendar_today,
                    color: Colors.pinkAccent,
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.planAhead);
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildFeatureCard(
                    title: "Shopping Intelligence",
                    subtitle: "Smart insights for your wardrobe",
                    icon: Icons.shopping_cart_outlined,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.search);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            // Weather Recommendation Section (Moved outside main container)
            _buildWeatherRecommendation(),
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
          StreamBuilder<int>(
            stream: NotificationService().getUnreadCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              if (unreadCount == 0) return const SizedBox.shrink();
              
              return Positioned(
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
              );
            },
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

  /// Tab button with pill-shaped design
  Widget _tabButton(String title, int index) {
    bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade400,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// AI Makeover card matching the design
  Widget _buildAiMakeoverCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AiUploadPage()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Start Your\nAI Makeover',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Upload a full-body photo or\nselfie to begin.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 35),
            ),
          ],
        ),
      ),
    );
  }

  /// Style By Occasion horizontal list
  Widget _buildStyleByOccasion() {
    final List<Map<String, dynamic>> occasions = [
      {'name': 'Casual', 'value': 'casual', 'icon': Icons.check_circle_outline},
      {'name': 'Afro-Chic', 'value': 'afrochic', 'icon': Icons.eco_outlined},
      {'name': 'Corporate', 'value': 'corporate', 'icon': Icons.business_center_outlined},
      {'name': 'Street wear', 'value': 'streetwear', 'icon': Icons.style_outlined},
      {'name': 'Glamour', 'value': 'glamour', 'icon': Icons.diamond_outlined},
    ];
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Style By Occasion",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          "Discover your global style icon twin",
          style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
        ),
        const SizedBox(height: 15),
        StreamBuilder<DocumentSnapshot>(
          stream: userId == null ? null : FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
          builder: (context, snapshot) {
            final userData = snapshot.data?.data() as Map<String, dynamic>?;
            final selectedStyle = (userData?['stylePreference'] ?? 'casual').toString();
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: occasions.map((occ) {
                  return _buildOccasionItem(
                    occ,
                    isSelected: occ['value'] == selectedStyle,
                    onTap: userId == null ? null : () => _updateStylePreference(userId, occ['value']),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _updateStylePreference(String userId, String stylePreference) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'stylePreference': stylePreference,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Widget _buildOccasionItem(Map<String, dynamic> occasion, {required bool isSelected, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                occasion['icon'],
                color: isSelected ? Colors.white : Colors.grey.shade400,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              occasion['name'],
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.black : Colors.grey.shade500,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shortcut card for main app features
  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                  onPressed: () => Geolocator.openAppSettings(),
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
        _buildMatchingProductRecommendations(),
      ],
    );
  }

  Widget _buildMatchingProductRecommendations() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || _currentWeather == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final stylePreference = (userData?['stylePreference'] ?? 'casual').toString();

        return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
          stream: _productService.getRecommendedProductDocs(
            weatherTags: _currentWeather!.weatherTags,
            stylePreference: stylePreference,
          ),
          builder: (context, productSnapshot) {
            if (productSnapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
            }

            final products = productSnapshot.data ?? [];
            if (products.isEmpty) {
              return Text(
                "No ${_formatStyleLabel(stylePreference)} pieces match today's weather yet.",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              );
            }

            return SizedBox(
              height: 145,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: products.length.clamp(0, 8).toInt(),
                separatorBuilder: (_, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final doc = products[index];
                  final data = Map<String, dynamic>.from(doc.data());
                  data['id'] = doc.id;
                  return _buildRecommendedProductCard(data);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecommendedProductCard(Map<String, dynamic> product) {
    final imageUrl = product['rawImageUrl'] ?? product['imageUrl'] ?? product['imageURL'] ?? '';
    final name = product['name'] ?? 'Product';
    final style = product['styleTag'] ?? product['style'] ?? 'casual';

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(productData: product))),
      child: SizedBox(
        width: 105,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 105,
              height: 95,
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(14)),
              clipBehavior: Clip.antiAlias,
              child: imageUrl.toString().startsWith('http')
                  ? Image.network(imageUrl, fit: BoxFit.cover)
                  : const Icon(Icons.image, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text(_formatStyleLabel(style.toString()), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  String _formatStyleLabel(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
