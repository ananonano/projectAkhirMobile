# Database Seeder Update Summary

## Real Data from Google Maps Scraping

### Total Venues: 101 Sports Fields

#### FUTSAL (18 venues)
- Price range: Rp 100,000 - Rp 200,000
- Filtered out: "Kaos Futsal Jogja" (clothing store)
- Real venues include: Planet Futsal, Dolano Coffee & Futsal, GPS Futsal Academy, Pelle Futsal, etc.

#### BADMINTON (39 venues)  
- Price range: Rp 35,000 - Rp 70,000
- Filtered out: "Toko Dunia Badminton" (sporting goods store)
- Real venues include: Lapangan Badminton MOY, Gor Mini Badminton Sambilegi, GOR PHOENIX, etc.

#### BASKETBALL (10 venues)
- Price range: Rp 80,000 - Rp 200,000
- All entries are valid basketball courts
- Real venues include: UTAMA basketball - GOR victory, UMY Basketball Court, etc.

#### TENNIS (18 venues)
- Price range: Rp 60,000 - Rp 120,000
- Filtered out: "Senar Raket Badminton-Tennis" (sports equipment)
- Real venues include: Persatuan Tenis Meja Suryanaga, Tennis Court at Hyatt Regency, etc.

#### MINI SOCCER (16 venues)
- Price range: Rp 250,000 - Rp 400,000
- All entries are valid mini soccer fields
- Real venues include: Lapangan Mini Soccer Kepuharjo, Adyoko Mini Soccer, CH4 Arena, etc.

## Implementation Status

The database version has been updated from 7 to 8 to force recreation.

Next step: Update the `realJogjaCourts` list in `_onCreate` method with all 101 real venues from the CSV files, with:
- Real coordinates (lat/lng)
- Real addresses
- Randomized realistic prices
- Unique varied descriptions
- Proper amenities assignment

## Note
Due to the large size of the data (101 venues), the complete seeder code will be provided in the next step.
