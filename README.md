# Banigoba - Virtual Wardrobe & AR Try-On

Banigoba is a modern Flutter-based social wardrobe platform that allows users to manage their daily dress-up, discover community trends, and try on accessories using artificial intelligence (AI).

## 🚀 Key Features

### 👗 Wardrobe Management
- **Personal Wardrobe**: Upload and organize your clothing items with details like category, subcategory, colour, and gender.
- ** Firebase Storage**: Efficient image handling.
- **Privacy Controls**: Set items as 'private' or 'public'. Public items are visible to friends and the community.
- **Favorites**: Add items from the community or search results to your own wardrobe.

### AI Try-On
- **FASHN AI API**: overlays product on stored avatar image, one garment per call.
- **Gemini (Nano Banana)**: alternative engine that dresses the avatar in every
  selected item in a single call. Generate with both to compare results side by
  side on the Avatar Try-On page.

Both engines read their keys from `--dart-define` (see `dart_defines.example.json`):

```bash
flutter run --dart-define-from-file=dart_defines.json
```

### 🤝 Social Discovery
- **Community Feed**: Explore public wardrobes from users across the platform.
- **Follow System**: Follow friends and other users to see their latest style updates.
- **Detailed Profiles**: Clickable accounts to view user stats (followers/following) and their public wardrobe collections. Profiles are private by default; you must be following a user to see their wardrobe and follower lists.
- **Notification Center**: Real-time notifications for follow requests, accepted requests, and when friends post new items.
- **Dynamic Interaction**: Clickable follower/following lists to navigate through the social network.

### 🔍 Search & Filters
- **Smart Search**: Search for products or users.
- **Granular Filters**: Filter items by Category, Subcategory, Gender, and Colour.

## 🛠 Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend/Auth**: Firebase Authentication & Cloud Firestore
- **Storage**: Firebase Storage
- **AI/AR**: Google ML Kit (Face Detection) & Camera API
- **Navigation**: Structured Routing system

## 📂 Project Structure

```
lib/
├── main.dart             # App entry point & Theme configuration
├── navigation/           # AppRoutes & AuthGate logic
├── screens/              # All UI screens (Wardrobe, Search, Profile, AR Camera, etc.)
├── services/             # Business logic (Firebase, Supabase, Face Detection)
├── widgets/              # Reusable UI components (AppDrawer, etc.)
└── firebase_options.dart # Firebase configuration
```

## ⚙️ Setup & Installation

1.  **Firebase Setup**:
    - Create a Firebase project and enable Auth (Email/Password) and Firestore.
    - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS).
      
2.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Run the App**:
    ```bash
    flutter run
    ```

---
Developed as a comprehensive solution for digital fashion management.
