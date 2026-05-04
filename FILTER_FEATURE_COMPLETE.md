# Filter Feature - COMPLETE ✅

## Feature Overview
Added comprehensive filter functionality to Home Screen search bar. Users can now filter lapangan by:
1. **Rating** (Tertinggi/Terendah)
2. **Harga** (Range: Min - Max)
3. **Kategori Olahraga** (Multiple selection)

## User Request
> "untuk search bar yang di homepage, kan itu dibagian ujung kanan search bar ada ikon filter ya, nah itu aku mau fitur filternya bekerja, jadi nanti kalo tekan tombol filter, nanti bisa ada pilihan bisa filter lewat rating (tertinggi/terendah), terus harga bisa diinput nanti untuk filternya dari rentang berapa sampai berapa, terus juga bisa filter berdasarkan kategori tapi dia selectbox gitu mau kategori olahraga apa aja"

## Implementation Details

### 1. Filter State Variables
Added to `_HomeScreenState`:
```dart
String? _filterRating;              // 'highest' or 'lowest'
double? _filterPriceMin;            // Minimum price
double? _filterPriceMax;            // Maximum price
List<String> _filterCategories = []; // Selected sport types
TextEditingController _priceMinController;
TextEditingController _priceMaxController;
```

### 2. Filter Logic (`_applyFilters`)
Filters are applied in this order:
1. **Category Filter**: Filter by selected sport types
2. **Price Range Filter**: Filter by min/max price
3. **Rating Sort**: Sort by rating (highest/lowest)

```dart
List<LapanganModel> _applyFilters(List<LapanganModel> data, Map<int, double> ratings) {
  // Filter by categories
  if (_filterCategories.isNotEmpty) {
    filtered = filtered.where((lapangan) => 
      _filterCategories.contains(lapangan.jenis.toUpperCase())
    ).toList();
  }
  
  // Filter by price range
  if (_filterPriceMin != null) {
    filtered = filtered.where((lapangan) => lapangan.harga >= _filterPriceMin!).toList();
  }
  if (_filterPriceMax != null) {
    filtered = filtered.where((lapangan) => lapangan.harga <= _filterPriceMax!).toList();
  }
  
  // Sort by rating
  if (_filterRating == 'highest') {
    filtered.sort((a, b) => ratingB.compareTo(ratingA)); // Descending
  } else if (_filterRating == 'lowest') {
    filtered.sort((a, b) => ratingA.compareTo(ratingB)); // Ascending
  }
  
  return filtered;
}
```

### 3. Filter Bottom Sheet UI
Beautiful modal bottom sheet with:

#### Rating Section
- Two options: **Tertinggi** (highest) / **Terendah** (lowest)
- Toggle selection (tap again to deselect)
- Visual feedback with icons and colors

#### Price Range Section
- Two text fields: **Min** and **Max**
- Number keyboard
- Rupiah prefix (Rp)
- Separated by dash (—)

#### Category Section
- Multiple selection chips
- All sport types: Futsal, Basket, Badminton, Mini Soccer, Tennis
- Visual feedback when selected
- Can select multiple categories

#### Action Buttons
- **Reset**: Clear all filters and reload
- **Terapkan Filter**: Apply filters and reload

### 4. UI Components

#### Filter Button
Changed from search trigger to filter trigger:
```dart
suffixIcon: IconButton(
  icon: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
  onPressed: _showFilterBottomSheet, // ✅ Opens filter modal
),
```

#### Rating Option Widget
Custom widget for rating selection:
- Icon (arrow up/down)
- Label text
- Border and background color change on selection

#### Filter Chips
Material FilterChip for categories:
- Checkmark when selected
- Color change on selection
- Multiple selection support

## User Flow

### Opening Filter
1. User taps filter icon (tune icon) in search bar
2. Bottom sheet slides up from bottom
3. Shows all filter options

### Selecting Filters
1. **Rating**: Tap "Tertinggi" or "Terendah" (tap again to deselect)
2. **Price**: Enter min and/or max price in Rupiah
3. **Category**: Tap sport chips to select/deselect (can select multiple)

### Applying Filters
1. Tap "Terapkan Filter" button
2. Bottom sheet closes
3. Lapangan list reloads with filters applied
4. Only matching lapangan shown

### Resetting Filters
1. Tap "Reset" button
2. All filters cleared
3. Bottom sheet closes
4. Full lapangan list shown

## Filter Behavior

### Single Filter
- **Rating only**: Sort all lapangan by rating
- **Price only**: Show lapangan within price range
- **Category only**: Show lapangan of selected categories

### Combined Filters
Filters work together:
- **Category + Price**: Show selected categories within price range
- **Category + Rating**: Show selected categories sorted by rating
- **Price + Rating**: Show lapangan within price range sorted by rating
- **All three**: Show selected categories within price range sorted by rating

### Edge Cases
- **No filters**: Show all lapangan (default behavior)
- **No results**: Show empty state "Lapangan tidak ditemukan"
- **Invalid price**: Ignored (only valid numbers applied)
- **Min > Max**: Both applied independently (no validation)

## Visual Design

### Bottom Sheet
- White background
- Rounded top corners (20px)
- Padding: 24px
- Scrollable content
- Keyboard-aware (adjusts for keyboard)

### Colors
- **Selected**: Primary color with light background
- **Unselected**: Gray border with white background
- **Buttons**: Primary (apply) / Gray (reset)

### Typography
- **Title**: 20px, Bold
- **Section Headers**: 14px, Semi-bold
- **Options**: 14px, Medium/Semi-bold

## Files Modified

### `lib/screens/home_screen.dart`
- ✅ Added filter state variables
- ✅ Added `_applyFilters` method
- ✅ Updated `_fetchLapangans` to apply filters
- ✅ Added `_showFilterBottomSheet` method
- ✅ Added `_buildRatingOption` widget
- ✅ Changed filter button action
- ✅ Added text controller disposal

## Testing Checklist
- [ ] Filter button opens bottom sheet
- [ ] Rating filter works (highest/lowest)
- [ ] Price min filter works
- [ ] Price max filter works
- [ ] Price range filter works (min + max)
- [ ] Category single selection works
- [ ] Category multiple selection works
- [ ] Combined filters work together
- [ ] Reset button clears all filters
- [ ] Apply button applies filters and closes sheet
- [ ] Close button closes sheet without applying
- [ ] Empty state shows when no results
- [ ] Filters persist during session
- [ ] Filters work with search text
- [ ] Filters work with sport type categories

## Future Enhancements (Optional)
- [ ] Show active filter count badge on filter icon
- [ ] Add distance filter (nearby first)
- [ ] Add availability filter (has available slots)
- [ ] Add facility filter (parking, toilet, etc.)
- [ ] Save filter preferences
- [ ] Quick filter presets

## Status: ✅ COMPLETE
All filter functionality implemented and ready for testing.
