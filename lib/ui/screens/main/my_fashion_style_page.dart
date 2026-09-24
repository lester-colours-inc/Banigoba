// Builds the My Fashion Style hub: AI makeover, style by occasion, community and events. Reached from the drawer.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/services/weather_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/models/weather.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/app_routes.dart';
import '../../widgets/cart_badge_button.dart';
import '../../widgets/safe_product_image.dart';
import '../events/events_page.dart';
import '../makeover/ai_upload_page.dart';
import '../shop/product_detail_page.dart';
import 'hair_style_page.dart';

/// Makeover, style-by-occasion, community and events hub. No longer the Home
/// tab — Home is the dress-up feed — so it is pushed from the drawer.
class MyFashionStylePage extends StatefulWidget {
  const MyFashionStylePage({super.key});

  @override
  State<MyFashionStylePage> createState() => _MyFashionStylePageState();
}

class _MyFashionStylePageState extends State<MyFashionStylePage> {
  int _selectedTabIndex = 0;
  static Color primaryColor = Color(0xFF0D0140);

  final WeatherService _weatherService = WeatherService();
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
      final weather = await _weatherService.fetchOptionalWeather(latLong);
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
            Icons.arrow_back_ios_new,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.maybePop(context),
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
        actions: [SizedBox(width: 20)],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            _buildTabs(),
            SizedBox(height: 25),
            if (_selectedTabIndex == 2)
              const EventsSection(embedded: true, listHeight: 520)
            else ...[
              _buildFashionStyleLandingActions(),
              SizedBox(height: 25),
              _buildWeatherRecommendation(),
            ],
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
    return FashionLandingTabs(
      selectedIndex: _selectedTabIndex,
      onSelected: (index) => setState(() => _selectedTabIndex = index),
    );
  }

  /// Wires the reusable landing action widget to Firebase and app navigation.
  Widget _buildFashionStyleLandingActions() {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<DocumentSnapshot>(
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

        return FashionStyleLandingActions(
          selectedStylePreference: selectedStyle,
          onStartMakeover: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AiUploadPage()),
            );
          },
          onStyleOccasionSelected: userId == null
              ? null
              : (stylePreference) =>
                    _updateStylePreference(userId, stylePreference),
          onPlanAhead: () => Navigator.pushNamed(context, AppRoutes.planAhead),
          onShoppingIntelligence: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const ShoppingIntelligencePage(),
              ),
            );
          },
        );
      },
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
      ],
    );
  }
}

class FashionLandingTabs extends StatelessWidget {
  const FashionLandingTabs({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const Color _primaryColor = Color(0xFF0D0140);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FashionLandingTabButton(
            title: 'Makeover',
            index: 0,
            selectedIndex: selectedIndex,
            onSelected: onSelected,
          ),
          const SizedBox(width: 15),
          _FashionLandingTabButton(
            title: 'Community',
            index: 1,
            selectedIndex: selectedIndex,
            onSelected: onSelected,
          ),
          const SizedBox(width: 15),
          _FashionLandingTabButton(
            title: 'Events',
            index: 2,
            selectedIndex: selectedIndex,
            onSelected: onSelected,
          ),
        ],
      ),
    );
  }
}

class _FashionLandingTabButton extends StatelessWidget {
  const _FashionLandingTabButton({
    required this.title,
    required this.index,
    required this.selectedIndex,
    required this.onSelected,
  });

  final String title;
  final int index;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      key: Key('fashion_${title.toLowerCase()}_tab'),
      onTap: () => onSelected(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? FashionLandingTabs._primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected
                ? FashionLandingTabs._primaryColor
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
}

class FashionStyleLandingActions extends StatelessWidget {
  const FashionStyleLandingActions({
    super.key,
    required this.onStartMakeover,
    required this.onPlanAhead,
    required this.onShoppingIntelligence,
    this.selectedStylePreference = 'casual',
    this.onStyleOccasionSelected,
  });

  final VoidCallback onStartMakeover;
  final VoidCallback onPlanAhead;
  final VoidCallback onShoppingIntelligence;
  final String selectedStylePreference;
  final ValueChanged<String>? onStyleOccasionSelected;

  static const Color _primaryColor = Color(0xFF0D0140);
  static const List<Map<String, dynamic>> _occasions = [
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildAiMakeoverCard(context),
        const SizedBox(height: 25),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            children: [
              _buildStyleByOccasion(context),
              const SizedBox(height: 25),
              _buildFeatureCard(
                context,
                title: 'Idol Style Match',
                subtitle: 'Discover your global style icon twin',
                icon: Icons.star,
                color: _primaryColor,
                onTap: () {},
              ),
              const SizedBox(height: 15),
              _buildFeatureCard(
                context,
                key: const Key('fashion_plan_ahead_button'),
                title: 'Plan Ahead',
                subtitle: 'Week planner, trip packer & event series',
                icon: Icons.calendar_today,
                color: Colors.pinkAccent,
                onTap: onPlanAhead,
              ),
              const SizedBox(height: 15),
              _buildFeatureCard(
                context,
                key: const Key('fashion_shopping_intelligence_button'),
                title: 'Shopping Intelligence',
                subtitle: 'Smart insights for your wardrobe',
                icon: Icons.shopping_cart_outlined,
                color: Colors.orange,
                onTap: onShoppingIntelligence,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAiMakeoverCard(BuildContext context) {
    return GestureDetector(
      key: const Key('fashion_start_makeover_button'),
      onTap: onStartMakeover,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: _primaryColor,
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
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 35),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleByOccasion(BuildContext context) {
    return Column(
      key: const Key('fashion_style_by_occasion_section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Style By Occasion',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Discover your global style icon twin',
          style: TextStyle(
            color: Theme.of(context).colorScheme.outline,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 15),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _occasions.map((occasion) {
              final value = occasion['value'] as String;

              return _buildOccasionItem(
                context,
                occasion,
                isSelected: value == selectedStylePreference,
                onTap: onStyleOccasionSelected == null
                    ? null
                    : () => onStyleOccasionSelected!(value),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildOccasionItem(
    BuildContext context,
    Map<String, dynamic> occasion, {
    required bool isSelected,
    required VoidCallback? onTap,
  }) {
    final value = occasion['value'] as String;

    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: GestureDetector(
        key: Key('fashion_occasion_$value'),
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: isSelected ? _primaryColor : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                occasion['icon'] as IconData,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.outline,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              occasion['name'] as String,
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

  Widget _buildFeatureCard(
    BuildContext context, {
    Key? key,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(12),
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
}

class ShoppingIntelligencePage extends StatefulWidget {
  const ShoppingIntelligencePage({super.key});

  @override
  State<ShoppingIntelligencePage> createState() =>
      _ShoppingIntelligencePageState();
}

class _ShoppingIntelligencePageState extends State<ShoppingIntelligencePage> {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: const Text(
          'Shopping Intelligence',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<_SmartRecommendation>>(
        future: _loadShoppingIntelligence(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to load recommendations right now.'),
            );
          }

          final recommendations = snapshot.data ?? [];
          if (recommendations.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Add purchases, wardrobe items, or style preferences for smarter item and hair suggestions.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 16,
              childAspectRatio: 0.66,
            ),
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              return _SmartRecommendationTile(
                recommendation: recommendations[index],
              );
            },
          );
        },
      ),
    );
  }

  Future<List<_SmartRecommendation>> _loadShoppingIntelligence(
    String? userId,
  ) async {
    final userSnapshot = userId == null
        ? null
        : await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
    final userData = userSnapshot?.data() ?? const <String, dynamic>{};
    final stylePreference = (userData['stylePreference'] ?? '').toString();
    final hairstylePreferences = _stringList(userData['hairstylePreference']);

    final productReasonsByToken = <String, Set<String>>{};
    final hairReasonsByToken = <String, Set<String>>{};
    void addSignal(
      Map<String, Set<String>> reasonsByToken,
      String token,
      String reason,
    ) {
      final normalized = _normalizeToken(token);
      if (normalized.isEmpty || normalized == 'other') return;
      reasonsByToken.putIfAbsent(normalized, () => <String>{}).add(reason);
    }

    addSignal(
      productReasonsByToken,
      stylePreference,
      'your $stylePreference style preference',
    );
    for (final preference in hairstylePreferences) {
      addSignal(
        hairReasonsByToken,
        preference,
        'your $preference hairstyle preference',
      );
    }

    if (userId != null) {
      final wardrobeSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('wardrobe')
          .limit(40)
          .get();
      for (final doc in wardrobeSnapshot.docs) {
        for (final token in _styleTokens(doc.data())) {
          addSignal(
            productReasonsByToken,
            token,
            'similar tags in your wardrobe',
          );
        }
      }

      final orderSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('customerId', isEqualTo: userId)
          .limit(20)
          .get();
      for (final doc in orderSnapshot.docs) {
        final items = doc.data()['items'];
        if (items is! Iterable) continue;
        for (final item in items.whereType<Map>()) {
          final itemData = Map<String, dynamic>.from(item);
          for (final token in _styleTokens(itemData)) {
            addSignal(productReasonsByToken, token, 'your past purchases');
          }
        }
      }
    }

    final productSnapshot = await FirebaseFirestore.instance
        .collection('products')
        .limit(120)
        .get();
    final hairstyleSnapshot = await FirebaseFirestore.instance
        .collection('hairstyles')
        .limit(120)
        .get();

    final recommendations = <_SmartRecommendation>[
      ...productSnapshot.docs
          .map(
            (doc) => _scoreRecommendation(
              type: _SmartRecommendationType.product,
              data: {...doc.data(), 'id': doc.id},
              reasonsByToken: productReasonsByToken,
            ),
          )
          .whereType<_SmartRecommendation>(),
      ...hairstyleSnapshot.docs
          .map(
            (doc) => _scoreRecommendation(
              type: _SmartRecommendationType.hairstyle,
              data: {...doc.data(), 'id': doc.id},
              reasonsByToken: hairReasonsByToken,
            ),
          )
          .whereType<_SmartRecommendation>(),
    ];

    recommendations.sort((a, b) => b.score.compareTo(a.score));
    return recommendations.take(40).toList();
  }

  _SmartRecommendation? _scoreRecommendation({
    required _SmartRecommendationType type,
    required Map<String, dynamic> data,
    required Map<String, Set<String>> reasonsByToken,
  }) {
    final tokens = _styleTokens(data).map(_normalizeToken).toSet();
    final reasons = <String>{};
    var score = 0;

    for (final token in tokens) {
      final tokenReasons = reasonsByToken[token];
      if (tokenReasons == null) continue;
      score += tokenReasons.length;
      reasons.addAll(tokenReasons);
    }
    if (score == 0) return null;

    return _SmartRecommendation(
      type: type,
      data: data,
      name: _recommendationName(type, data),
      imageUrl: _recommendationImageUrl(data),
      reason: 'Based on ${reasons.take(2).join(' and ')}.',
      score: score,
    );
  }

  List<String> _styleTokens(Map<String, dynamic> data) {
    final tokens = <String>[];
    void add(dynamic value) {
      if (value == null) return;
      if (value is Iterable) {
        for (final item in value) {
          add(item);
        }
        return;
      }
      final text = value.toString().trim();
      if (text.isEmpty) return;
      tokens.add(text);
      tokens.addAll(
        text
            .split(RegExp(r'[^A-Za-z0-9]+'))
            .where((token) => token.trim().length > 2),
      );
    }

    for (final key in [
      'name',
      'category',
      'subcategory',
      'styleTag',
      'style',
      'weatherTags',
      'functionalTags',
      'colours',
      'colour',
      'gender',
      'hairType',
      'texture',
      'styleType',
      'styleTypes',
      'cutTypeGroup',
      'cutType',
      'occasion',
      'occasions',
      'maintenanceLevel',
      'length',
    ]) {
      add(data[key]);
    }
    return tokens;
  }

  List<String> _stringList(dynamic value) {
    if (value is String) return [value];
    if (value is! Iterable) return const [];
    return value
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .toList();
  }

  String _normalizeToken(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  String _recommendationName(
    _SmartRecommendationType type,
    Map<String, dynamic> data,
  ) {
    if (type == _SmartRecommendationType.hairstyle) {
      return (data['name'] ??
              data['cutType'] ??
              data['styleType'] ??
              'Hairstyle')
          .toString();
    }
    return (data['name'] ?? 'Fashion item').toString();
  }

  String _recommendationImageUrl(Map<String, dynamic> data) {
    return (data['imageUrl'] ??
            data['imageURL'] ??
            data['rawImageUrl'] ??
            data['resultImageUrl'] ??
            '')
        .toString();
  }
}

class _SmartRecommendationTile extends StatelessWidget {
  const _SmartRecommendationTile({required this.recommendation});

  final _SmartRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: recommendation.type == _SmartRecommendationType.product
          ? () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ProductDetailPage(productData: recommendation.data),
              ),
            )
          : () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => RecommendedHairTryOnPage(
                  styleName: recommendation.name,
                  styleImageUrl: recommendation.imageUrl,
                ),
              ),
            ),
      borderRadius: BorderRadius.circular(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: colors.surfaceContainerHighest,
                    child: recommendation.imageUrl.isEmpty
                        ? Icon(
                            recommendation.type ==
                                    _SmartRecommendationType.hairstyle
                                ? Icons.face_retouching_natural
                                : Icons.checkroom_outlined,
                            color: Colors.grey,
                            size: 38,
                          )
                        : recommendation.type ==
                              _SmartRecommendationType.product
                        ? SafeProductImage(
                            imageUrl: recommendation.imageUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.contain,
                            iconSize: 38,
                          )
                        : Image.network(
                            recommendation.imageUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => Icon(
                              Icons.broken_image_outlined,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          recommendation.type ==
                              _SmartRecommendationType.hairstyle
                          ? const Color(0xFF0D0140)
                          : Colors.orange,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      recommendation.type == _SmartRecommendationType.hairstyle
                          ? 'Hair'
                          : 'Item',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            recommendation.reason,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 11,
              height: 1.18,
            ),
          ),
        ],
      ),
    );
  }
}

enum _SmartRecommendationType { product, hairstyle }

class _SmartRecommendation {
  const _SmartRecommendation({
    required this.type,
    required this.data,
    required this.name,
    required this.imageUrl,
    required this.reason,
    required this.score,
  });

  final _SmartRecommendationType type;
  final Map<String, dynamic> data;
  final String name;
  final String imageUrl;
  final String reason;
  final int score;
}
