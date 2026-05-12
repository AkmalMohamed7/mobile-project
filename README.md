# Route Tracker

A Flutter application for tracking outdoor routes with offline maps, distance calculation, speed monitoring, and route history.

## Overview

Route Tracker is a Flutter app designed to track GPS movement, display paths on offline maps, and store trip details locally.

## Features

- Live route tracking with GPS position streaming
- Distance, duration, current speed, and average speed calculation
- Offline map support using a local tile archive (`assets/tiles_map.zip`)
- Route history with embedded map preview and delete option
- Automatic route persistence in the app documents directory
- Simple main screen with start/stop tracking controls

## Architecture

### `lib/main.dart`
- App entry point
- Sets up `MaterialApp` and shows `HomeScreen`

### `lib/home_screen.dart`
- Main route tracking UI
- Initializes offline map tiles via `TileService`
- Uses `Geolocator.getPositionStream` for live GPS updates
- Calculates total distance and average speed
- Saves completed routes with `RouteStorage`

### `lib/history_screen.dart`
- Loads saved routes from local storage
- Displays route summaries and small map previews
- Allows deleting saved routes

### `lib/route_storage.dart`
- Defines the `SavedRoute` data model
- Saves and loads JSON route history from `routes.json`
- Stores route points as latitude/longitude values

### `lib/tile_service.dart`
- Extracts `assets/tiles_map.zip` into the app documents directory
- Caches extracted tiles path so extraction happens only once

### `lib/tile_provider.dart`
- Custom `OfflineTileProvider` for `flutter_map`
- Loads tiles from the extracted local tile directory
- Falls back to a transparent image when a tile file is missing

## Dependencies

- `flutter`
- `flutter_map`
- `geolocator`
- `latlong2`
- `path_provider`
- `archive`
- `cupertino_icons`

## Setup

1. Install Flutter SDK:
   ```bash
   flutter doctor
   ```
2. Navigate to the project directory:
   ```bash
   cd d:/route/route_tracker
   ```
3. Fetch dependencies:
   ```bash
   flutter pub get
   ```

## Run

Run the app on any available device:

```bash
flutter run
```

Or specify a platform:

```bash
flutter run -d windows
flutter run -d chrome
flutter run -d android
flutter run -d ios
```

## Offline Map Tiles

- The app depends on the archive file `assets/tiles_map.zip`.
- On first run, `TileService` extracts the archive to `applicationDocumentsDirectory()/tiles`.
- The archive must contain the tile structure: `z/x/y.png`.
- To replace the map tiles, provide a new `assets/tiles_map.zip` archive and update `pubspec.yaml` if the asset path changes.

## Permissions

- The app requires location permission.
- If GPS is disabled, the app prompts the user to enable it.
- Additional Android or iOS permission configuration may be required for release builds.

## Data Storage

- Routes are saved to `routes.json` in the app documents directory.
- Each route includes:
  - `id`
  - `date`
  - `distanceKm`
  - `durationSeconds`
  - `avgSpeedKmh`
  - `points`
- Saved routes can be deleted from the history screen.

## Screens

### Home Screen
- Main map display
- Draws route polyline on the map
- Shows route stats in a bottom panel
- Start/stop tracking button

### History Screen
- List of saved routes
- Small offline map preview for each route
- Route details such as distance, time, and speed
- Delete button for each route

## Known Issues

- `lib/history_screen.dart`: unused import of `package:latlong2/latlong.dart`
- `lib/history_screen.dart`: `BuildContext` is used after an async gap in `_deleteRoute`
- `lib/home_screen.dart`: uses `.withOpacity()` which may be deprecated in some Flutter versions
- No route export or sharing support currently available

## Future Improvements

- Add route export to GPX or KML
- Add more detail in the history screen
- Improve location permission handling
- Add support for online map switching
- Enhance UI/UX for history and tracking controls

## License

- This project is intended for private use and is not published to pub.dev.
- An open-source license can be added later if desired.
