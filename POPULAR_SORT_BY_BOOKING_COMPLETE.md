# Popular Sort by Booking Count - COMPLETE ✅

## User Request
> "ini lapangan terlaris dia berdasarkan apa bre? aku nanya aja"
> "iya bre berdasarkan jumlah booking aja"

## Previous Implementation
**Before**: "Lapangan Terlaris" sorted by **review count** (`_reviewCounts`)
- Assumption: More reviews = more popular
- Less accurate because not everyone leaves a review

## New Implementation
**After**: "Lapangan Terlaris" sorted by **booking count** (`_bookingCounts`)
- More accurate: Directly counts actual bookings
- Query: `SELECT COUNT(*) FROM bookings WHERE lapangan_id = ?`

## Changes Made

### 1. Added Booking Count Storage
```dart
Map<int, int> _bookingCounts = {}; // Store booking counts for popularity
```

### 2. Added Method to Get Booking Count
```dart
Future<int> _getBookingCount(int lapanganId) async {
  final db = await DatabaseHelper.instance.database;
  final result = await db.rawQuery(
    'SELECT COUNT(*) as count FROM bookings WHERE lapangan_id = ?',
    [lapanganId],
  );
  return (result.first['count'] as int?) ?? 0;
}
```

### 3. Updated _fetchLapangans
Now loads booking counts for each lapangan:
```dart
for (var lapangan in data) {
  if (lapangan.id != null) {
    // ... load ratings and reviews
    
    // Get booking count for this lapangan
    final bookingCount = await _getBookingCount(lapangan.id!);
    bookingCounts[lapangan.id!] = bookingCount;
  }
}
```

### 4. Updated _applyFilters
Now accepts `bookingCounts` parameter and uses it for sorting:
```dart
else if (_sortBy == 'popular') {
  // Sort by booking count (most booked = most popular)
  filtered.sort((a, b) {
    final countA = bookingCounts[a.id] ?? 0;
    final countB = bookingCounts[b.id] ?? 0;
    return countB.compareTo(countA); // Descending
  });
}
```

### 5. Added Import
```dart
import '../database/database.dart';
```

## How It Works

### Booking Count Query
For each lapangan, count total bookings:
```sql
SELECT COUNT(*) as count FROM bookings WHERE lapangan_id = ?
```

### Sort Logic
1. Get booking count for lapangan A and B
2. Compare counts
3. Sort descending (highest count first)
4. Lapangan with most bookings appears first

## Example

### Database State
```
Lapangan A: 15 bookings, 5 reviews
Lapangan B: 10 bookings, 8 reviews
Lapangan C: 20 bookings, 3 reviews
```

### Before (Review Count)
Order: B (8 reviews) → A (5 reviews) → C (3 reviews)

### After (Booking Count)
Order: C (20 bookings) → A (15 bookings) → B (10 bookings) ✅

## Benefits

### More Accurate
- Reflects actual usage/popularity
- Every booking counted, not just reviews
- Not everyone leaves reviews

### Real Popularity Metric
- Shows which lapangan are actually being used
- Better indicator of demand
- Helps users find proven popular venues

### Business Insight
- Venue owners can see real popularity
- Users trust venues with many bookings
- More reliable than review count

## Files Modified

### `lib/screens/home_screen.dart`
- ✅ Added `_bookingCounts` map
- ✅ Added `_getBookingCount` method
- ✅ Updated `_fetchLapangans` to load booking counts
- ✅ Updated `_applyFilters` to use booking counts for popular sort
- ✅ Added `DatabaseHelper` import

## Performance Note
- Adds one database query per lapangan
- Query is simple COUNT, very fast
- Cached in `_bookingCounts` map
- Only loaded once per search/filter

## Testing Checklist
- [ ] "Lapangan Terlaris" sorts by booking count
- [ ] Lapangan with most bookings appears first
- [ ] Lapangan with 0 bookings appears last
- [ ] Sort works correctly with filters
- [ ] Performance acceptable with many lapangan

## Status: ✅ COMPLETE
"Lapangan Terlaris" now sorts by actual booking count, not review count.
