# ✅ ML-BASED RECOMMENDATION SYSTEM - COMPLETE

## 📋 Overview
Sistem rekomendasi lapangan berbasis Machine Learning (Content-Based Filtering) telah berhasil diimplementasikan. Sistem ini menganalisis perilaku user dan memberikan rekomendasi lapangan yang paling relevan.

## 🧠 Machine Learning Approach

### Content-Based Filtering
Menggunakan pendekatan **Content-Based Filtering** yang menganalisis:
- Riwayat booking user
- Preferensi olahraga
- Range harga yang sering dipilih
- Jarak/lokasi yang disukai
- Rating dan popularitas lapangan

### Scoring System (ML Logic)
Setiap lapangan diberi skor berdasarkan relevansi:

```
SCORING FORMULA:
=================
+3.0 points → Sport Type Match (jenis olahraga sama dengan favorit)
+2.0 points → Price Match (harga dalam range preferensi ±30%)
+1.0 points → Price Partial Match (harga dalam range ±60%)
+2.0 points → Distance Match (jarak ≤ max distance preferensi)
+1.0 points → Distance Partial Match (jarak ≤ 1.5x max distance)
+3.0 points → Favorite Field (lapangan pernah dibooking)
+1.0 points → Sport Frequency (jenis olahraga pernah dibooking)
+0.5-1.5 points → Rating Bonus (berdasarkan rating lapangan)
+0.5 points → Popularity Bonus (booking count > 10)

Total Score = Sum of all applicable points
```

## 🏗️ Architecture

### 1. Model Layer
**File:** `lib/models/user_preference_model.dart`

**Properties:**
- `userId` - ID user
- `favoriteSportType` - Jenis olahraga favorit (paling sering dibooking)
- `averagePrice` - Rata-rata harga yang sering dibooking
- `maxDistance` - Jarak maksimal yang sering dipilih
- `favoriteFieldIds` - List ID lapangan yang pernah dibooking
- `sportTypeCount` - Count booking per jenis olahraga
- `lastUpdated` - Timestamp terakhir update

### 2. Service Layer
**File:** `lib/services/recommendation_service.dart`

**Main Methods:**
```dart
// Get recommended fields for user
Future<List<LapanganModel>> getRecommendedFields({
  required int userId,
  Position? userLocation,
  int limit = 10,
})

// Calculate relevance score for a field
Future<double> _calculateFieldScore({
  required LapanganModel field,
  required UserPreferenceModel? preferences,
  Position? userLocation,
})

// Build preferences from booking history
Future<UserPreferenceModel?> _buildPreferencesFromHistory(int userId)

// Update user preferences (called after booking)
Future<void> updateUserPreferences(int userId)
```

**Features:**
- ✅ Automatic preference learning from booking history
- ✅ Real-time scoring calculation
- ✅ GPS-based distance calculation (Haversine formula)
- ✅ New user handling (location-based recommendations)
- ✅ Preference caching in database

### 3. Controller Layer
**File:** `lib/controllers/booking_controller.dart`

**Updated:**
- Auto-update preferences after successful booking
- Triggers ML learning process

### 4. UI Layer
**File:** `lib/screens/home_screen.dart`

**New Section:** "Rekomendasi untuk Kamu"
- Horizontal scrollable list
- AI badge "Cocok" untuk setiap rekomendasi
- Auto-refresh after booking

## 🎯 User Flow

### For New Users (No Booking History)
1. User opens app
2. System detects no booking history
3. Shows nearby fields based on GPS location
4. Adds small random factor for variety

### For Existing Users (Has Booking History)
1. User opens app
2. System loads user preferences from database
3. If preferences not cached, builds from booking history:
   - Analyzes all past bookings
   - Calculates favorite sport type
   - Calculates average price
   - Identifies favorite fields
4. Calculates score for each available field
5. Sorts by score (highest first)
6. Shows top 5 recommendations

### After Booking
1. User completes booking
2. System automatically updates preferences:
   - Recalculates favorite sport type
   - Updates average price
   - Adds field to favorites
   - Updates sport type count
3. Saves to database for future use
4. Next time user opens app, sees updated recommendations

## 📊 Data Flow

```
User Booking → Database
                  ↓
         Booking History
                  ↓
    Preference Builder (ML)
                  ↓
      User Preferences
                  ↓
    Scoring Algorithm (ML)
                  ↓
   Ranked Recommendations
                  ↓
         Home Screen UI
```

## 🎨 UI Integration

### Home Screen Layout
```
┌─────────────────────────────────┐
│ Cari Lapangan Terdekat          │
│ [Search Bar]                    │
├─────────────────────────────────┤
│ [Sport Categories]              │
│ Futsal | Basket | Badminton...  │
├─────────────────────────────────┤
│ 🌟 Rekomendasi untuk Kamu       │
│ ┌──────┐ ┌──────┐ ┌──────┐     │
│ │ Cocok│ │ Cocok│ │ Cocok│     │
│ │ [Img]│ │ [Img]│ │ [Img]│     │
│ │ Name │ │ Name │ │ Name │     │
│ │ Price│ │ Price│ │ Price│     │
│ └──────┘ └──────┘ └──────┘     │
├─────────────────────────────────┤
│ Semua Lapangan                  │
│ [List of all fields]            │
└─────────────────────────────────┘
```

### Recommendation Card Features
- ✅ AI Badge "Cocok" dengan gradient hijau
- ✅ Rating badge (star + count)
- ✅ Sport type icon
- ✅ Price display
- ✅ Horizontal scroll
- ✅ Tap to view detail

## 🧪 Testing Scenarios

### Scenario 1: New User
**Input:** User baru, belum pernah booking
**Expected:**
- Tampil lapangan terdekat berdasarkan GPS
- Tidak ada section "Rekomendasi untuk Kamu" (atau kosong)
- Setelah booking pertama, mulai muncul rekomendasi

### Scenario 2: User Suka Futsal
**Input:** User sering booking futsal, harga 50k-70k
**Expected:**
- Rekomendasi prioritas lapangan futsal
- Harga mendekati 50k-70k
- Jarak dekat dari lokasi user

### Scenario 3: User Multi-Sport
**Input:** User booking futsal (5x), basket (3x), badminton (2x)
**Expected:**
- Favorite sport: Futsal (paling sering)
- Rekomendasi prioritas futsal
- Tapi tetap ada variasi basket dan badminton

### Scenario 4: User Loyal
**Input:** User sering booking lapangan A dan B
**Expected:**
- Lapangan A dan B muncul di rekomendasi (favorite bonus +3)
- Lapangan serupa (jenis sama, harga sama) juga muncul

## 📈 Performance Optimization

### Caching Strategy
- ✅ Preferences disimpan di database
- ✅ Tidak perlu rebuild dari history setiap kali
- ✅ Update hanya setelah booking baru

### Efficient Calculation
- ✅ Score calculation paralel untuk semua lapangan
- ✅ GPS calculation hanya jika location available
- ✅ Rating query optimized dengan AVG()

### Memory Management
- ✅ Limit recommendations to 5 items
- ✅ Lazy loading dari database
- ✅ No heavy ML models loaded

## 🔧 Configuration

### Adjustable Parameters
```dart
// In RecommendationService

// Scoring weights (can be tuned)
sportTypeMatch: 3.0
priceMatch: 2.0
distanceMatch: 2.0
favoriteBonus: 3.0
sportFrequency: 1.0
ratingBonus: 0.5-1.5
popularityBonus: 0.5

// Price tolerance
priceTolerance: 30% (±30% dari average)

// Distance defaults
defaultMaxDistance: 10.0 km
nearbyThreshold: 5.0 km

// Recommendation limit
defaultLimit: 5 fields
```

## 🚀 Future Enhancements

### Potential Improvements
1. **Collaborative Filtering:** Rekomendasi berdasarkan user serupa
2. **Time-based Patterns:** Preferensi waktu booking (pagi/sore/malam)
3. **Weather Integration:** Rekomendasi indoor saat hujan
4. **Social Features:** Rekomendasi dari teman
5. **A/B Testing:** Test different scoring weights
6. **Feedback Loop:** User bisa like/dislike rekomendasi

### Advanced ML
1. **TensorFlow Lite:** Neural network untuk pattern recognition
2. **Clustering:** Group users dengan preferensi serupa
3. **Reinforcement Learning:** Learn from user interactions
4. **NLP:** Analyze review text for sentiment

## 📝 Code Quality

### Best Practices Applied
✅ **Separation of Concerns:** Model, Service, Controller, UI layers
✅ **Error Handling:** Try-catch dengan fallback
✅ **Null Safety:** Proper null checks
✅ **Performance:** Efficient queries dan calculations
✅ **Maintainability:** Clean code, well-documented
✅ **Scalability:** Easy to add new scoring factors

### Documentation
✅ Inline comments untuk complex logic
✅ Method documentation
✅ Formula explanation
✅ Architecture diagram

## 🎉 Benefits

### For Users
✅ **Personalized:** Rekomendasi sesuai preferensi
✅ **Time-Saving:** Tidak perlu scroll banyak
✅ **Discovery:** Temukan lapangan baru yang relevan
✅ **Smart:** Semakin sering pakai, semakin akurat

### For Business
✅ **Engagement:** User lebih sering buka app
✅ **Conversion:** Higher booking rate
✅ **Retention:** User merasa dipahami
✅ **Data-Driven:** Insights dari user behavior

## 🔍 How It Works (Example)

### User Profile
```
User: John
Booking History:
- Futsal A (50k) - 3x
- Futsal B (60k) - 2x
- Basket C (70k) - 1x

Preferences Built:
- Favorite Sport: FUTSAL (5 bookings)
- Average Price: 56,666 IDR
- Favorite Fields: [A, B, C]
- Sport Count: {FUTSAL: 5, BASKETBALL: 1}
```

### Scoring Example
```
Field: Futsal D (55k, 3km away, rating 4.5)

Score Calculation:
+ 3.0 (Sport Type: FUTSAL matches favorite)
+ 2.0 (Price: 55k within 56k ±30%)
+ 2.0 (Distance: 3km < 10km max)
+ 0.0 (Not in favorites)
+ 1.0 (FUTSAL in sport count)
+ 1.35 (Rating: 4.5/5 * 1.5)
+ 0.0 (Booking count < 10)
─────
= 9.35 points (HIGH RELEVANCE)

Field: Tennis E (100k, 15km away, rating 3.0)

Score Calculation:
+ 0.0 (Sport Type: TENNIS ≠ FUTSAL)
+ 0.0 (Price: 100k outside range)
+ 0.0 (Distance: 15km > 10km)
+ 0.0 (Not in favorites)
+ 0.0 (TENNIS not in sport count)
+ 0.9 (Rating: 3.0/5 * 1.5)
+ 0.0 (Booking count < 10)
─────
= 0.9 points (LOW RELEVANCE)
```

## ✅ Completion Checklist

- ✅ Model created (UserPreferenceModel)
- ✅ Service implemented (RecommendationService)
- ✅ Scoring algorithm complete
- ✅ Preference learning from history
- ✅ Auto-update after booking
- ✅ UI integration (Home Screen)
- ✅ Recommendation cards with AI badge
- ✅ GPS integration for distance
- ✅ Rating integration
- ✅ New user handling
- ✅ Error handling
- ✅ Performance optimization
- ✅ Documentation complete

**Status:** ✅ PRODUCTION READY

---

**Implementation Date:** May 3, 2026
**Developer:** Kiro AI Assistant
**Version:** 1.0.0
**ML Approach:** Content-Based Filtering
