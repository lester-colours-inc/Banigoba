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
import '../../widgets/cart_badge_button.dart';
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
  static Color primaryColor = Color(0xFF0D0140);

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
    Future.delayed(Duration(milliseconds: 500), () {
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
          if (status == LocationPermission.whileInUse ||
              status == LocationPermission.always) {
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.location_on, color: primaryColor),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Local Recommendations',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Text(
            'To suggest the perfect fashion for your current day, we need access to your location for real-time weather updates.',
            style: TextStyle(fontSize: 15, height: 1.4),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Not Now',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: Text(
                  'Allow Access',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.low,
        distanceFilter: 1000,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.menu,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'My Fashion Style',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            _buildAppBarAction(
              Icons.shopping_bag_outlined,
              () => Navigator.pushNamed(context, AppRoutes.cart),
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          SizedBox(width: 20),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            _buildTabs(),
            SizedBox(height: 25),
            // AI Makeover Card
            _buildAiMakeoverCard(),
            SizedBox(height: 25),
            // Main Content Area (Light Background)
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                children: [
                  // Style By Occasion
                  _buildStyleByOccasion(),
                  SizedBox(height: 25),
                  // Feature shortcuts
                  _buildFeatureCard(
                    title: "Idol Style Match",
                    subtitle: "Discover your global style icon twin",
                    icon: Icons.star,
                    color: primaryColor,
                    onTap: () {},
                  ),
                  SizedBox(height: 15),
                  _buildFeatureCard(
                    title: "Plan Ahead",
                    subtitle: "Week planner, trip packer & event series",
                    icon: Icons.calendar_today,
                    color: Colors.pinkAccent,
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.planAhead);
                    },
                  ),
                  SizedBox(height: 15),
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
            SizedBox(height: 25),
            // Weather Recommendation Section (Moved outside main container)
            _buildWeatherRecommendation(),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /// AppBar action buttons helper
  Widget _buildAppBarAction(
    IconData icon,
    VoidCallback onTap, {
    bool hasNotification = false,
  }) {
    if (icon == Icons.shopping_bag_outlined) {
      return CartBadgeButton(
        onPressed: onTap,
        color: Theme.of(context).colorScheme.onSurface,
      );
    }

    return Stack(
      children: [
        IconButton(
          icon: Icon(
            icon,
            color: Theme.of(context).colorScheme.onSurface,
            size: 28,
          ),
          onPressed: onTap,
        ),
        if (hasNotification)
          StreamBuilder<int>(
            stream: NotificationService().getUnreadCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              if (unreadCount == 0) return SizedBox.shrink();

              return Positioned(
                right: 5,
                top: 5,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
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
          SizedBox(width: 15),
          _tabButton("Community", 1),
          SizedBox(width: 15),
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
        padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.outline,
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
          MaterialPageRoute(builder: (context) => AiUploadPage()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(25),
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
                  Text(
                    'Start Your\nAI Makeover',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 10),
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
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(Icons.add, color: Colors.white, size: 35),
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
      {
        'name': 'Corporate',
        'value': 'corporate',
        'icon': Icons.business_center_outlined,
      },
      {
        'name': 'Street wear',
        'value': 'streetwear',
        'icon': Icons.style_outlined,
      },
      {'name': 'Glamour', 'value': 'glamour', 'icon': Icons.diamond_outlined},
    ];
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Style By Occasion",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text(
          "Discover your global style icon twin",
          style: TextStyle(
            color: Theme.of(context).colorScheme.outline,
            fontSize: 11,
          ),
        ),
        SizedBox(height: 15),
        StreamBuilder<DocumentSnapshot>(
          stream: userId == null
              ? null
              : FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .snapshots(),
          builder: (context, snapshot) {
            final userData = snapshot.data?.data() as Map<String, dynamic>?;
            final selectedStyle = (userData?['stylePreference'] ?? 'casual')
                .toString();
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: occasions.map((occ) {
                  return _buildOccasionItem(
                    occ,
                    isSelected: occ['value'] == selectedStyle,
                    onTap: userId == null
                        ? null
                        : () => _updateStylePreference(userId, occ['value']),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _updateStylePreference(
    String userId,
    String stylePreference,
  ) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'stylePreference': stylePreference,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Widget _buildOccasionItem(
    Map<String, dynamic> occasion, {
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(right: 15),
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
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.outline,
                size: 24,
              ),
            ),
            SizedBox(height: 8),
            Text(
              occasion['name'],
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? Colors.black
                    : Theme.of(context).colorScheme.onSurfaceVariant,
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
        margin: EdgeInsets.only(bottom: 15),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
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
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
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

  Widget _buildWeatherRecommendation() {
    if (_isLoadingWeather) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(Icons.location_off_outlined, color: primaryColor),
            SizedBox(height: 10),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            SizedBox(height: 12),
            TextButton.icon(
              onPressed: _checkPermissionAndFetchWeather,
              icon: Icon(Icons.refresh),
              label: Text('Try again'),
            ),
          ],
        ),
      );
    }

    final weather = _currentWeather;
    if (weather == null) {
      return SizedBox.shrink();
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Image.network(
                weather.iconUrl,
                width: 58,
                height: 58,
                errorBuilder: (_, _, _) =>
                    Icon(Icons.cloud_outlined, color: Colors.white, size: 46),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${weather.temperatureC.round()}°C in ${weather.locationName}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${weather.condition}. ${weather.clothingRecommendation}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 18),
        Text(
          'Recommended for today',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: userId == null
              ? null
              : FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .snapshots(),
          builder: (context, userSnapshot) {
            final stylePreference = userSnapshot.data
                ?.data()?['stylePreference']
                ?.toString();
            return StreamBuilder<
              List<QueryDocumentSnapshot<Map<String, dynamic>>>
            >(
              stream: _productService.getRecommendedProductDocs(
                weatherTags: weather.weatherTags,
                stylePreference: stylePreference,
              ),
              builder: (context, productSnapshot) {
                if (productSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(color: primaryColor),
                    ),
                  );
                }

                if (productSnapshot.hasError) {
                  return Text(
                    'Unable to load recommendations right now.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  );
                }

                final products = productSnapshot.data ?? [];
                if (products.isEmpty) {
                  return Text(
                    'No matching items yet. Try another style or check back later.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  );
                }

                return SizedBox(
                  height: 190,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: products.length,
                    separatorBuilder: (_, _) => SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final product = products[index].data();
                      final imageUrl =
                          (product['imageUrl'] ?? product['imageURL'] ?? '')
                              .toString();
                      final name = (product['name'] ?? 'Fashion item')
                          .toString();
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductDetailPage(productData: product),
                          ),
                        ),
                        child: SizedBox(
                          width: 135,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  width: 135,
                                  height: 145,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  child: imageUrl.isEmpty
                                      ? Icon(
                                          Icons.checkroom_outlined,
                                          color: Colors.grey,
                                          size: 38,
                                        )
                                      : Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => Icon(
                                            Icons.broken_image_outlined,
                                            color: Colors.grey,
                                          ),
                                        ),
                                ),
                              ),
                              SizedBox(height: 7),
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
