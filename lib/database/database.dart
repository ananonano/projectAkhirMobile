import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/lapangan_model.dart';
import 'database_factory.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    return await PlatformDatabaseFactory.getDatabase(
      version: 10,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE lapangans ADD COLUMN jam_buka TEXT DEFAULT "08:00"');
        await db.execute('ALTER TABLE lapangans ADD COLUMN jam_tutup TEXT DEFAULT "22:00"');
        print('[DB] Successfully upgraded schema to v2 - Added jam_buka and jam_tutup');
      } catch (e) {
        print('[DB] Upgrade warning v2: $e');
      }
    }
    
    if (oldVersion < 3) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS chat_messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            role TEXT NOT NULL,
            text TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        ''');
        print('[DB] Successfully upgraded schema to v3 - Added chat_messages table');
      } catch (e) {
        print('[DB] Upgrade warning v3: $e');
      }
    }
    
    if (oldVersion < 4) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS reviews (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            lapangan_id INTEGER NOT NULL,
            rating INTEGER NOT NULL,
            comment TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
            FOREIGN KEY (lapangan_id) REFERENCES lapangans (id) ON DELETE CASCADE
          )
        ''');
        print('[DB] Successfully upgraded schema to v4 - Added reviews table');
      } catch (e) {
        print('[DB] Upgrade warning v4: $e');
      }
    }
    
    if (oldVersion < 5) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS lapangan_images (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            lapangan_id INTEGER NOT NULL,
            image_path TEXT NOT NULL,
            position INTEGER DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (lapangan_id) REFERENCES lapangans (id) ON DELETE CASCADE
          )
        ''');
        print('[DB] Successfully upgraded schema to v5 - Added lapangan_images table');
      } catch (e) {
        print('[DB] Upgrade warning v5: $e');
      }
    }
    
    if (oldVersion < 6) {
      try {
        await db.execute('ALTER TABLE bookings ADD COLUMN status TEXT DEFAULT "completed"');
        print('[DB] Successfully upgraded schema to v6 - Added status to bookings');
      } catch (e) {
        print('[DB] Upgrade warning v6: $e');
      }
    }

    if (oldVersion < 7) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS vouchers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL,
            percent_discount INTEGER NOT NULL,
            earned_score INTEGER NOT NULL,
            is_used INTEGER DEFAULT 0,
            used_at TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (username) REFERENCES users (username) ON DELETE CASCADE
          )
        ''');
        print('[DB] Successfully upgraded schema to v7 - Added vouchers table');
      } catch (e) {
        print('[DB] Upgrade warning v7: $e');
      }
    }

    if (oldVersion < 8) {
      try {
        // Drop and recreate lapangans table to refresh with real data
        await db.execute('DROP TABLE IF EXISTS lapangans');
        await db.execute('''
          CREATE TABLE lapangans (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nama_lapangan TEXT,
            description TEXT,
            image TEXT,
            jenis TEXT, 
            harga INTEGER, 
            capacity INTEGER DEFAULT 1,
            address TEXT,
            lat REAL,
            lng REAL,
            jam_buka TEXT DEFAULT "08:00",
            jam_tutup TEXT DEFAULT "22:00",
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        ''');
        print('[DB] Successfully upgraded schema to v8 - Refreshed lapangans with real data');
      } catch (e) {
        print('[DB] Upgrade warning v8: $e');
      }
    }

    if (oldVersion < 9) {
      try {
        await db.execute('ALTER TABLE bookings ADD COLUMN payment_method TEXT DEFAULT "QRIS"');
        print('[DB] Successfully upgraded schema to v9 - Added payment_method to bookings');
      } catch (e) {
        print('[DB] Upgrade warning v9: $e');
      }
    }

    if (oldVersion < 10) {
      try {
        // Add user_id column to chat_messages table
        await db.execute('ALTER TABLE chat_messages ADD COLUMN user_id INTEGER DEFAULT 1');
        print('[DB] Successfully upgraded schema to v10 - Added user_id to chat_messages');
      } catch (e) {
        print('[DB] Upgrade warning v10: $e');
      }
    }
  }

  Future<bool> checkUsernameExists(String username) async {
    Database db = await instance.database;
    var res = await db.query(
      "users",
      where: "username = ?",
      whereArgs: [username],
    );
    return res.isNotEmpty;
  }

  Future _onCreate(Database db, int version) async {
    print('[DB_onCreate] Starting database creation...');
    print('[DB_onCreate] Platform: ${kIsWeb ? "WEB" : "MOBILE"}');
    
    // 1. Tabel Users
    print('[DB_onCreate] Creating users table...');
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        password TEXT,
        name TEXT,
        email TEXT UNIQUE,
        phone TEXT,
        image TEXT,
        role TEXT DEFAULT 'user',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    print('[DB_onCreate] Users table created');

    // 2. Tabel Lapangans
    print('[DB_onCreate] Creating lapangans table...');
    await db.execute('''
      CREATE TABLE lapangans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_lapangan TEXT,
        description TEXT,
        image TEXT,
        jenis TEXT, 
        harga INTEGER, 
        capacity INTEGER DEFAULT 1,
        address TEXT,
        lat REAL,
        lng REAL,
        jam_buka TEXT DEFAULT "08:00",
        jam_tutup TEXT DEFAULT "22:00",
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    print('[DB_onCreate] Lapangans table created');

    // 3. Tabel Amenities
    await db.execute('''
      CREATE TABLE amenities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 4. Tabel Relasi Lapangan_Amenities
    await db.execute('''
      CREATE TABLE lapangan_amenities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lapangan_id INTEGER,
        amenity_id INTEGER,
        FOREIGN KEY (lapangan_id) REFERENCES lapangans (id) ON DELETE CASCADE,
        FOREIGN KEY (amenity_id) REFERENCES amenities (id) ON DELETE CASCADE
      )
    ''');

    // 5. Tabel Bookings
    await db.execute('''
      CREATE TABLE bookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        lapangan_id INTEGER,
        nama_lapangan TEXT, 
        tanggal TEXT, 
        jam TEXT, 
        total_harga TEXT, 
        status TEXT DEFAULT "completed",
        payment_method TEXT DEFAULT "QRIS",
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (lapangan_id) REFERENCES lapangans (id) ON DELETE CASCADE
      )
    ''');

    // 6. Tabel Payments
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        booking_id INTEGER UNIQUE, 
        method TEXT,
        amount INTEGER,
        status TEXT DEFAULT 'unpaid',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (booking_id) REFERENCES bookings (id) ON DELETE CASCADE
      )
    ''');

    // 7. Tabel Chat Messages
    await db.execute('''
      CREATE TABLE chat_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        role TEXT NOT NULL,
        text TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // 8. Tabel Reviews
    await db.execute('''
      CREATE TABLE reviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        lapangan_id INTEGER NOT NULL,
        rating INTEGER NOT NULL,
        comment TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (lapangan_id) REFERENCES lapangans (id) ON DELETE CASCADE
      )
    ''');

    // 9. Tabel Lapangan Images
    await db.execute('''
      CREATE TABLE lapangan_images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lapangan_id INTEGER NOT NULL,
        image_path TEXT NOT NULL,
        position INTEGER DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (lapangan_id) REFERENCES lapangans (id) ON DELETE CASCADE
      )
    ''');

    // 10. Tabel Vouchers
    await db.execute('''
      CREATE TABLE vouchers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        percent_discount INTEGER NOT NULL,
        earned_score INTEGER NOT NULL,
        is_used INTEGER DEFAULT 0,
        used_at TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (username) REFERENCES users (username) ON DELETE CASCADE
      )
    ''');

    print('[DB_onCreate] All tables created successfully');

    // SEEDER - REAL DATA FROM GOOGLE MAPS SCRAPING    
    if (kIsWeb) {
      print('[DB_onCreate] Running on WEB - Skipping data seeding for performance');
      print('[DB_onCreate] Creating minimal admin account only...');
      
      // Only create admin account for web
      await db.insert('users', {
        'username': 'admin',
        'password': 'f865b53623b121fd34ee5426c792e5c33af8c227',
        'name': 'Super Admin Lapangin',
        'email': 'admin@lapangin.com',
        'phone': '081234567890',
        'role': 'admin',
      });
      
      print('[DB_onCreate] Web database initialization complete!');
      return; // Exit early for web
    }

    print('[DB_onCreate] Running on MOBILE - Loading full dataset...');

    // Insert Admin Account
    await db.insert('users', {
      'username': 'admin',
      'password': 'f865b53623b121fd34ee5426c792e5c33af8c227',
      'name': 'Super Admin Lapangin',
      'email': 'admin@lapangin.com',
      'phone': '081234567890',
      'role': 'admin',
    });

    // Insert User Accounts
    String userPass = '95c946bf622ef93b0a211cd0fd028dfdfcf7e39e';
    await db.insert('users', {
      'username': 'danang',
      'password': userPass,
      'name': 'Danang Adiwibowo',
      'email': 'danang@email.com',
      'phone': '081234567891',
      'role': 'user',
    });
    await db.insert('users', {
      'username': 'vano',
      'password': userPass,
      'name': 'Vano',
      'email': 'vano@email.com',
      'phone': '081234567892',
      'role': 'user',
    });
    await db.insert('users', {
      'username': 'atilla',
      'password': userPass,
      'name': 'Mohammad Atilla Danadyaksa',
      'email': 'atilla@email.com',
      'phone': '081234567893',
      'role': 'user',
    });
    await db.insert('users', {
      'username': 'najla',
      'password': userPass,
      'name': 'Najla',
      'email': 'najla@email.com',
      'phone': '081234567894',
      'role': 'user',
    });

    // Insert Amenities
    await db.insert('amenities', {'name': 'Toilet Bersih'});
    await db.insert('amenities', {'name': 'Kantin / Cafe'});
    await db.insert('amenities', {'name': 'Parkir Luas'});
    await db.insert('amenities', {'name': 'Mushola'});

    // Data real 101 venue olahraga
    List<Map<String, dynamic>> realVenues = [
      // Lapangan futsal (18 venue)
      {'nama_lapangan': 'Next Futsal, Pool & Lounge', 'description': 'Lapangan futsal modern dengan fasilitas pool dan lounge area. Cocok untuk main sambil santai bersama teman.', 'image': 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800', 'jenis': 'FUTSAL', 'harga': 175000, 'capacity': 10, 'address': 'Jalan Urip Sumoharjo 139, Kota Yogyakarta', 'lat': -7.783087, 'lng': 110.386795},
      {'nama_lapangan': 'Planet Futsal', 'description': 'Salah satu lapangan futsal terbaik di Jogja dengan vinyl berkualitas tinggi dan pencahayaan sempurna untuk main malam.', 'image': 'https://images.unsplash.com/photo-1589487391730-58f20eb2c308?w=800', 'jenis': 'FUTSAL', 'harga': 180000, 'capacity': 10, 'address': 'Jl. Ring Road Utara No.168, Depok, Sleman', 'lat': -7.760301, 'lng': 110.408318},
      {'nama_lapangan': 'Dolano Coffee & Futsal', 'description': 'Konsep unik futsal dengan kafe, bisa main futsal sambil ngopi. Suasana nyaman dan harga terjangkau.', 'image': 'https://www.bing.com/th?id=OLC.QCJClZlJdH6nAg480x360&pid=Local', 'jenis': 'FUTSAL', 'harga': 145000, 'capacity': 10, 'address': 'Jalan Sonopakis, Bantul', 'lat': -7.811669, 'lng': 110.336243},
      {'nama_lapangan': 'GPS Futsal Academy', 'description': 'Lapangan futsal dengan program akademi untuk yang serius latihan. Rumput sintetis premium dan drainase bagus.', 'image': 'https://www.bing.com/th?id=OLC.OhvNTXyAlgDqPA480x360&pid=Local', 'jenis': 'FUTSAL', 'harga': 165000, 'capacity': 10, 'address': 'Panggung Harjo Sewon, Bantul', 'lat': -7.833537, 'lng': 110.358063},
      {'nama_lapangan': 'Pelle Futsal', 'description': 'Lokasi strategis dekat kampus, favorit mahasiswa untuk main futsal sore. Harga bersahabat dan fasilitas lengkap.', 'image': 'https://images.unsplash.com/photo-1551958219-acbc608c6377?w=800', 'jenis': 'FUTSAL', 'harga': 135000, 'capacity': 10, 'address': 'Jalan Babarsari 5, Catur tunggal, Sleman', 'lat': -7.780180, 'lng': 110.415443},
      {'nama_lapangan': 'Angel Futsal', 'description': 'Lapangan futsal di area Magelang dengan lantai vinyl empuk. Cocok untuk turnamen dan latihan tim.', 'image': 'https://www.bing.com/th?id=OLC.IKIRw3SyFVyAEw480x360&pid=Local', 'jenis': 'FUTSAL', 'harga': 120000, 'capacity': 10, 'address': 'Kwangsan Donorejo Secang, Magelang', 'lat': -7.387634, 'lng': 110.271751},
      {'nama_lapangan': 'Sport Academy Yogyakarta', 'description': 'Kompleks olahraga dengan lapangan futsal dan basket. Fasilitas modern dan parkir luas.', 'image': 'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=800', 'jenis': 'FUTSAL', 'harga': 155000, 'capacity': 10, 'address': 'Jalan Garuni 3, Sleman', 'lat': -7.775974, 'lng': 110.411781},
      {'nama_lapangan': 'Toronto Futsal', 'description': 'Lapangan futsal di Wonogiri dengan suasana asri. Rumput sintetis tebal dan nyaman di kaki.', 'image': 'https://www.bing.com/th?id=OLC.OZMPSJgU/JJfzw480x360&pid=Local', 'jenis': 'FUTSAL', 'harga': 110000, 'capacity': 10, 'address': 'Jalan Wonogiri Pacitan, Wonogiri', 'lat': -7.953000, 'lng': 110.931503},
      {'nama_lapangan': 'FA Futsal', 'description': 'Lapangan futsal keluarga dengan harga ekonomis. Cocok untuk main santai bareng keluarga atau teman kantor.', 'image': 'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=800', 'jenis': 'FUTSAL', 'harga': 125000, 'capacity': 10, 'address': 'Jl. Joyoningrat No.km 4, Magelang', 'lat': -7.595958, 'lng': 110.335518},
      {'nama_lapangan': 'Futsal Parangtritis', 'description': 'Lapangan futsal dekat pantai Parangtritis. Main futsal sambil menikmati udara pantai yang segar.', 'image': 'https://images.unsplash.com/photo-1553778263-73a83bab9b0c?w=800', 'jenis': 'FUTSAL', 'harga': 105000, 'capacity': 10, 'address': 'Jalan Parang Tritis, Bantul', 'lat': -7.962426, 'lng': 110.321671},
      {'nama_lapangan': 'S Class Futsal', 'description': 'Lapangan futsal kelas premium di Solo dengan fasilitas VIP lounge dan tribun penonton yang nyaman.', 'image': 'https://www.bing.com/th?id=OLC.zyMyvBWlYiQ5XQ480x360&pid=Local', 'jenis': 'FUTSAL', 'harga': 190000, 'capacity': 10, 'address': 'Jl. Urip Sumoharjo No. 140, Surakarta', 'lat': -7.561672, 'lng': 110.836235},
      {'nama_lapangan': 'Empat R. Futsal', 'description': 'Lapangan futsal dengan 4 court tersedia. Bisa booking sekaligus untuk turnamen atau event besar.', 'image': 'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?w=800', 'jenis': 'FUTSAL', 'harga': 140000, 'capacity': 10, 'address': 'Jl. Parangtritis SLT, Kota Yogyakarta', 'lat': -7.825900, 'lng': 110.367699},
      {'nama_lapangan': 'Golden Goal Futsal', 'description': 'Lapangan futsal di area Pogung dengan rumput sintetis import. Sering dipakai untuk liga futsal kampus.', 'image': 'https://images.unsplash.com/photo-1606925797300-0b35e9d1794e?w=800', 'jenis': 'FUTSAL', 'harga': 150000, 'capacity': 10, 'address': 'Jl. Pogung Raya, Mlati, Sleman', 'lat': -7.757432, 'lng': 110.374779},
      {'nama_lapangan': 'Danareal Futsal', 'description': 'Lapangan futsal di Wonosobo dengan view pegunungan. Udara sejuk dan lapangan terawat dengan baik.', 'image': 'https://www.bing.com/th?id=OLC.MZMTRPXqgSqw/A480x360&pid=Local', 'jenis': 'FUTSAL', 'harga': 115000, 'capacity': 10, 'address': 'Wonosobo, Jawa Tengah', 'lat': -7.385088, 'lng': 109.967842},
      {'nama_lapangan': 'Jakal 7 Futsal', 'description': 'Lapangan futsal legendaris di Jalan Kaliurang. Favorit mahasiswa UGM dan UII untuk main futsal.', 'image': 'https://images.unsplash.com/photo-1577223625816-7546f13df25d?w=800', 'jenis': 'FUTSAL', 'harga': 160000, 'capacity': 10, 'address': 'Jalan Kaliurang, KM 7.8 No. 67, Sinduharjo, Sleman', 'lat': -7.732071, 'lng': 110.396667},
      {'nama_lapangan': 'X-tra FUTSAL', 'description': 'Lapangan futsal ekstra luas dengan fasilitas ekstra lengkap. Ada kantin dan mushola yang bersih.', 'image': 'https://images.unsplash.com/photo-1624880357913-a8539238245b?w=800', 'jenis': 'FUTSAL', 'harga': 145000, 'capacity': 10, 'address': 'Kalasan, Sleman', 'lat': -7.734427, 'lng': 110.450096},
      {'nama_lapangan': 'Futsal Soccer Delanggu', 'description': 'Lapangan futsal di Delanggu dengan harga terjangkau. Cocok untuk latihan rutin tim futsal.', 'image': 'https://images.unsplash.com/photo-1560272564-c83b66b1ad12?w=800', 'jenis': 'FUTSAL', 'harga': 100000, 'capacity': 10, 'address': 'Jalan Delanggu Purbayan, Delanggu', 'lat': -7.624449, 'lng': 110.709091},
      {'nama_lapangan': 'Vgd Futsal', 'description': 'Lapangan futsal di Magelang dengan rumput sintetis baru. Drainase bagus dan tidak becek saat hujan.', 'image': 'https://www.bing.com/th?id=OLC.RKMFdozfttB5nw480x360&pid=Local', 'jenis': 'FUTSAL', 'harga': 130000, 'capacity': 10, 'address': 'Sawah, Sidomulyo, Salaman, Magelang', 'lat': -7.576900, 'lng': 110.146301},

      // BADMINTON COURTS (39 venues)
      {'nama_lapangan': 'Lapangan Badminton MOY', 'description': 'Lapangan badminton outdoor dengan net standar internasional. Cocok untuk latihan pagi atau sore.', 'image': 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800', 'jenis': 'BADMINTON', 'harga': 45000, 'capacity': 4, 'address': 'Cangkringan, Sleman', 'lat': -7.676954, 'lng': 110.464188},
      {'nama_lapangan': 'Gor Mini Badminton Sambilegi', 'description': 'GOR mini dengan 3 lapangan badminton indoor. Lantai karpet hijau dan pencahayaan terang.', 'image': 'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?w=800', 'jenis': 'BADMINTON', 'harga': 50000, 'capacity': 4, 'address': 'Jl. Teratai No.63, Depok, Sleman', 'lat': -7.776996, 'lng': 110.434090},
      {'nama_lapangan': 'GOR PHOENIX BADMINTON CENTER', 'description': 'Pusat badminton dengan 6 lapangan indoor. Sering dipakai untuk turnamen tingkat kota.', 'image': 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800', 'jenis': 'BADMINTON', 'harga': 65000, 'capacity': 4, 'address': 'Jl. Sumberan Baru No.254e, Yogyakarta', 'lat': -7.782492, 'lng': 110.348251},
      {'nama_lapangan': 'Lap Badminton Derkuku', 'description': 'Lapangan badminton sederhana dengan harga mahasiswa. Cocok untuk main santai bareng teman.', 'image': 'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?w=800', 'jenis': 'BADMINTON', 'harga': 35000, 'capacity': 4, 'address': 'Gg. Derkuku, Depok, Sleman', 'lat': -7.765920, 'lng': 110.420242},
      {'nama_lapangan': 'Chimpling Badminton', 'description': 'Lapangan badminton di area Pakem dengan udara sejuk pegunungan. Nyaman untuk main pagi hari.', 'image': 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800', 'jenis': 'BADMINTON', 'harga': 40000, 'capacity': 4, 'address': 'Pakem, Sleman', 'lat': -7.661591, 'lng': 110.425629},
      {'nama_lapangan': 'Gor Jambon Badminton Center', 'description': 'GOR badminton dengan lantai kayu solid. Favorit atlet badminton untuk latihan serius.', 'image': 'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?w=800', 'jenis': 'BADMINTON', 'harga': 55000, 'capacity': 4, 'address': 'Jalan Jambon, Sleman', 'lat': -7.764900, 'lng': 110.349297},
      {'nama_lapangan': 'GOR Badminton Kelurahan Kricak', 'description': 'GOR milik kelurahan dengan harga terjangkau. Bersih dan terawat dengan baik.', 'image': 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800', 'jenis': 'BADMINTON', 'harga': 38000, 'capacity': 4, 'address': 'Tegalrejo, Yogyakarta', 'lat': -7.774188, 'lng': 110.359451},
      {'nama_lapangan': 'G O R Badminton Nusa Indah', 'description': 'Lapangan badminton indoor dengan AC. Nyaman untuk main siang hari tanpa kepanasan.', 'image': 'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?w=800', 'jenis': 'BADMINTON', 'harga': 60000, 'capacity': 4, 'address': 'Jalan godean km 4.5, Kota Yogyakarta', 'lat': -7.780436, 'lng': 110.346710},
      {'nama_lapangan': 'GOR GOTRO (Badminton)', 'description': 'GOR Gotong Royong dengan 4 lapangan badminton. Parkir luas dan kantin tersedia.', 'image': 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800', 'jenis': 'BADMINTON', 'harga': 48000, 'capacity': 4, 'address': 'Jalan Gotong Royong 1, Depok', 'lat': -7.767190, 'lng': 110.366928},
      {'nama_lapangan': 'GOR Badminton Tompeyan', 'description': 'Lapangan badminton klasik di area Tompeyan. Sudah berdiri lama dan punya banyak member setia.', 'image': 'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?w=800', 'jenis': 'BADMINTON', 'harga': 42000, 'capacity': 4, 'address': 'Jalan Tompeyan, Yogyakarta', 'lat': -7.784684, 'lng': 110.354805},
      {'nama_lapangan': 'GOR Badminton Seturan', 'description': 'Lokasi strategis di Seturan dekat kampus. Ramai dikunjungi mahasiswa untuk olahraga sore.', 'image': 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800', 'jenis': 'BADMINTON', 'harga': 52000, 'capacity': 4, 'address': 'Jalan Seturan 2, Sleman', 'lat': -7.768251, 'lng': 110.406670},
      {'nama_lapangan': 'Gedung Serbaguna Badminton Ds. Kudu', 'description': 'Gedung serbaguna yang bisa disewa untuk badminton. Lapangan luas dan bersih.', 'image': 'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?w=800', 'jenis': 'BADMINTON', 'harga': 40000, 'capacity': 4, 'address': 'Jl. Aren No.rt03/2, Sukoharjo', 'lat': -7.610826, 'lng': 110.790192},
      {'nama_lapangan': 'R Dwi Setyo GOR Badminton', 'description': 'GOR badminton di Boyolali dengan fasilitas lengkap. Cocok untuk turnamen dan latihan tim.', 'image': 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800', 'jenis': 'BADMINTON', 'harga': 45000, 'capacity': 4, 'address': 'Jl. Raya Nogosari, Boyolali', 'lat': -7.443441, 'lng': 110.713295},
      {'nama_lapangan': 'GOR B&F Kere Elit', 'description': 'GOR dengan lapangan badminton dan futsal. Bisa booking paket hemat untuk dua olahraga.', 'image': 'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?w=800', 'jenis': 'BADMINTON', 'harga': 50000, 'capacity': 4, 'address': 'Semin, Gunungkidul', 'lat': -7.866258, 'lng': 110.744194},
      {'nama_lapangan': 'Gor badminton Mergangsan', 'description': 'Lapangan badminton di tengah kota Jogja. Akses mudah dan dekat dengan berbagai fasilitas umum.', 'image': 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800', 'jenis': 'BADMINTON', 'harga': 47000, 'capacity': 4, 'address': 'Mergangsan, Yogyakarta', 'lat': -7.807073, 'lng': 110.378342},
      {'nama_lapangan': 'Gor Badminton Bp.Marino', 'description': 'Lapangan badminton pribadi yang dibuka untuk umum. Suasana homey dan nyaman.', 'image': 'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?w=800', 'jenis': 'BADMINTON', 'harga': 43000, 'capacity': 4, 'address': 'Tempuran, Sukoharjo', 'lat': -7.675136, 'lng': 110.781532},
      {'nama_lapangan': 'GBK (Gelora Badminton Kebon)', 'description': 'Gelora badminton dengan nama unik. Lapangan standar dan harga bersahabat.', 'image': 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800', 'jenis': 'BADMINTON', 'harga': 40000, 'capacity': 4, 'address': 'Trucuk, Klaten', 'lat': -7.726161, 'lng': 110.698402},
      {'nama_lapangan': 'Onggomertan Badminton Court', 'description': 'Lapangan badminton di area perumahan Onggomertan. Tenang dan cocok untuk latihan fokus.', 'image': 'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?w=800', 'jenis': 'BADMINTON', 'harga': 46000, 'capacity': 4, 'address': 'Jalan Muron, Sleman', 'lat': -7.773989, 'lng': 110.428124},
      {'nama_lapangan': 'Lapangan Badminton Temanggal', 'description': 'Lapangan badminton outdoor di area Temanggal. Udara segar dan view sawah yang asri.', 'image': 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800', 'jenis': 'BADMINTON', 'harga': 38000, 'capacity': 4, 'address': 'Manggal, Purwomartani Kalasan, Sleman', 'lat': -7.779049, 'lng': 110.453194},
      {'nama_lapangan': 'Lapangan Badminton Blotan', 'description': 'Lapangan badminton sederhana dengan net standar. Harga murah dan cocok untuk main santai.', 'image': 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800', 'jenis': 'BADMINTON', 'harga': 35000, 'capacity': 4, 'address': 'Jalan Blotan Raya, Sleman', 'lat': -7.736029, 'lng': 110.415772},
      {'nama_lapangan': 'Gor Joko Badminton', 'description': 'GOR badminton di Solo dengan lantai karpet biru. Sering dipakai untuk latihan atlet daerah.', 'image': 'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?w=800', 'jenis': 'BADMINTON', 'harga': 50000, 'capacity': 4, 'address': 'Jl. Kutai VI C, Surakarta', 'lat': -7.544771, 'lng': 110.801338},
      {'nama_lapangan': 'Sanguku Badminton Hall', 'description': 'Hall badminton indoor dengan 5 lapangan. Fasilitas modern dan AC yang dingin.', 'image': 'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?w=800', 'jenis': 'BADMINTON', 'harga': 58000, 'capacity': 4, 'address': 'Jl. Baladewa No.5, Depok, Sleman', 'lat': -7.774796, 'lng': 110.416824},
      {'nama_lapangan': 'Gor Badminton Gandok Mulya', 'description': 'GOR badminton di area Gandok dengan parkir luas. Cocok untuk acara turnamen.', 'image': 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800', 'jenis': 'BADMINTON', 'harga': 48000, 'capacity': 4, 'address': 'Jalan Gandok Baru, Sleman', 'lat': -7.761100, 'lng': 110.388199},
      {'nama_lapangan': 'Gor sadewa jogja badminton', 'description': 'Lapangan badminton dengan nama Sadewa. Lantai karpet merah dan net berkualitas.', 'image': 'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?w=800', 'jenis': 'BADMINTON', 'harga': 52000, 'capacity': 4, 'address': 'Jl. Cendrawasih No.6, Mlati, Sleman', 'lat': -7.756099, 'lng': 110.364204},
      {'nama_lapangan': 'Lapangan Badminton Klebengan', 'description': 'Lapangan badminton legendaris di Klebengan. Sudah ada sejak lama dan punya banyak penggemar.', 'image': 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800', 'jenis': 'BADMINTON', 'harga': 45000, 'capacity': 4, 'address': 'Jalan Kaliurang, Sleman', 'lat': -7.761698, 'lng': 110.380524},
      {'nama_lapangan': 'Sewa Lapangan Badminton Patukan', 'description': 'Lapangan badminton di Patukan dengan sistem sewa per jam. Fleksibel dan harga terjangkau.', 'image': 'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?w=800', 'jenis': 'BADMINTON', 'harga': 40000, 'capacity': 4, 'address': 'Jalan Sidoarum, Sleman', 'lat': -7.794600, 'lng': 110.322800},
      {'nama_lapangan': 'Ancuku Badminton Center', 'description': 'Pusat badminton dengan program membership. Member dapat diskon dan fasilitas ekstra.', 'image': 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800', 'jenis': 'BADMINTON', 'harga': 55000, 'capacity': 4, 'address': 'Jalan Tino Sidin 16, Kasihan, Bantul', 'lat': -7.799434, 'lng': 110.344841},
      {'nama_lapangan': 'GOR Badminton BLPT', 'description': 'GOR badminton milik BLPT dengan fasilitas lengkap. Sering dipakai untuk event resmi.', 'image': 'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?w=800', 'jenis': 'BADMINTON', 'harga': 50000, 'capacity': 4, 'address': 'Jl. Kyai Mojo No.70, Tegalrejo, Yogyakarta', 'lat': -7.779402, 'lng': 110.354713},
      {'nama_lapangan': 'Lap Badminton Tompeyan', 'description': 'Lapangan badminton outdoor di Tompeyan. Cocok untuk main pagi atau sore hari.', 'image': 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800', 'jenis': 'BADMINTON', 'harga': 38000, 'capacity': 4, 'address': 'Jl. Kyai Mojo (Tompeyan), Yogyakarta', 'lat': -7.784181, 'lng': 110.354767},
      {'nama_lapangan': 'Lapangan Badminton Nyai Adhi Soro', 'description': 'Lapangan badminton di area Nyai Adhi Soro. Tenang dan jarang ramai.', 'image': 'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?w=800', 'jenis': 'BADMINTON', 'harga': 42000, 'capacity': 4, 'address': 'Jalan Nyai Adhi Soro, Yogyakarta', 'lat': -7.815132, 'lng': 110.393562},
      {'nama_lapangan': 'Murah Jati Badminton Courts', 'description': 'Sesuai namanya, lapangan badminton dengan harga murah. Cocok untuk mahasiswa dan pelajar.', 'image': 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800', 'jenis': 'BADMINTON', 'harga': 35000, 'capacity': 4, 'address': 'Jl. Imogiri Barat No.174, Sewon, Bantul', 'lat': -7.831605, 'lng': 110.374847},
      {'nama_lapangan': 'GOR Badminton Wonocatur', 'description': 'GOR badminton di Wonocatur dengan lantai kayu. Nyaman dan tidak licin.', 'image': 'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?w=800', 'jenis': 'BADMINTON', 'harga': 48000, 'capacity': 4, 'address': 'Jalan wonocatur, Bantul', 'lat': -7.801903, 'lng': 110.410500},
      {'nama_lapangan': 'GOR Pandiga', 'description': 'GOR Pandiga dengan 4 lapangan badminton indoor. Fasilitas toilet dan kantin tersedia.', 'image': 'https://www.bing.com/th?id=OLC.bqFDPT3K3hoPjw480x360&pid=Local', 'jenis': 'BADMINTON', 'harga': 55000, 'capacity': 4, 'address': 'Jalan Corongan, Sleman', 'lat': -7.778805, 'lng': 110.421471},
      {'nama_lapangan': 'Gor Badminton H. Bejo Meubel', 'description': 'Lapangan badminton di area meubel H. Bejo. Unik dan harga terjangkau.', 'image': 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800', 'jenis': 'BADMINTON', 'harga': 43000, 'capacity': 4, 'address': 'Lorog, Sukoharjo', 'lat': -7.747747, 'lng': 110.796364},
      {'nama_lapangan': 'Lapangan Badminton Minomartani', 'description': 'Lapangan badminton di Minomartani dengan suasana pedesaan yang asri.', 'image': 'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?w=800', 'jenis': 'BADMINTON', 'harga': 40000, 'capacity': 4, 'address': 'Jalan Lele 4, Sleman', 'lat': -7.740500, 'lng': 110.406502},
      {'nama_lapangan': 'GOR Badminton Ngabean', 'description': 'GOR badminton di Ngabean dengan parkir motor yang luas. Aman dan nyaman.', 'image': 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800', 'jenis': 'BADMINTON', 'harga': 45000, 'capacity': 4, 'address': 'Ngaglik, Sleman', 'lat': -7.740523, 'lng': 110.392876},
      {'nama_lapangan': 'Lap Badminton 06', 'description': 'Lapangan badminton nomor 06 di Tridadi. Sederhana tapi terawat dengan baik.', 'image': 'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?w=800', 'jenis': 'BADMINTON', 'harga': 38000, 'capacity': 4, 'address': 'Beran Kidul Tridadi Sleman, Yogyakarta', 'lat': -7.722509, 'lng': 110.351509},
      {'nama_lapangan': 'GOR Badminton Sabdodadi', 'description': 'GOR badminton di Sabdodadi Bantul. Lapangan luas dan pencahayaan bagus.', 'image': 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800', 'jenis': 'BADMINTON', 'harga': 42000, 'capacity': 4, 'address': 'Jalan Sadewa, Bantul', 'lat': -7.889200, 'lng': 110.354500},

      // BASKETBALL COURTS (10 venues)
      {'nama_lapangan': 'UTAMA basketball - GOR victory', 'description': 'Lapangan basket indoor premium dengan lantai parket profesional. Sering dipakai untuk pertandingan resmi.', 'image': 'https://www.bing.com/th?id=OLC.O9T05X37dgf/vg480x360&pid=Local', 'jenis': 'BASKETBALL', 'harga': 180000, 'capacity': 10, 'address': 'Jl. Veteran 19-23, Yogyakarta City', 'lat': -7.804408, 'lng': 110.394829},
      {'nama_lapangan': 'UMY Basketball Court', 'description': 'Lapangan basket kampus UMY yang dibuka untuk umum. Fasilitas standar universitas dan harga mahasiswa.', 'image': 'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=800', 'jenis': 'BASKETBALL', 'harga': 120000, 'capacity': 10, 'address': 'Jalan Ringroad Barat, Sleman', 'lat': -7.750537, 'lng': 110.340988},
      {'nama_lapangan': 'ISLAMIC CENTRE Basketball Court', 'description': 'Lapangan basket di Islamic Centre Solo. Lapangan outdoor dengan ring standar NBA.', 'image': 'https://images.unsplash.com/photo-1608245449230-4ac19066d2d0?w=800', 'jenis': 'BASKETBALL', 'harga': 95000, 'capacity': 10, 'address': 'Jalan Untung Suropati 134, Surakarta', 'lat': -7.578925, 'lng': 110.837250},
      {'nama_lapangan': 'Basketball Court SMA N 2 Bantul', 'description': 'Lapangan basket sekolah yang bisa disewa untuk umum. Cocok untuk latihan tim atau turnamen sekolah.', 'image': 'https://images.unsplash.com/photo-1519861531473-9200262188bf?w=800', 'jenis': 'BASKETBALL', 'harga': 85000, 'capacity': 10, 'address': 'Jalan RA Kartini Trirenggo Bantul, Bantul', 'lat': -7.893733, 'lng': 110.338516},
      {'nama_lapangan': 'Bima Perkasa Basketball Academy', 'description': 'Akademi basket dengan program pelatihan profesional. Lapangan indoor dengan AC dan tribun penonton.', 'image': 'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=800', 'jenis': 'BASKETBALL', 'harga': 165000, 'capacity': 10, 'address': 'Jl. Miliran III No.400, Umbulharjo, Yogyakarta', 'lat': -7.796956, 'lng': 110.389915},
      {'nama_lapangan': 'Mataram Basketball Academy', 'description': 'Akademi basket Mataram dengan pelatih bersertifikat. Fasilitas lengkap untuk latihan serius.', 'image': 'https://images.unsplash.com/photo-1608245449230-4ac19066d2d0?w=800', 'jenis': 'BASKETBALL', 'harga': 155000, 'capacity': 10, 'address': 'Jl. Veteran No.23, Umbulharjo, Yogyakarta', 'lat': -7.803599, 'lng': 110.394936},
      {'nama_lapangan': 'Sport Academy Yogyakarta Basketball', 'description': 'Lapangan basket di Sport Academy dengan lantai vinyl. Bisa sekaligus booking futsal untuk variasi.', 'image': 'https://images.unsplash.com/photo-1519861531473-9200262188bf?w=800', 'jenis': 'BASKETBALL', 'harga': 145000, 'capacity': 10, 'address': 'Jalan Garuni 3, Sleman', 'lat': -7.775974, 'lng': 110.411781},
      {'nama_lapangan': 'BBS Basketball Court', 'description': 'Lapangan basket di area BBS Semarang. Outdoor dengan pencahayaan LED untuk main malam.', 'image': 'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=800', 'jenis': 'BASKETBALL', 'harga': 110000, 'capacity': 10, 'address': 'Jalan Jangli Boulevard, Semarang', 'lat': -7.032990, 'lng': 110.430656},
      {'nama_lapangan': 'Eagles Workout Basketball', 'description': 'Lapangan basket dengan program workout khusus. Cocok untuk yang ingin latihan fisik sambil main basket.', 'image': 'https://images.unsplash.com/photo-1608245449230-4ac19066d2d0?w=800', 'jenis': 'BASKETBALL', 'harga': 125000, 'capacity': 10, 'address': 'Gang Candi, Kutoarjo', 'lat': -7.716215, 'lng': 109.919739},
      {'nama_lapangan': 'Basketball Court UNDIP', 'description': 'Lapangan basket kampus UNDIP Semarang. Fasilitas universitas dengan harga terjangkau.', 'image': 'https://images.unsplash.com/photo-1519861531473-9200262188bf?w=800', 'jenis': 'BASKETBALL', 'harga': 100000, 'capacity': 10, 'address': 'Jl. Prof. Soedarto, Tembalang, Semarang', 'lat': -7.054595, 'lng': 110.431099},

      // TENNIS COURTS (18 venues)
      {'nama_lapangan': 'Persatuan Tenis Meja Suryanaga', 'description': 'Pusat tenis meja dengan meja standar internasional. Sering dipakai untuk latihan atlet PON.', 'image': 'https://www.bing.com/th?id=OLC.5tk5MKsWw4+QWQ480x360&pid=Local', 'jenis': 'TENNIS', 'harga': 85000, 'capacity': 4, 'address': 'Jl. Suryoputran No.21, Kraton, Yogyakarta', 'lat': -7.809641, 'lng': 110.365562},
      {'nama_lapangan': 'Tennis Court at Hyatt Regency', 'description': 'Lapangan tenis hotel bintang 5 Hyatt Regency. Fasilitas mewah dengan pemandangan indah.', 'image': 'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?w=800', 'jenis': 'TENNIS', 'harga': 120000, 'capacity': 4, 'address': 'Hyatt Regency Yogyakarta, Jl. Palagan Tentara Pelajar, Sleman', 'lat': -7.727578, 'lng': 110.380234},
      {'nama_lapangan': 'Lapangan Tenis FIK UNY', 'description': 'Lapangan tenis Fakultas Ilmu Keolahragaan UNY. Hard court dengan net standar ITF.', 'image': 'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?w=800', 'jenis': 'TENNIS', 'harga': 75000, 'capacity': 4, 'address': 'Jl. Colombo No.1, Catur tunggal, Sleman', 'lat': -7.774910, 'lng': 110.386398},
      {'nama_lapangan': 'Bausasran Tennis Club', 'description': 'Klub tenis eksklusif di Bausasran. Member club dengan fasilitas premium dan pelatih profesional.', 'image': 'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?w=800', 'jenis': 'TENNIS', 'harga': 110000, 'capacity': 4, 'address': 'Jalan Dokter Sutomo, Yogyakarta', 'lat': -7.795648, 'lng': 110.376686},
      {'nama_lapangan': 'Lapangan Tennis Timoho', 'description': 'Lapangan tenis di area Timoho yang ramai. Dekat dengan berbagai fasilitas umum.', 'image': 'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?w=800', 'jenis': 'TENNIS', 'harga': 80000, 'capacity': 4, 'address': 'Gondokusuman, Yogyakarta', 'lat': -7.791054, 'lng': 110.391037},
      {'nama_lapangan': 'Tennis Court Casa Grande', 'description': 'Lapangan tenis di perumahan Casa Grande. Eksklusif dan terawat dengan sangat baik.', 'image': 'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?w=800', 'jenis': 'TENNIS', 'harga': 95000, 'capacity': 4, 'address': 'Depok, Sleman', 'lat': -7.760821, 'lng': 110.420166},
      {'nama_lapangan': 'Green Garden Tennis Sport', 'description': 'Lapangan tenis di Green Garden dengan suasana hijau dan asri. Nyaman untuk main pagi hari.', 'image': 'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?w=800', 'jenis': 'TENNIS', 'harga': 88000, 'capacity': 4, 'address': 'Perumahan Green Garden, Bantul', 'lat': -7.776700, 'lng': 110.349197},
      {'nama_lapangan': 'Lapangan Tennis TC', 'description': 'Lapangan tenis di Taman Cemara. Lokasi strategis dan mudah diakses.', 'image': 'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?w=800', 'jenis': 'TENNIS', 'harga': 70000, 'capacity': 4, 'address': 'Taman Cemara, Sleman', 'lat': -7.759302, 'lng': 110.420334},
      {'nama_lapangan': 'CV JOGJA TENNIS CHAMPIONSHIP', 'description': 'Pusat tenis yang sering mengadakan turnamen. Fasilitas lengkap untuk event besar.', 'image': 'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?w=800', 'jenis': 'TENNIS', 'harga': 100000, 'capacity': 4, 'address': 'Puri Gejayan Indah C-20, Sleman', 'lat': -7.764397, 'lng': 110.397232},
      {'nama_lapangan': 'Lapangan Tennis TSI', 'description': 'Lapangan tenis Taman Siswa Indah. Cocok untuk latihan rutin dan turnamen kecil.', 'image': 'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?w=800', 'jenis': 'TENNIS', 'harga': 75000, 'capacity': 4, 'address': 'Perumahan Taman Siswa Indah, Mergangsan, Yogyakarta', 'lat': -7.809029, 'lng': 110.374573},
      {'nama_lapangan': 'Outdoor Tennis Courts UMY', 'description': 'Lapangan tenis outdoor kampus UMY. Harga mahasiswa dan bisa dipakai untuk umum.', 'image': 'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?w=800', 'jenis': 'TENNIS', 'harga': 65000, 'capacity': 4, 'address': 'Kutu Tegal, Sinduadi, Sleman', 'lat': -7.754905, 'lng': 110.365211},
      {'nama_lapangan': 'UII Tennis Court', 'description': 'Lapangan tenis kampus UII dengan fasilitas standar universitas. Buka untuk umum di luar jam kuliah.', 'image': 'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?w=800', 'jenis': 'TENNIS', 'harga': 80000, 'capacity': 4, 'address': 'Jalan Kaliurang km 14,5, Sleman', 'lat': -7.694332, 'lng': 110.418556},
      {'nama_lapangan': 'Tennis Outdoor Perum GAP', 'description': 'Lapangan tenis outdoor di perumahan GAP. Eksklusif untuk warga dan tamu.', 'image': 'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?w=800', 'jenis': 'TENNIS', 'harga': 90000, 'capacity': 4, 'address': 'Kompleks Perum GAP, Sleman', 'lat': -7.778419, 'lng': 110.351036},
      {'nama_lapangan': 'Bina Marga Tennis Court', 'description': 'Lapangan tenis di perumahan Bina Marga Magelang. Suasana sejuk pegunungan.', 'image': 'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?w=800', 'jenis': 'TENNIS', 'harga': 70000, 'capacity': 4, 'address': 'Perumahan Bina Marga, Magelang', 'lat': -7.495466, 'lng': 110.208023},
      {'nama_lapangan': 'Tennis Court Palagan', 'description': 'Lapangan tenis di Jalan Palagan. Akses mudah dan parkir luas.', 'image': 'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?w=800', 'jenis': 'TENNIS', 'harga': 85000, 'capacity': 4, 'address': 'Jalan Palagan Tentara Pelajar, Sleman', 'lat': -7.739800, 'lng': 110.375099},
      {'nama_lapangan': 'Lapangan Tennis Indoor Manahan', 'description': 'Lapangan tenis indoor di stadion Manahan Solo. AC dan pencahayaan sempurna.', 'image': 'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?w=800', 'jenis': 'TENNIS', 'harga': 115000, 'capacity': 4, 'address': 'Jalan Adi Sucipto, Surakarta', 'lat': -7.556100, 'lng': 110.807701},
      {'nama_lapangan': 'Lapangan Tennis Dodiklatpur', 'description': 'Lapangan tenis milik Dodiklatpur Klaten. Fasilitas militer yang dibuka untuk umum.', 'image': 'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?w=800', 'jenis': 'TENNIS', 'harga': 75000, 'capacity': 4, 'address': 'Jalan Kesatrian, Klaten', 'lat': -7.736800, 'lng': 110.589996},
      {'nama_lapangan': 'T Bakulan Tennis', 'description': 'Lapangan tenis di area Bakulan dekat pantai. Udara segar dan view pantai yang indah.', 'image': 'https://www.bing.com/th?id=OLC.hCXWdroC2Cz5ig480x360&pid=Local', 'jenis': 'TENNIS', 'harga': 80000, 'capacity': 4, 'address': 'Jalan Parangtritis 5, Bantul', 'lat': -7.924979, 'lng': 110.349060},

      // MINI SOCCER FIELDS (16 venues)
      {'nama_lapangan': 'Lapangan Mini Soccer Kepuharjo', 'description': 'Lapangan mini soccer di kaki Gunung Merapi. Rumput sintetis premium dengan view pegunungan yang spektakuler.', 'image': 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800', 'jenis': 'MINI_SOCCER', 'harga': 320000, 'capacity': 14, 'address': 'Cangkringan, Sleman', 'lat': -7.627169, 'lng': 110.446808},
      {'nama_lapangan': 'Adyoko Mini Soccer', 'description': 'Lapangan mini soccer dengan rumput sintetis grade A. Drainase sempurna dan tidak becek saat hujan.', 'image': 'https://images.unsplash.com/photo-1589487391730-58f20eb2c308?w=800', 'jenis': 'MINI_SOCCER', 'harga': 280000, 'capacity': 14, 'address': 'Dukuh Kumbulan, Sukoharjo', 'lat': -7.648455, 'lng': 110.861702},
      {'nama_lapangan': 'CH4 Arena Mini Soccer', 'description': 'Arena mini soccer modern dengan tribun penonton. Cocok untuk turnamen dan liga mini soccer.', 'image': 'https://images.unsplash.com/photo-1551958219-acbc608c6377?w=800', 'jenis': 'MINI_SOCCER', 'harga': 310000, 'capacity': 14, 'address': 'Jl. Dieng.Km. 05, Krasak, Wonosobo', 'lat': -7.322485, 'lng': 109.913223},
      {'nama_lapangan': 'D Soccer Stadium Mini Soccer', 'description': 'Stadion mini soccer dengan fasilitas lengkap. Ruang ganti, toilet, dan kantin tersedia.', 'image': 'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=800', 'jenis': 'MINI_SOCCER', 'harga': 295000, 'capacity': 14, 'address': 'Jl. Sedayu Klp. No.8kel, Genuk, Semarang', 'lat': -6.977642, 'lng': 110.479187},
      {'nama_lapangan': 'The Arena Mini Soccer', 'description': 'Arena mini soccer premium dengan pencahayaan LED profesional. Bisa main sampai malam tanpa silau.', 'image': 'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=800', 'jenis': 'MINI_SOCCER', 'harga': 340000, 'capacity': 14, 'address': 'Dr. Suratmo No. 311 A, Kota Semarang', 'lat': -6.997260, 'lng': 110.381447},
      {'nama_lapangan': 'Orso Mini Soccer', 'description': 'Lapangan mini soccer dengan rumput tebal dan empuk. Nyaman untuk sliding tackle.', 'image': 'https://images.unsplash.com/photo-1553778263-73a83bab9b0c?w=800', 'jenis': 'MINI_SOCCER', 'harga': 270000, 'capacity': 14, 'address': 'Jl. Jangli Raya No.11, Candisari, Semarang', 'lat': -7.023070, 'lng': 110.426849},
      {'nama_lapangan': 'GAMA MINI SOCCER', 'description': 'Lapangan mini soccer dekat kampus dengan harga mahasiswa. Sering dipakai untuk liga antar fakultas.', 'image': 'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?w=800', 'jenis': 'MINI_SOCCER', 'harga': 260000, 'capacity': 14, 'address': 'Jl. Gendong Raya, Tembalang, Semarang', 'lat': -7.040607, 'lng': 110.467888},
      {'nama_lapangan': 'MINI SOCCER PEDURUNGAN', 'description': 'Lapangan mini soccer di Pedurungan dengan fasilitas modern. Parkir luas dan aman.', 'image': 'https://images.unsplash.com/photo-1606925797300-0b35e9d1794e?w=800', 'jenis': 'MINI_SOCCER', 'harga': 275000, 'capacity': 14, 'address': 'Jl. Plamongan Elok IV, Pedurungan, Semarang', 'lat': -7.022039, 'lng': 110.477547},
      {'nama_lapangan': 'MINI SOCCER PRO_GT', 'description': 'Lapangan mini soccer profesional di Temanggung. Rumput import dan garis lapangan yang jelas.', 'image': 'https://images.unsplash.com/photo-1577223625816-7546f13df25d?w=800', 'jenis': 'MINI_SOCCER', 'harga': 285000, 'capacity': 14, 'address': 'Gg. Bougenfil, Temanggung', 'lat': -7.325530, 'lng': 110.171913},
      {'nama_lapangan': 'MV ARENA MINI SOCCER', 'description': 'Arena mini soccer di Bandung dengan konsep modern. Fasilitas kafe dan lounge area.', 'image': 'https://images.unsplash.com/photo-1624880357913-a8539238245b?w=800', 'jenis': 'MINI_SOCCER', 'harga': 350000, 'capacity': 14, 'address': 'Jl. Raya Ujung Berung No.46a, Cinambo, Bandung', 'lat': -6.915221, 'lng': 107.696823},
      {'nama_lapangan': 'Lapangan Mini Soccer Depok', 'description': 'Lapangan mini soccer di area Depok Sleman. Dekat kampus dan mudah diakses.', 'image': 'https://images.unsplash.com/photo-1560272564-c83b66b1ad12?w=800', 'jenis': 'MINI_SOCCER', 'harga': 290000, 'capacity': 14, 'address': 'Depok, Sleman', 'lat': -7.784451, 'lng': 110.419792},
      {'nama_lapangan': 'KALISI Mini Soccer', 'description': 'Lapangan mini soccer di Kalisi Bantul. Suasana pedesaan yang asri dan tenang.', 'image': 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800', 'jenis': 'MINI_SOCCER', 'harga': 265000, 'capacity': 14, 'address': 'Jl. Kalisi 2, Kasihan, Bantul', 'lat': -7.841572, 'lng': 110.342072},
      {'nama_lapangan': 'METRO MINI SOCCER', 'description': 'Lapangan mini soccer dengan lokasi strategis di pinggir jalan raya. Mudah ditemukan.', 'image': 'https://images.unsplash.com/photo-1589487391730-58f20eb2c308?w=800', 'jenis': 'MINI_SOCCER', 'harga': 300000, 'capacity': 14, 'address': 'Jl. Sunan Geseng No.16, Magelang', 'lat': -7.374660, 'lng': 110.325119},
      {'nama_lapangan': 'CV GOLDEN MINI SOCCER', 'description': 'Lapangan mini soccer golden dengan rumput emas (kuning). Unik dan instagramable.', 'image': 'https://images.unsplash.com/photo-1551958219-acbc608c6377?w=800', 'jenis': 'MINI_SOCCER', 'harga': 330000, 'capacity': 14, 'address': 'Jl. KI Mangunsarkoro No. 20, Kota Semarang', 'lat': -6.977512, 'lng': 110.428307},
      {'nama_lapangan': 'Mini Soccer Perbi', 'description': 'Lapangan mini soccer Permata Biru dengan fasilitas lengkap. Ada mushola dan kantin 24 jam.', 'image': 'https://www.bing.com/th?id=OLC.Nqcu66YDZ0jhFA480x360&pid=Local', 'jenis': 'MINI_SOCCER', 'harga': 315000, 'capacity': 14, 'address': 'Jl Akasia Raya, Permata Biru No 01, Cileunyi, Bandung', 'lat': -6.946404, 'lng': 107.733086},
      {'nama_lapangan': 'CG Mini Soccer', 'description': 'Lapangan mini soccer di Curug Tangerang. Rumput sintetis baru dan sangat terawat.', 'image': 'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=800', 'jenis': 'MINI_SOCCER', 'harga': 305000, 'capacity': 14, 'address': 'Jl. Cukang Galih Kidul No.1, Curug, Tangerang', 'lat': -6.260604, 'lng': 106.539528},
    ];

    // Insert all venues into database
    for (var venue in realVenues) {
      int insertedId = await db.insert('lapangans', venue);

      // Assign default amenities
      await db.insert('lapangan_amenities', {
        'lapangan_id': insertedId,
        'amenity_id': 1, // Toilet
      });
      await db.insert('lapangan_amenities', {
        'lapangan_id': insertedId,
        'amenity_id': 3, // Parkir
      });

      // Add Kantin for expensive venues (>= 150k)
      if (venue['harga'] >= 150000) {
        await db.insert('lapangan_amenities', {
          'lapangan_id': insertedId,
          'amenity_id': 2, // Kantin
        });
      }

      // Add Mushola for very expensive venues (>= 250k)
      if (venue['harga'] >= 250000) {
        await db.insert('lapangan_amenities', {
          'lapangan_id': insertedId,
          'amenity_id': 4, // Mushola
        });
      }
    }
  }

  // CRUD METHODS
  
  Future<int> registerUser(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('users', row);
  }

  Future<int> insertUser(Map<String, dynamic> user) async {
    Database db = await instance.database;
    return await db.insert('users', user);
  }

  Future<Map<String, dynamic>?> getUser(String username, String password) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  // Update password user
  Future<int> updateUserPassword(String username, String hashedPassword) async {
    Database db = await instance.database;
    return await db.update(
      'users',
      {'password': hashedPassword},
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  Future<int> insertLapangan(
    String nama,
    String jenis,
    int harga,
    double lat,
    double lng,
    String description,
    String address,
  ) async {
    Database db = await instance.database;
    return await db.insert('lapangans', {
      'nama_lapangan': nama,
      'description': description,
      'jenis': jenis,
      'harga': harga,
      'address': address,
      'lat': lat,
      'lng': lng,
    });
  }

  Future<int> insertBooking(Map<String, dynamic> data) async {
    Database db = await instance.database;
    return await db.insert('bookings', data);
  }

  Future<List<Map<String, dynamic>>> getBookings({int? userId}) async {
    Database db = await instance.database;
    if (userId != null) {
      return await db.query(
        'bookings',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'id DESC',
      );
    }
    return await db.query('bookings', orderBy: 'id DESC');
  }

  Future<int> createPayment(int bookingId, int amount, String method) async {
    Database db = await instance.database;
    return await db.insert('payments', {
      'booking_id': bookingId,
      'amount': amount,
      'method': method,
      'status': 'paid',
    });
  }

  Future<List<String>> getBookedTimes(int lapanganId, String tanggal) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> res = await db.query(
      'bookings',
      where: 'lapangan_id = ? AND tanggal = ?',
      whereArgs: [lapanganId, tanggal],
    );

    List<String> booked = [];
    for (var row in res) {
      String jamString = row['jam'] ?? '';
      if (jamString.isNotEmpty) {
        booked.addAll(jamString.split(',').map((e) => e.trim()));
      }
    }
    return booked;
  }

  Future<List<LapanganModel>> getAllLapangan() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> res = await db.query('lapangans');
    return List<LapanganModel>.from(res.map((x) => LapanganModel.fromMap(x)));
  }

  Future<int> updateLapangan(LapanganModel lapangan) async {
    Database db = await instance.database;
    return await db.update(
      'lapangans',
      lapangan.toMap(),
      where: 'id = ?',
      whereArgs: [lapangan.id],
    );
  }

  Future<int> deleteLapangan(int id) async {
    Database db = await instance.database;
    return await db.delete(
      'lapangans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // AMENITIES METHODS
  
  Future<List<Map<String, dynamic>>> getAllAmenities() async {
    Database db = await instance.database;
    return await db.query('amenities');
  }

  Future<List<Map<String, dynamic>>> getAmenitiesForLapangan(int lapanganId) async {
    Database db = await instance.database;
    return await db.rawQuery('''
      SELECT a.* FROM amenities a
      INNER JOIN lapangan_amenities la ON a.id = la.amenity_id
      WHERE la.lapangan_id = ?
    ''', [lapanganId]);
  }

  Future<void> saveAmenitiesForLapangan(int lapanganId, List<int> amenityIds) async {
    Database db = await instance.database;
    
    // Delete existing amenities
    await db.delete(
      'lapangan_amenities',
      where: 'lapangan_id = ?',
      whereArgs: [lapanganId],
    );
    
    // Insert new amenities
    for (int amenityId in amenityIds) {
      await db.insert('lapangan_amenities', {
        'lapangan_id': lapanganId,
        'amenity_id': amenityId,
      });
    }
  }

  // EMAIL & PHONE CHECK METHODS 
  
  Future<bool> checkEmailExists(String email) async {
    Database db = await instance.database;
    var res = await db.query(
      "users",
      where: "email = ?",
      whereArgs: [email],
    );
    return res.isNotEmpty;
  }

  Future<bool> checkPhoneExists(String phone) async {
    Database db = await instance.database;
    var res = await db.query(
      "users",
      where: "phone = ?",
      whereArgs: [phone],
    );
    return res.isNotEmpty;
  }

  Future<Map<String, dynamic>?> getUserByEmailOrUsername(String emailOrUsername) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'email = ? OR username = ?',
      whereArgs: [emailOrUsername, emailOrUsername],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<Map<String, dynamic>?> loginWithEmailOrUsername(
    String emailOrUsername,
    String password,
  ) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: '(username = ? OR email = ?) AND password = ?',
      whereArgs: [emailOrUsername, emailOrUsername, password],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  // UNIQUE VALIDATION METHODS (for edit profile)
  
  Future<bool> checkUsernameExistsExcept(String username, int userId) async {
    Database db = await instance.database;
    var res = await db.query(
      "users",
      where: "username = ? AND id != ?",
      whereArgs: [username, userId],
    );
    return res.isNotEmpty;
  }

  Future<bool> checkEmailExistsExcept(String email, int userId) async {
    Database db = await instance.database;
    var res = await db.query(
      "users",
      where: "email = ? AND id != ?",
      whereArgs: [email, userId],
    );
    return res.isNotEmpty;
  }

  Future<bool> checkPhoneExistsExcept(String phone, int userId) async {
    Database db = await instance.database;
    var res = await db.query(
      "users",
      where: "phone = ? AND id != ?",
      whereArgs: [phone, userId],
    );
    return res.isNotEmpty;
  }
}
