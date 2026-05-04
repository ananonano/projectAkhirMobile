# Filter & Sort Separate Buttons - COMPLETE ✅

## User Request
> "jadi aku idenya buat jadi 2 tombol aja, yang pertama itu filter, yang ke2 itu semacam sorting. tapi ini 2 buttonnya jangan masuk ke search bar deh, buat di sebelah searchbar aja 2 button filter sama sort ini, untuk filter itu hampir bener kek sekarang, tapi untuk yang urutkan rating itu ganti jadi pilihan gitu aja mau pilih yang berdasarkan rating >= 1, >=2 , >=3 , >=4, atau 5. nah untuk filter sort ini, itu baru isinya urutan berdasarkan rating (tertinggi/terendah), harga (tertinggi/terendah), terus lapangan terlaris dan lapangan terbaru."

## Implementation

### UI Changes

#### Search Bar Row
Now has 3 elements side by side:
1. **Search Bar** (expanded) - Search by venue or sport
2. **Filter Button** (icon: filter_list) - Opens filter bottom sheet
3. **Sort Button** (icon: sort) - Opens sort bottom sheet

```
[  Search Bar (expanded)  ] [Filter] [Sort]
```

### Button 1: FILTER (filter_list icon)

Opens bottom sheet with 3 filter options:

#### 1. Rating Minimum
- **Options**: >= 1★, >= 2★, >= 3★, >= 4★, 5★
- **Behavior**: Single selection (tap to select, tap again to deselect)
- **Visual**: Chips with star icon
- **Logic**: Filters lapangan with rating >= selected value

#### 2. Rentang Harga (Price Range)
- **Min Input**: Number field with "Rp" prefix
- **Max Input**: Number field with "Rp" prefix
- **Behavior**: Can input one or both
- **Logic**: Filters lapangan within price range

#### 3. Kategori Olahraga (Sport Categories)
- **Options**: Futsal, Basket, Badminton, Mini Soccer, Tennis
- **Behavior**: Multiple selection (FilterChip)
- **Visual**: Chips with checkmark when selected
- **Logic**: Filters lapangan matching selected categories

#### Action Buttons
- **Reset**: Clear all filters and reload
- **Terapkan Filter**: Apply filters and close sheet

### Button 2: SORT (sort icon)

Opens bottom sheet with 6 sort options:

#### Sort Options
1. **Rating Tertinggi** (star icon) - Sort by rating descending
2. **Rating Terendah** (star_outline icon) - Sort by rating ascending
3. **Harga Tertinggi** (arrow_up icon) - Sort by price descending
4. **Harga Terendah** (arrow_down icon) - Sort by price ascending
5. **Lapangan Terlaris** (fire icon) - Sort by review count (popularity)
6. **Lapangan Terbaru** (new_releases icon) - Sort by ID (newest first)

#### Behavior
- **Single selection**: Tap option to apply immediately
- **Auto-close**: Sheet closes after selection
- **Visual feedback**: Selected option highlighted with checkmark
- **Reset button**: Clear sort and return to default order

## Filter Logic

### Filter Application Order
1. **Category Filter**: Filter by selected sport types
2. **Price Filter**: Filter by min/max price range
3. **Rating Filter**: Filter by minimum rating
4. **Sort**: Apply selected sort order

### Sort Logic

#### Rating Sort
- **Tertinggi**: `ratingB.compareTo(ratingA)` - Descending
- **Terendah**: `ratingA.compareTo(ratingB)` - Ascending

#### Price Sort
- **Tertinggi**: `b.harga.compareTo(a.harga)` - Descending
- **Terendah**: `a.harga.compareTo(b.harga)` - Ascending

#### Popularity Sort (Terlaris)
- Sort by `_reviewCounts` (number of reviews)
- More reviews = more popular
- Descending order

#### Newest Sort (Terbaru)
- Sort by `id` field
- Higher ID = newer lapangan
- Descending order

## State Management

### Filter State
```dart
double? _filterMinRating;        // 1.0, 2.0, 3.0, 4.0, 5.0
double? _filterPriceMin;         // Minimum price
double? _filterPriceMax;         // Maximum price
List<String> _filterCategories;  // Selected sport types
```

### Sort State
```dart
String? _sortBy;  // 'rating_high', 'rating_low', 'price_high', 
                  // 'price_low', 'popular', 'newest'
```

## User Flow

### Using Filter
1. Tap **Filter button** (filter_list icon)
2. Select minimum rating (optional)
3. Enter price range (optional)
4. Select sport categories (optional)
5. Tap **"Terapkan Filter"** → List filtered
6. Or tap **"Reset"** → Clear all filters

### Using Sort
1. Tap **Sort button** (sort icon)
2. Tap desired sort option
3. Sheet closes automatically
4. List reordered immediately
5. Or tap **"Reset Urutan"** → Return to default order

### Combined Usage
- Filters and sort work together
- Example: Filter by Futsal + Rating >= 4 + Sort by Harga Terendah
- Result: Futsal fields with 4+ stars, sorted by lowest price first

## Visual Design

### Button Style
- White background
- Border: 1px gray
- Shadow: subtle
- Icon: Primary color
- Size: 48x48px (same as search bar height)

### Filter Bottom Sheet
- Rounded top corners
- Scrollable content
- Keyboard-aware
- Sections clearly separated
- Primary color for selected items

### Sort Bottom Sheet
- Rounded top corners
- List of options
- Hover/tap feedback
- Checkmark for selected
- Auto-close on selection

## Files Modified

### `lib/screens/home_screen.dart`
- ✅ Updated filter state variables
- ✅ Added sort state variable
- ✅ Updated `_applyFilters` method with sort logic
- ✅ Changed search bar UI to row with 3 elements
- ✅ Updated `_showFilterBottomSheet` with rating minimum
- ✅ Added `_showSortBottomSheet` method
- ✅ Added `_buildSortOption` widget
- ✅ Removed unused `_buildRatingOption` method

## Testing Checklist

### Filter Button
- [ ] Filter button opens filter bottom sheet
- [ ] Rating minimum filter works (>=1, >=2, >=3, >=4, 5)
- [ ] Price min filter works
- [ ] Price max filter works
- [ ] Price range filter works (min + max)
- [ ] Category single selection works
- [ ] Category multiple selection works
- [ ] Reset button clears all filters
- [ ] Apply button applies filters and closes sheet

### Sort Button
- [ ] Sort button opens sort bottom sheet
- [ ] Rating Tertinggi sorts correctly
- [ ] Rating Terendah sorts correctly
- [ ] Harga Tertinggi sorts correctly
- [ ] Harga Terendah sorts correctly
- [ ] Lapangan Terlaris sorts by review count
- [ ] Lapangan Terbaru sorts by ID
- [ ] Selected option highlighted
- [ ] Sheet closes after selection
- [ ] Reset button clears sort

### Combined
- [ ] Filter + Sort work together
- [ ] Multiple filters + sort work correctly
- [ ] Reset filter doesn't affect sort
- [ ] Reset sort doesn't affect filters
- [ ] UI responsive on different screen sizes

## Status: ✅ COMPLETE
All changes implemented. Filter and Sort are now separate buttons with distinct functionality.
