// Displays planned wardrobe activity in a calendar-oriented layout.
import 'package:flutter/material.dart';
import '../../../core/app_routes.dart';

/// A page that combines a weekly calendar view with outfit planning.
/// Users can see their scheduled outfits and mark them as worn.
class WardrobeCalendarPage extends StatelessWidget {
  const WardrobeCalendarPage({super.key});

  static Color primaryColor = Color(0xFF0D0140);

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
          onPressed: () {},
        ),
        title: Text(
          'Quick Wear',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.shopping_bag_outlined,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () {},
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
        child: Column(
          children: [
            _buildCalendarHeader(context),
            SizedBox(height: 20),
            _buildOutfitSection(context, "Wear This", "Look Saved!"),
            SizedBox(height: 30),
            Padding(
              padding: EdgeInsets.all(25.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.search);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  'Explore More',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "September 2023",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Icon(Icons.calendar_month, color: primaryColor),
            ],
          ),
          SizedBox(height: 20),
          // Mocking a week view
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              bool isSelected = index == 3;
              return Container(
                width: 40,
                padding: EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected
                      ? null
                      : Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                ),
                child: Column(
                  children: [
                    Text(
                      ["S", "M", "T", "W", "T", "F", "S"][index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "${10 + index}",
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildOutfitSection(
    BuildContext context,
    String title,
    String status,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          SizedBox(height: 20),
          Container(
            height: 400,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 10),
                    Text(
                      status,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
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
}
