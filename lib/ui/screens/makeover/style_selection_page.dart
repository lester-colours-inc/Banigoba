// Lets users choose styling options and adds optional weather context to the makeover.
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../data/models/weather.dart';
import '../../../data/services/weather_service.dart';
import '../../widgets/try_on_product_picker.dart';
import 'avatar_try_on_page.dart';

class StyleSelectionPage extends StatefulWidget {
  final Uint8List? imageBytes;
  final String? imageUrl;

  const StyleSelectionPage({super.key, this.imageBytes, this.imageUrl})
    : assert(
        imageBytes != null || imageUrl != null,
        'Either imageBytes or imageUrl must be provided.',
      );

  static Color primaryColor = Color(0xFF0D0140);

  @override
  State<StyleSelectionPage> createState() => _StyleSelectionPageState();
}

class _StyleSelectionPageState extends State<StyleSelectionPage> {
  final WeatherService _weatherService = WeatherService();
  Weather? _currentWeather;
  bool _isLoadingWeather = true;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    // Check permissions before attempting to fetch weather
    final status = await Geolocator.checkPermission();

    if (status == LocationPermission.deniedForever) {
      // Silently fail - location permissions permanently denied
      if (!mounted) return;
      setState(() {
        _isLoadingWeather = false;
      });
      return;
    }

    try {
      final Position position = await _determinePosition();
      final String latLong = "${position.latitude},${position.longitude}";
      final weather = await _weatherService.fetchWeather(latLong);
      if (!mounted) return;
      setState(() {
        _currentWeather = weather;
        _isLoadingWeather = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingWeather = false;
      });
      // Silently handle errors - weather is optional for style selection
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

  Future<void> _openTryOn() async {
    final products = await showTryOnProductPicker(context);
    if (!mounted || products == null || products.isEmpty) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AvatarTryOnPage(),
        settings: RouteSettings(
          arguments: {
            'products': products,
            'garmentImageUrl': _productImageUrl(products.first),
            'garmentName': products
                .map((product) => (product['name'] ?? 'Clothing').toString())
                .join(' + '),
            'category': (products.first['category'] ?? 'auto').toString(),
          },
        ),
      ),
    );
  }

  String _productImageUrl(Map<String, dynamic> product) {
    for (final field in const [
      'rawImageUrl',
      'imageUrl',
      'imageURL',
      'processedImageUrl',
    ]) {
      final value = product[field];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return '';
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
        title: Text(
          'My Daily Dress Up',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  Icons.shopping_bag_outlined,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () {},
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          Container(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
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
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            _buildTabBar(),
            SizedBox(height: 20),
            _buildHeroCard(context),
            SizedBox(height: 20),
            _buildInfoRow(),
            SizedBox(height: 20),
            _buildActionButtons(context),
            SizedBox(height: 25),
            _buildSectionTile(
              icon: Icons.lightbulb_outline,
              title: 'Trending Styles',
              subtitle: 'Discover your global style icon twin',
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerLow,
            ),
            SizedBox(height: 12),
            _buildSectionTile(
              icon: Icons.shopping_bag_outlined,
              title: 'Designer Pick',
              subtitle: 'Discover your global style icon twin',
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerLow,
            ),
            SizedBox(height: 12),
            _buildSectionTile(
              icon: Icons.storefront_outlined,
              title: 'My Closet',
              subtitle: 'Discover your global style icon twin',
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerLow,
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _tabButton('Mine', 0),
          SizedBox(width: 12),
          _tabButton('My Friends', 1),
          SizedBox(width: 12),
          _tabButton('Community', 2),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? StyleSelectionPage.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected
                ? StyleSelectionPage.primaryColor
                : Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(30),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  widget.imageBytes != null
                      ? Image.memory(
                          widget.imageBytes!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                        )
                      : Image.network(
                          widget.imageUrl!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 64,
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                          ),
                        ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: ElevatedButton.icon(
                      onPressed: _openTryOn,
                      icon: Icon(Icons.checkroom, size: 18),
                      label: Text('Try On'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: StyleSelectionPage.primaryColor,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow() {
    final weatherLabel = _isLoadingWeather
        ? 'Loading weather...'
        : _currentWeather != null
        ? '${_currentWeather!.condition} · ${_currentWeather!.temperatureC.round()}°C'
        : 'Weather unavailable';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _infoChip(Icons.cloud_outlined, weatherLabel),
        _infoChip(Icons.calendar_today_outlined, '11 AM Meeting'),
        _infoChip(Icons.location_on_outlined, 'Ankara & Gold Accents'),
      ],
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: StyleSelectionPage.primaryColor, size: 18),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final buttons = ['Quick Wear', 'Customize', 'Try On', 'Find Shops'];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: buttons.map((label) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 68) / 2,
          child: ElevatedButton(
            onPressed: label == 'Try On' ? _openTryOn : () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: StyleSelectionPage.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color backgroundColor,
  }) {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(0xFFDED6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: StyleSelectionPage.primaryColor, size: 22),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
        ],
      ),
    );
  }
}
