import 'package:flutter/material.dart';
import '../../../data/services/weather_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/models/weather.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/app_routes.dart';
import '../wardrobe/wardrobe_calendar_page.dart';

/// Page displaying daily dress up recommendations and user posts
class DailyDressUpPage extends StatefulWidget {
  const DailyDressUpPage({super.key});

  @override
  State<DailyDressUpPage> createState() => _DailyDressUpPageState();
}

class _DailyDressUpPageState extends State<DailyDressUpPage> {
  int _selectedTabIndex = 0;
  static const Color primaryColor = Color(0xFF0D0140);

  final WeatherService _weatherService = WeatherService();
  Weather? _currentWeather;
  bool _isLoadingWeather = true;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  /// Fetches weather data using the current device location
  Future<void> _fetchWeather() async {
    // Check permissions before attempting to fetch weather
    var status = await Permission.location.status;
    
    if (status.isPermanentlyDenied || status.isRestricted) {
      // Silently fail - location permissions permanently denied
      if (!mounted) return;
      setState(() {
        _isLoadingWeather = false;
      });
      return;
    }

    setState(() {
      _isLoadingWeather = true;
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
        });
      }
      debugPrint("Weather fetch error: $e");
    }
  }

  /// Handles location permission and returns the current position
  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

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

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
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
                'My Daily Dress Up',
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
            const SizedBox(height: 20),
            _buildStatusHeader(),
            const SizedBox(height: 25),
            // Mock items representing user posts/recommendations
            _buildDressUpItem(
              title: "Warm & Cozy",
              subtitle: "Vibrant & Bold",
              imageUrl: "https://images.unsplash.com/photo-1591047139829-d91aecb6caea?q=80&w=1000&auto=format&fit=crop",
              bgColor: const Color(0xFFE1BEE7),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WardrobeCalendarPage()),
          );
        },
      ),
    );
  }

  void _showQuickWearDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const Text(
              "Quick Wear",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildQuickWearItem("Outerwear", "https://images.unsplash.com/photo-1591047139829-d91aecb6caea?q=80&w=200"),
            _buildQuickWearItem("Tops", "https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?q=80&w=200"),
            _buildQuickWearItem("Bottoms", "https://images.unsplash.com/photo-1541099649105-f69ad21f3246?q=80&w=200"),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text("Save Look", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickWearItem(String label, String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(url, width: 60, height: 60, fit: BoxFit.cover),
          ),
          const SizedBox(width: 15),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
    );
  }

  /// Helper to build consistent action buttons in the AppBar
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

  /// Horizontal tab selector for filtering content
  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _tabButton("Mine", 0),
          const SizedBox(width: 15),
          _tabButton("My Friends", 1),
          const SizedBox(width: 15),
          _tabButton("Community", 2),
        ],
      ),
    );
  }

  /// Individual tab button with selection state
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

  /// Header showing current weather and next calendar event
  Widget _buildStatusHeader() {
    if (_isLoadingWeather) {
      return Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFC5CAE9),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      );
    }

    String conditionText = _currentWeather?.condition ?? "Weather Unavailable";
    String tempText = _currentWeather != null ? "${_currentWeather!.temperatureC.round()}°C" : "";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFC5CAE9),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_outlined, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _currentWeather != null ? "$conditionText | $tempText" : conditionText,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text("|", style: TextStyle(color: Colors.white54, fontSize: 20)),
          ),
          const Icon(Icons.calendar_today_outlined, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          const Text(
            "11 AM Meeting",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  /// Build a single dress-up post/item
  Widget _buildDressUpItem({
    required String title,
    required String subtitle,
    required String imageUrl,
    required Color bgColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orange, width: 2),
              ),
              child: const CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage('https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(Icons.verified, color: Colors.indigo, size: 16),
                    ],
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Text(
              "Today",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  imageUrl,
                  height: double.infinity,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const Positioned(
                top: 15,
                right: 15,
                child: Icon(Icons.more_vert, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            _buildAction(Icons.shortcut_outlined, "Try On", onTap: () {
              Navigator.pushNamed(context, AppRoutes.camera);
            }),
            const SizedBox(width: 20),
            _buildAction(Icons.chat_bubble_outline, "Comment"),
            const SizedBox(width: 20),
            _buildAction(Icons.share_outlined, "Share"),
          ],
        ),
      ],
    );
  }

  /// Small action button with icon and text below a post
  Widget _buildAction(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
