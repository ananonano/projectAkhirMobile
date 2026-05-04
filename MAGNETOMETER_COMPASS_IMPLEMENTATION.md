# Magnetometer/Compass Implementation for Maps

## Overview
Menambahkan sensor magnetometer/compass untuk menampilkan arah hadap user di maps dengan panah segitiga yang berputar mengikuti arah, seperti Google Maps.

## Changes Made

### 1. Added Dependency
**File**: `pubspec.yaml`

```yaml
#Sensor
sensors_plus: ^7.0.0
flutter_compass: ^0.8.0
```

### 2. Updated Maps Screen
**File**: `lib/screens/maps_screen.dart`

#### A. Added Imports
```dart
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:async';
import 'dart:math' as math;
```

#### B. Added State Variables
```dart
// User location
LatLng? _userLocation;
bool _isLoadingLocation = false;
double? _userHeading; // Compass heading in degrees
StreamSubscription<CompassEvent>? _compassSubscription;
```

#### C. Updated initState()
```dart
@override
void initState() {
  super.initState();
  _loadLapangan();
  _getUserLocation();
  _startCompassListener(); // NEW
}
```

#### D. Updated dispose()
```dart
@override
void dispose() {
  _searchController.dispose();
  _mapController.dispose();
  _compassSubscription?.cancel(); // NEW
  super.dispose();
}
```

#### E. Added Compass Listener Method
```dart
void _startCompassListener() {
  _compassSubscription = FlutterCompass.events?.listen((CompassEvent event) {
    if (mounted && event.heading != null) {
      setState(() {
        _userHeading = event.heading;
      });
    }
  });
}
```

#### F. Updated User Location Marker (Replace existing marker code)
Find this section in the `build()` method around line 505-543:

```dart
// User Location Marker
if (_userLocation != null)
  MarkerLayer(
    markers: [
      Marker(
        point: _userLocation!,
        width: 60,
        height: 60,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.withOpacity(0.3),
          ),
          child: Center(
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue,
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  ),
```

**Replace with:**

```dart
// User Location Marker with Compass Heading
if (_userLocation != null)
  MarkerLayer(
    markers: [
      Marker(
        point: _userLocation!,
        width: 80,
        height: 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer circle (accuracy indicator)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4285F4).withOpacity(0.15),
              ),
            ),
            // Direction arrow (rotates with compass)
            if (_userHeading != null)
              Transform.rotate(
                angle: (_userHeading! * math.pi / 180),
                child: CustomPaint(
                  size: const Size(40, 40),
                  painter: _DirectionArrowPainter(),
                ),
              ),
            // Center dot (always visible)
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4285F4),
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  ),
```

#### G. Add Custom Painter Class (at the end of file, before closing brace)
Add this class at the very end of the file, after the `_buildMyLocationButton()` method:

```dart
}

// Custom Painter for Direction Arrow
class _DirectionArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Draw triangle arrow pointing up (north)
    // Top point
    path.moveTo(size.width / 2, 0);
    // Bottom left
    path.lineTo(size.width / 2 - 8, size.height / 2 + 4);
    // Bottom right
    path.lineTo(size.width / 2 + 8, size.height / 2 + 4);
    // Close path
    path.close();

    // Draw shadow
    canvas.drawShadow(path, Colors.black.withOpacity(0.3), 3.0, false);
    
    // Draw arrow
    canvas.drawPath(path, paint);
    
    // Draw white border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

## How It Works

### 1. Compass Sensor
- `flutter_compass` package provides real-time compass heading data
- Heading is in degrees (0-360°):
  - 0° = North
  - 90° = East
  - 180° = South
  - 270° = West

### 2. Visual Components
- **Outer Circle**: Light blue circle showing accuracy area
- **Direction Arrow**: Blue triangle that rotates with compass heading
- **Center Dot**: Blue dot showing exact user location

### 3. Rotation
- Arrow rotates using `Transform.rotate()`
- Angle converted from degrees to radians: `heading * π / 180`
- Arrow always points in the direction user is facing

### 4. Custom Painter
- Draws triangle arrow shape
- Adds shadow for depth
- Adds white border for visibility

## Testing

1. **Install dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run on physical device** (compass doesn't work on emulator):
   ```bash
   flutter run
   ```

3. **Test compass**:
   - Open Maps screen
   - Allow location permission
   - Rotate your phone
   - Arrow should rotate to match your facing direction

## Permissions

### Android (`android/app/src/main/AndroidManifest.xml`)
Already has location permissions, no additional permissions needed for compass.

### iOS (`ios/Runner/Info.plist`)
Already has location permissions, no additional permissions needed for compass.

## Troubleshooting

### Arrow not rotating
- Make sure you're testing on a physical device (not emulator)
- Check if device has magnetometer sensor
- Try calibrating compass by moving phone in figure-8 pattern

### Arrow jittering
- Normal behavior due to magnetic interference
- Can add smoothing/filtering if needed

### No arrow visible
- Check if `_userHeading` is not null
- Verify compass permission is granted
- Check console for compass errors

## Visual Result

Before (old marker):
```
    ●  ← Simple blue dot
```

After (new marker with compass):
```
    ▲  ← Triangle arrow pointing in facing direction
    ●  ← Blue dot in center
   (○) ← Light blue accuracy circle
```

The arrow rotates 360° based on device orientation, just like Google Maps!

## Files Modified

1. ✅ `pubspec.yaml` - Added `flutter_compass: ^0.8.0`
2. ✅ `lib/screens/maps_screen.dart` - Added compass functionality and custom arrow painter

## Next Steps

Run `flutter pub get` and test on a physical device to see the compass arrow in action!
