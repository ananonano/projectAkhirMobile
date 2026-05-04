# Bottom Navbar Keyboard Fix ✅

## Problem
Saat user menggunakan search bar di home screen dan keyboard muncul, bottom navigation bar ikut naik ke atas keyboard.

### Before:
```
┌─────────────────┐
│   Home Screen   │
│   [Search Bar]  │ ← User tap here
│                 │
│   [Content]     │
├─────────────────┤
│ [Navbar] ↑      │ ← Navbar naik ikut keyboard ❌
├─────────────────┤
│   [Keyboard]    │
└─────────────────┘
```

### After:
```
┌─────────────────┐
│   Home Screen   │
│   [Search Bar]  │ ← User tap here
│                 │
│   [Content]     │
│   (scrollable)  │
├─────────────────┤
│   [Keyboard]    │
└─────────────────┘
│ [Navbar]        │ ← Navbar stay di bawah ✅
```

## Solution

### Added Property to Scaffold
**File**: `lib/screens/root.dart`

```dart
return Scaffold(
  resizeToAvoidBottomInset: false, // ✅ Prevent navbar from moving
  body: Stack(
    children: [
      // ... content
    ],
  ),
);
```

### What `resizeToAvoidBottomInset: false` Does:

**Default Behavior (true):**
- Scaffold resizes when keyboard appears
- All content (including navbar) pushed up
- Navbar appears above keyboard

**With `false`:**
- Scaffold does NOT resize
- Keyboard overlays the content
- Navbar stays at bottom of screen
- Content behind keyboard is hidden (expected)

## How It Works

### Before Fix:
```
Keyboard appears
  ↓
Scaffold resizes
  ↓
All widgets pushed up
  ↓
Navbar moves above keyboard ❌
```

### After Fix:
```
Keyboard appears
  ↓
Scaffold stays same size
  ↓
Keyboard overlays content
  ↓
Navbar stays at bottom ✅
```

## User Experience

### Search Flow:
1. User taps search bar in home
2. Keyboard slides up from bottom
3. Navbar stays fixed at bottom (behind keyboard)
4. Search bar and results visible above keyboard
5. User can type and see results
6. Dismiss keyboard → Navbar visible again

### Benefits:
- ✅ Navbar position consistent
- ✅ No jarring movement
- ✅ Professional app behavior
- ✅ Similar to Instagram, WhatsApp, etc.

## Technical Details

### Property:
- **Name**: `resizeToAvoidBottomInset`
- **Type**: `bool`
- **Default**: `true`
- **Location**: `Scaffold` widget

### When to Use:
- ✅ Apps with bottom navigation bar
- ✅ When you want navbar to stay fixed
- ✅ When content can scroll behind keyboard

### When NOT to Use:
- ❌ Forms that need all fields visible
- ❌ Single-screen apps without navbar
- ❌ When you need content to resize

## Alternative Solutions (Not Used)

### 1. MediaQuery Padding
```dart
// More complex, not needed
Padding(
  padding: EdgeInsets.only(
    bottom: MediaQuery.of(context).viewInsets.bottom,
  ),
)
```

### 2. Keyboard Listener
```dart
// Overkill for this use case
KeyboardVisibilityBuilder(...)
```

### 3. SingleChildScrollView
```dart
// Already handled by individual screens
```

## Testing Checklist

- [x] Home screen search → Navbar stays at bottom
- [ ] Maps screen search → Navbar stays at bottom
- [ ] Chat screen input → Navbar stays at bottom
- [ ] Profile edit → Navbar stays at bottom
- [ ] Keyboard dismiss → Navbar still at bottom
- [ ] Switch tabs → Navbar position correct

## Files Modified
1. `lib/screens/root.dart` - Added `resizeToAvoidBottomInset: false` to Scaffold

## Status
✅ **FIX COMPLETE** - Navbar stays at bottom when keyboard appears

Bottom navigation bar sekarang stay di posisi bawah, tidak ikut naik saat keyboard muncul!
