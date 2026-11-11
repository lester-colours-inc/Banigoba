// Style selection: optional weather and the next event as context, and the
// way on to Try On.
import 'dart:typed_data';

import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import 'package:banigoba/app/routes/app_routes.dart';
import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/events/services/upcoming_event_service.dart';
import 'package:banigoba/modules/home/models/weather.dart';
import 'package:banigoba/modules/home/services/weather_service.dart';
import 'package:banigoba/modules/makeover/views/avatar_try_on_page.dart';
import 'package:banigoba/modules/makeover/widgets/try_on_product_picker.dart';
import 'package:banigoba/modules/wardrobe/views/wardrobe_calendar_page.dart';

class StyleSelectionController extends GetxController {
  StyleSelectionController({
    this.imageBytes,
    this.imageUrl,
    this.plannedDate,
    this.eventId,
    this.eventName,
    WeatherService? weatherService,
    UpcomingEventService? upcomingEventService,
  }) : _weatherService = weatherService ?? WeatherService(),
       _upcomingEventService = upcomingEventService ?? UpcomingEventService();

  final Uint8List? imageBytes;
  final String? imageUrl;
  final DateTime? plannedDate;
  final String? eventId;
  final String? eventName;
  final WeatherService _weatherService;
  final UpcomingEventService _upcomingEventService;

  final Rxn<Weather> weather = Rxn<Weather>();
  final Rxn<UpcomingEvent> upcomingEvent = Rxn<UpcomingEvent>();
  final RxBool isLoadingWeather = true.obs;
  final RxBool isLoadingEvent = true.obs;

  String get weatherLabel {
    if (isLoadingWeather.value) return 'Loading weather...';
    final current = weather.value;
    if (current == null) return 'Weather unavailable';
    return '${current.condition} • ${current.temperatureC.round()}°C • '
        '${current.locationName}';
  }

  String get eventLabel {
    if (isLoadingEvent.value) return 'Loading event...';
    return upcomingEvent.value?.shortLabel ?? eventName ?? 'No upcoming event';
  }

  @override
  void onInit() {
    super.onInit();
    _fetchWeather();
    _loadUpcomingEvent();
  }

  Future<void> _loadUpcomingEvent() async {
    final userId = AppAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) {
      isLoadingEvent.value = false;
      return;
    }
    try {
      final event = await _upcomingEventService.getClosestEvent(userId);
      if (isClosed) return;
      upcomingEvent.value = event;
    } catch (_) {
      // The event is optional context.
    }
    if (!isClosed) isLoadingEvent.value = false;
  }

  Future<void> _fetchWeather() async {
    // Check permissions before attempting to fetch weather
    final status = await Geolocator.checkPermission();
    if (status == LocationPermission.deniedForever) {
      // Silently fail - location permissions permanently denied
      if (!isClosed) isLoadingWeather.value = false;
      return;
    }
    try {
      final position = await _determinePosition();
      final latLong = '${position.latitude},${position.longitude}';
      final fetched = await _weatherService.fetchOptionalWeather(latLong);
      if (isClosed) return;
      weather.value = fetched;
    } catch (_) {
      // Silently handle errors - weather is optional for style selection
    }
    if (!isClosed) isLoadingWeather.value = false;
  }

  /// Verifies location services and permissions, returning current Position
  Future<Position> _determinePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
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

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        distanceFilter: 1000,
      ),
    );
  }

  Future<void> openTryOn() async {
    final context = Get.context;
    if (context == null) return;
    final products = await showTryOnProductPicker(context);
    if (isClosed || products == null || products.isEmpty) return;

    await Get.to<void>(
      () => const AvatarTryOnPage(),
      arguments: {
        'products': products,
        'category': (products.first['category'] ?? 'auto').toString(),
        if (plannedDate != null) 'plannedDate': plannedDate!.toIso8601String(),
        if (eventId != null) 'eventId': eventId,
        if (eventName != null) 'eventName': eventName,
      },
    );
  }

  void openQuickWear() => Get.to<void>(() => const WardrobeCalendarPage());

  void openShops() => Get.toNamed<void>(AppRoutes.shops);
}
