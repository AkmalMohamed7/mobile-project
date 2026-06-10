# 🗺️ Route Tracker App

A Flutter mobile application that tracks walking, jogging, and running routes on an **offline OpenStreetMap** for Fayoum University area.

> Built for Fayoum University – Mobile Application Development Course (2025/2026)

---

## ✨ Features

- 🗺️ **Offline Map** – Works without internet using local OpenStreetMap tiles (Fayoum University area, 10 km²)
- 📍 **Real-time GPS Tracking** – Tracks your location every 5 meters
- 🔵 **Live Route Drawing** – Draws your path as a blue line on the map
- 🏃 **Activity Detection** – Automatically detects activity type based on speed:
  - 🧍 **Standing Still** – under 1 km/h
  - 🚶 **Walking** – 1 to 6 km/h
  - 🏃 **Jogging** – 6 to 10 km/h
  - ⚡ **Running** – above 10 km/h
- 📊 **Live Statistics** – Distance, time, current speed, and average speed
- 💾 **Route History** – Save and view all past routes with map preview
- 🗑️ **Delete Routes** – Remove saved routes with confirmation dialog

---

## 🛠️ Tech Stack

| Technology | Usage |
|------------|-------|
| [Flutter](https://flutter.dev) | Mobile app framework |
| [Dart](https://dart.dev) | Programming language |
| [flutter_map](https://pub.dev/packages/flutter_map) | Offline OpenStreetMap display |
| [geolocator](https://pub.dev/packages/geolocator) | GPS location & speed |
| [latlong2](https://pub.dev/packages/latlong2) | Lat/lng coordinate handling |
| [path_provider](https://pub.dev/packages/path_provider) | Device storage access |
| [archive](https://pub.dev/packages/archive) | ZIP file extraction |

---

## 📁 Project Structure

```
route_tracker/
├── lib/
│   ├── main.dart              # App entry point
│   ├── home_screen.dart       # Main screen (map + tracking + stats)
│   ├── tile_service.dart      # Extract map ZIP on first launch
│   ├── tile_provider.dart     # Load offline map tiles from device
│   ├── route_storage.dart     # Save/load/delete routes as JSON
│   └── history_screen.dart    # Saved routes history screen
├── assets/
│   └── tiles_map.zip          # Offline map tiles (Fayoum University)
├── android/
│   └── app/src/main/
│       └── AndroidManifest.xml
└── pubspec.yaml
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0`
- Android Studio or VS Code
- Android device or emulator (API 21+)

### Installation

**1. Clone the repository**
```bash
git clone https://github.com/YOUR_USERNAME/route_tracker.git
cd route_tracker
```

**2. Install dependencies**
```bash
flutter pub get
```

**3. Add the map tiles**

Place `tiles_map.zip` inside the `assets/` folder.
The ZIP should contain folders structured as:
```
18/
  153512/
    89234.png
17/
  ...
```
*(zoom level / X / Y.png – standard XYZ tile format)*

**4. Run the app**
```bash
flutter run
```

---

## 🗺️ How the Offline Map Works

The map uses the **XYZ tile format** from OpenStreetMap:

- The map area is split into thousands of small **256×256 px PNG images** called tiles
- Each tile is identified by **Z** (zoom level), **X** (column), **Y** (row)
- Tiles are bundled as a single ZIP file in `assets/`
- On **first launch**, the app extracts the ZIP to the device's Documents directory
- On **subsequent launches**, tiles are loaded directly from device storage

```
tiles / 15 / 9876 / 12345.png
         ↑     ↑       ↑
        zoom   X       Y
```

Available zoom levels: **12 – 18** (covers ~10 km² around Fayoum University)

---

## 📊 How Statistics Are Calculated

| Stat | Method |
|------|--------|
| **Distance** | `Geolocator.distanceBetween()` between consecutive GPS points (meters), summed up |
| **Time** | `Timer.periodic()` increments every second |
| **Current Speed** | `pos.speed` from GPS directly (m/s × 3.6 = km/h) |
| **Average Speed** | `(totalDistance / seconds) × 3.6` after stopping |

---

## 🏃 Activity Detection Logic

```dart
String getActivityType(double speedKmh) {
  if (speedKmh < 1.0)  return 'Standing Still';
  if (speedKmh < 6.0)  return 'Walking';
  if (speedKmh < 10.0) return 'Jogging';
  return 'Running';
}
```

---

## 💾 Data Persistence

Routes are saved as **JSON** on the device's Documents directory:

```json
[
  {
    "id": "1716412800000",
    "date": "2025-05-23T10:00:00.000",
    "distanceKm": 0.72,
    "durationSeconds": 58,
    "avgSpeedKmh": 44.9,
    "points": [
      { "lat": 29.3084, "lng": 30.8428 },
      { "lat": 29.3091, "lng": 30.8435 }
    ]
  }
]
```

---

## 🔐 Permissions

The following permissions are required in `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
```

Permissions are also requested at runtime using `Geolocator.requestPermission()`.

---

## 📦 Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_map: ^7.0.0
  geolocator: ^13.0.0
  latlong2: ^0.9.0
  path_provider: ^2.0.0
  archive: ^3.4.10
```

---

## 🧪 Testing Without Being in Fayoum

Use **Lockito** (Android) or the **Emulator Extended Controls → Location** to simulate GPS coordinates:

- **Latitude:** `29.3084`
- **Longitude:** `30.8428`

---

## 📌 Notes

- Map tiles are only extracted once on first launch; subsequent launches load from device storage directly
- If a tile is outside the Fayoum area, a transparent 1×1 px image is returned (no crash)
- Current speed is read from `pos.speed` (GPS chip) for accuracy, not calculated manually
- The history screen shows a non-interactive map preview (`InteractiveFlag.none`) for each saved route
<<<<<<< HEAD


This project is for educational purposes only.
Map data © [OpenStreetMap contributors](https://www.openstreetmap.org/copyright)
=======
>>>>>>> 7ab8b4cd9f65309beb2839f46c48fe9427505eb3
