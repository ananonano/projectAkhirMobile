import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';

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
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'lapangin.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  // Fungsi Register User Baru
  Future<int> registerUser(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('users', row);
  }

  // Fungsi cek username biar nggak duplikat
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
    // 1. Tabel Users
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

    // 2. Tabel Lapangans
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
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

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

    // =========================================================
    // SEEDER (DUMMY DATA & REAL DATA) BIAR APLIKASI FULL
    // =========================================================

    // --- Insert Akun Admin (Password: admin123) ---
    await db.insert('users', {
      'username': 'admin',
      'password': 'f865b53623b121fd34ee5426c792e5c33af8c227', // SHA-1 admin123
      'name': 'Super Admin Lapangin',
      'role': 'admin',
    });

    // --- Insert Akun Geng TPM (Password: user123) ---
    String userPass =
        '95c946bf622ef93b0a211cd0fd028dfdfcf7e39e'; // SHA-1 user123
    await db.insert('users', {
      'username': 'danang',
      'password': userPass,
      'name': 'Danang Adiwibowo',
      'role': 'user',
    });
    await db.insert('users', {
      'username': 'vano',
      'password': userPass,
      'name': 'Vano',
      'role': 'user',
    });
    await db.insert('users', {
      'username': 'atilla',
      'password': userPass,
      'name': 'Mohammad Atilla Danadyaksa',
      'role': 'user',
    });
    await db.insert('users', {
      'username': 'najla',
      'password': userPass,
      'name': 'Najla',
      'role': 'user',
    });

    // --- Insert Amenities Dasar ---
    await db.insert('amenities', {'name': 'Toilet Bersih'}); // ID 1
    await db.insert('amenities', {'name': 'Kantin / Cafe'}); // ID 2
    await db.insert('amenities', {'name': 'Parkir Luas'}); // ID 3
    await db.insert('amenities', {'name': 'Mushola'}); // ID 4

    // ==========================================
    // SEEDING 30 DATA LAPANGAN REAL JOGJA
    // ==========================================
    List<Map<String, dynamic>> realJogjaCourts = [
      // --- FUTSAL (8 Lapangan) ---
      {
        'nama_lapangan': 'Planet Futsal Condongcatur',
        'description':
            'Lapangan vinyl berkualitas dengan tribun penonton, toilet bersih, dan parkir luas.',
        'image':
            'https://lh3.googleusercontent.com/grass-cs/ANxoTn0VKfbUwWAmLFqvP4a86r5BFyJRprDmDGMZPTgZytkVcyp_nP8GkIUulYY_6FXs3_72NDEjRckni5dzQKvedAH1cAlsgHPZy0Yh7yaUE01Y-nJHOn3dCwzAKm4MkXIQDxduakQ=s3072-w3072-h1552-rw',
        'jenis': 'FUTSAL',
        'harga': 180000,
        'capacity': 10,
        'address':
            'Jl. Ring Road Utara No.168, Ngringin, Condongcatur, Kec. Depok, Sleman',
        'lat': -7.760301,
        'lng': 110.408319,
      },
      {
        'nama_lapangan': 'Tifosi Futsal ',
        'description':
            'Futsal favorit tengah kota, rumput sintetis dan vinyl tersedia.',
        'image':
            'https://yogyaku.com/wp-content/uploads/2024/12/Tifosi-Futsal-yang-populer-di-Jogja.jpg',
        'jenis': 'FUTSAL',
        'harga': 150000,
        'capacity': 10,
        'address':
            'Jl. Sukonandi No.11, Semaki, Kec. Umbulharjo, Kota Yogyakarta',
        'lat': -7.799260,
        'lng': 110.381060,
      },
      {
        'nama_lapangan': 'Bardosono Happy Futsal',
        'description': 'Harga mahasiswa, lapangan nyaman untuk latihan rutin.',
        'image':
            'https://lh3.googleusercontent.com/p/AF1QipN0jw3jbOTatWpeLT1IqHSknsHyD24ukmTwC5t8=w243-h244-n-k-no-nu',
        'jenis': 'FUTSAL',
        'harga': 120000,
        'capacity': 10,
        'address': 'Jl. Prof. DR. Soepomo Sh, Warungboto, Kec. Umbulharjo',
        'lat': -7.807325,
        'lng': 110.389827,
      },
      {
        'nama_lapangan': 'Telaga Futsal 3',
        'description':
            'Lokasi strategis di Jalan Kaliurang, parkir motor luas, sirkulasi udara bagus.',
        'image':
            'https://lh3.googleusercontent.com/gps-cs-s/APNQkAFloKayHApwOLjyBRnxw2C5msocWPF-D5q6WKxTR_o3cJemQDxEkMxiNzVxzmZVQjVonrENTLz_KvbhlWJBHGUHzbI-QzzEwBogGHMXKkvf4dnuK_lSk39fldbOwUaec5d8OaY=s1360-w1360-h1020-rw',
        'jenis': 'FUTSAL',
        'harga': 130000,
        'capacity': 10,
        'address': 'Jl. Kaliurang KM 5.5, Sinduadi, Kec. Mlati, Sleman',
        'lat': -7.755210,
        'lng': 110.384310,
      },
      {
        'nama_lapangan': 'Jakal 7 Futsal',
        'description':
            'Tempat futsal legendaris mahasiswa UGM dan UII, lantai vinyl empuk.',
        'image':
            'https://lh3.googleusercontent.com/gps-cs-s/APNQkAHkB75_Plwcpi4FTJ18I0LSXJ7t0Mem9c3VLZfThDai2BJ2-XmotREoTzvnrAs2jRjZ1Wit85LkkGC3e7afqJmsgQGV9NnztwrT4CBR2RuL1sA6rVGIz3-AnWd8W2ppYsa6g6f3rQ=s1360-w1360-h1020-rw',
        'jenis': 'FUTSAL',
        'harga': 140000,
        'capacity': 10,
        'address': 'Jl. Kaliurang KM 7, Babadan, Sinduharjo, Ngaglik, Sleman',
        'lat': -7.740120,
        'lng': 110.390140,
      },
      {
        'nama_lapangan': 'Jogokariyan Futsal',
        'description':
            'Futsal di area Jogokariyan Selatan, ramah lingkungan dan bersih.',
        'image':
            'https://image.idntimes.com/post/20230309/75231121-543886693109373-6448972192126845471-n-759160577ba6e08b02b9cea2a6d29d8f-6f71dd08d70d2335133b4db244098518.jpg?tr=w-1200,f-webp,q-75&width=1200&format=webp&quality=75',
        'jenis': 'FUTSAL',
        'harga': 110000,
        'capacity': 10,
        'address': 'Jl. Jogokariyan, Mantrijeron, Kota Yogyakarta',
        'lat': -7.823611,
        'lng': 110.364812,
      },
      {
        'nama_lapangan': '4R Futsal',
        'description': 'Lapangan sintetis dengan penerangan LED terang.',
        'image':
            'https://lh3.googleusercontent.com/gps-cs-s/APNQkAGj5QpQ3ZXtLZFoX8lU2VkiXLTuDU7FPAa6etr0cMqKQa-L3U0aXFe5LgwQvB-G6K8_znGROmoHAdlqiN07E_ddC-J5Uocnn3CkOwECFdcerjk6dBF5kGbN-KRwl_wYk9xtZobcHA=s1360-w1360-h1020-rw',
        'jenis': 'FUTSAL',
        'harga': 125000,
        'capacity': 10,
        'address': 'Jl. Monjali, Karangjati, Sinduadi, Kec. Mlati, Sleman',
        'lat': -7.755431,
        'lng': 110.374122,
      },
      {
        'nama_lapangan': 'Paragon Futsal',
        'description':
            'Dekat dengan area Seturan, sering dipakai turnamen kampus.',
        'image':
            'https://lh3.googleusercontent.com/gps-cs-s/APNQkAHIqIFFkwyMkIEfvFXzQluK4IvKll-vhwlFNiXgXRNVws3IaJyigoe0W93npVgWL6Wg-28nik4AciLZ1JFtI_gjIoyda0Wz8Xy2_qXEb2_DNbOT0ObXOZQM24uIaI4ofEZ9r1U=s1360-w1360-h1020-rw',
        'jenis': 'FUTSAL',
        'harga': 160000,
        'capacity': 10,
        'address': 'Jl. Seturan Raya, Kledokan, Caturtunggal, Sleman',
        'lat': -7.769211,
        'lng': 110.408123,
      },

      // --- BADMINTON (8 Lapangan) ---
      {
        'nama_lapangan': 'Depok Sports Center (Badminton)',
        'description': 'Karpet BWF standar internasional, bebas angin bocor.',
        'image':
            'https://lh3.googleusercontent.com/gps-cs-s/APNQkAFkoB9NVvHdFssM95RSRafWiB7_-aJgqssJkc7sccYWii9pRNHqK79Q_gf7qv3UXOa32ouej3SnK2mo7rp3Vh6ZJObFuFCaEplOyXuVvX2ROyaQtDEWWgBIysc7VzGqD2O-mUJzag=s1360-w1360-h1020-rw',
        'jenis': 'BADMINTON',
        'harga': 60000,
        'capacity': 4,
        'address': 'Jl. Seturan No.Kav.4, Kledokan, Caturtunggal, Sleman',
        'lat': -7.773062,
        'lng': 110.409072,
      },
      {
        'nama_lapangan': 'GOR Klebengan Badminton',
        'description':
            'GOR mahasiswa yang legend, lantai kayu dan karpet tersedia.',
        'image':
            'https://image.popmama.com/post/20250629/upload_63045315565e9af646c18a087748136f_231c88ad-ba1f-43c1-93be-cc04d9f6b9a3.jpg?tr=w-1200,f-webp,q-75&width=1200&format=webp&quality=75',
        'jenis': 'BADMINTON',
        'harga': 50000,
        'capacity': 4,
        'address': 'Jl. Agro, Karang Gayam, Caturtunggal, Sleman',
        'lat': -7.766868,
        'lng': 110.386260,
      },
      {
        'nama_lapangan': 'GOR Lembah UGM',
        'description': 'Fasilitas olahraga dalam kampus UGM, sangat terawat.',
        'image':
            'https://lh3.googleusercontent.com/gps-cs-s/APNQkAHi1335SEXxL-2Hi21FZ82a5b6NKIVk7bCr9HeSwuGeuONX7yftDlcaUrviebiEQOdZjVUThBQlQOWmqVMuS8aYNKlmwIY4DbHxoxe-40hgppBGx--eterJdM07accbtDh6MYUuAXcQm1kg=s1360-w1360-h1020-rw',
        'jenis': 'BADMINTON',
        'harga': 40000,
        'capacity': 4,
        'address': 'Lembah UGM, Karang Malang, Caturtunggal, Sleman',
        'lat': -7.771234,
        'lng': 110.382145,
      },
      {
        'nama_lapangan': 'GOR Pandiga',
        'description': 'Lantai karpet hijau, kantin lengkap, parkir aman.',
        'image': '',
        'jenis': 'BADMINTON',
        'harga': 55000,
        'capacity': 4,
        'address': 'Jl. Kaliurang KM 6, Sawitsari, Condongcatur, Sleman',
        'lat': -7.748123,
        'lng': 110.386123,
      },
      {
        'nama_lapangan': 'GOR FIK UNY',
        'description':
            'Fasilitas standar atlet nasional milik Universitas Negeri Yogyakarta.',
        'image': '',
        'jenis': 'BADMINTON',
        'harga': 70000,
        'capacity': 4,
        'address': 'Kampus UNY Karangmalang, Caturtunggal, Sleman',
        'lat': -7.774512,
        'lng': 110.386712,
      },
      {
        'nama_lapangan': 'GOR Balai Desa Condongcatur',
        'description':
            'Pilihan murah meriah untuk warga sekitar dan mahasiswa.',
        'image': '',
        'jenis': 'BADMINTON',
        'harga': 35000,
        'capacity': 4,
        'address': 'Komplek Balai Desa Condongcatur, Sleman',
        'lat': -7.756211,
        'lng': 110.398122,
      },
      {
        'nama_lapangan': 'GOR Tridadi Sleman',
        'description': 'Area olahraga terpadu milik Pemkab Sleman.',
        'image': '',
        'jenis': 'BADMINTON',
        'harga': 45000,
        'capacity': 4,
        'address': 'Jl. Panglima Sudirman, Tridadi, Kec. Sleman',
        'lat': -7.712133,
        'lng': 110.360144,
      },
      {
        'nama_lapangan': 'GOR Donotirto',
        'description':
            'GOR klasik Jogja Selatan, langganan para bapak-bapak PB.',
        'image': '',
        'jenis': 'BADMINTON',
        'harga': 40000,
        'capacity': 4,
        'address': 'Jl. Bantul, Gedongkiwo, Mantrijeron, Kota Yogyakarta',
        'lat': -7.818122,
        'lng': 110.358122,
      },

      // --- BASKETBALL (6 Lapangan) ---
      {
        'nama_lapangan': 'Kridosono Sport Hall',
        'description':
            'Lapangan basket full court dengan atap semi-indoor, pusat kota.',
        'image': '',
        'jenis': 'BASKETBALL',
        'harga': 200000,
        'capacity': 10,
        'address': 'Jl. Yos Sudarso No.100, Kotabaru, Kec. Gondokusuman',
        'lat': -7.787156,
        'lng': 110.373454,
      },
      {
        'nama_lapangan': 'GOR Amongrogo',
        'description':
            'Stadion indoor terbesar di Jogja, biasa untuk event IBL.',
        'image': '',
        'jenis': 'BASKETBALL',
        'harga': 450000,
        'capacity': 10,
        'address': 'Jl. Kenari No.14, Semaki, Kec. Umbulharjo, Kota Yogyakarta',
        'lat': -7.804122,
        'lng': 110.391233,
      },
      {
        'nama_lapangan': 'Lapangan Basket UNY',
        'description': 'Outdoor dengan ring standar, favorit sore hari.',
        'image': '',
        'jenis': 'BASKETBALL',
        'harga': 100000,
        'capacity': 10,
        'address': 'Kompleks FIK UNY, Karangmalang, Sleman',
        'lat': -7.773122,
        'lng': 110.385133,
      },
      {
        'nama_lapangan': 'Yuso Basketball Court',
        'description': 'Lapangan basket semi-indoor dengan lantai beton halus.',
        'image': '',
        'jenis': 'BASKETBALL',
        'harga': 150000,
        'capacity': 10,
        'address': 'Jl. Kusumanegara, Semaki, Kota Yogyakarta',
        'lat': -7.801122,
        'lng': 110.388144,
      },
      {
        'nama_lapangan': 'Lapangan Basket Mandala Krida',
        'description':
            'Komplek stadion utama Jogja, outdoor, gratis jika tidak di-booking event.',
        'image': '',
        'jenis': 'BASKETBALL',
        'harga': 80000,
        'capacity': 10,
        'address': 'Jl. Kenari, Semaki, Kec. Umbulharjo, Kota Yogyakarta',
        'lat': -7.798122,
        'lng': 110.392133,
      },
      {
        'nama_lapangan': 'UII Poncowinatan Basket',
        'description': 'Lapangan legendaris tengah kota milik UII.',
        'image': '',
        'jenis': 'BASKETBALL',
        'harga': 120000,
        'capacity': 10,
        'address': 'Jl. Poncowinatan, Cokrodiningratan, Jetis, Kota YK',
        'lat': -7.780133,
        'lng': 110.362144,
      },

      // --- TENNIS (4 Lapangan) ---
      {
        'nama_lapangan': 'Tennis DKT Kotabaru',
        'description': 'Pencahayaan memadai, terletak tepat di Kotabaru.',
        'image': '',
        'jenis': 'TENNIS',
        'harga': 120000,
        'capacity': 4,
        'address': 'Jl. Dr. Wahidin Sudirohusodo, Kotabaru, Gondokusuman',
        'lat': -7.785250,
        'lng': 110.377958,
      },
      {
        'nama_lapangan': 'Lembah UGM Tennis Court',
        'description': 'Hard court di lingkungan asri kampus UGM.',
        'image': '',
        'jenis': 'TENNIS',
        'harga': 80000,
        'capacity': 4,
        'address': 'Lembah UGM, Karangmalang, Sleman',
        'lat': -7.770511,
        'lng': 110.380222,
      },
      {
        'nama_lapangan': 'UNY Tennis Court',
        'description':
            'Fasilitas tenis indoor dan outdoor, sering ada pelatih.',
        'image': '',
        'jenis': 'TENNIS',
        'harga': 100000,
        'capacity': 4,
        'address': 'Kampus UNY Karangmalang, Sleman',
        'lat': -7.774822,
        'lng': 110.387133,
      },
      {
        'nama_lapangan': 'Lapangan Tenis Sinduadi',
        'description': 'Lapangan tenis warga yang asri dan sepi.',
        'image': '',
        'jenis': 'TENNIS',
        'harga': 60000,
        'capacity': 4,
        'address': 'Sinduadi, Kec. Mlati, Kabupaten Sleman',
        'lat': -7.742511,
        'lng': 110.364122,
      },

      // --- MINI SOCCER (4 Lapangan) ---
      {
        'nama_lapangan': 'Maguwoharjo Football Park',
        'description':
            'Rumput sintetis grade A, drainase sangat baik. Suasana stadion profesional.',
        'image': '',
        'jenis': 'MINI_SOCCER',
        'harga': 350000,
        'capacity': 14,
        'address': 'Jl. Selokan Mataram, Maguwoharjo, Sleman',
        'lat': -7.769393,
        'lng': 110.420334,
      },
      {
        'nama_lapangan': 'Jogja Mini Soccer (JMS)',
        'description':
            'Pilihan utama di area Jogja Barat/Selatan, rumput tebal.',
        'image': '',
        'jenis': 'MINI_SOCCER',
        'harga': 300000,
        'capacity': 14,
        'address': 'Jl. Wates KM 3, Kasihan, Bantul',
        'lat': -7.805122,
        'lng': 110.340133,
      },
      {
        'nama_lapangan': 'Baturetno Mini Soccer',
        'description':
            'Berada di area Banguntapan, rumput bagus dan bench pemain proper.',
        'image': '',
        'jenis': 'MINI_SOCCER',
        'harga': 250000,
        'capacity': 14,
        'address': 'Baturetno, Banguntapan, Bantul',
        'lat': -7.825122,
        'lng': 110.410133,
      },
      {
        'nama_lapangan': 'UII Training Ground',
        'description': 'Lapangan rumput asli dengan perawatan standar liga.',
        'image': '',
        'jenis': 'MINI_SOCCER',
        'harga': 400000,
        'capacity': 14,
        'address': 'Kampus Terpadu UII, Jl. Kaliurang KM 14.5, Sleman',
        'lat': -7.687122,
        'lng': 110.414133,
      },
    ];

    // Eksekusi Looping
    for (var court in realJogjaCourts) {
      int insertedId = await db.insert('lapangans', court);

      // Inject Fasilitas Default
      await db.insert('lapangan_amenities', {
        'lapangan_id': insertedId,
        'amenity_id': 1,
      }); // Toilet
      await db.insert('lapangan_amenities', {
        'lapangan_id': insertedId,
        'amenity_id': 3,
      }); // Parkir Luas

      // Inject Kantin khusus lapangan mahal (>= Rp150.000)
      if (court['harga'] >= 150000) {
        await db.insert('lapangan_amenities', {
          'lapangan_id': insertedId,
          'amenity_id': 2,
        });
      }
    }
  }

  // --- Fungsi CRUD Basic ---
  Future<int> insertUser(Map<String, dynamic> user) async {
    Database db = await instance.database;
    return await db.insert('users', user);
  }

  Future<Map<String, dynamic>?> getUser(
    String username,
    String password,
  ) async {
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

  // Fungsi buat ambil data user berdasarkan username aja (tanpa password)
  // Dipakai pas biometric login buat dapetin user_id yang bener
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

  // Filter booking berdasarkan user_id biar tiap user cuma liat booking miliknya sendiri
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

  // Fungsi tambahan buat Payment (Dipanggil pas user bayar)
  Future<int> createPayment(int bookingId, int amount, String method) async {
    Database db = await instance.database;
    return await db.insert('payments', {
      'booking_id': bookingId,
      'amount': amount,
      'method': method,
      'status': 'paid',
    });
  }

  // Fungsi buat ngecek jam mana aja yang udah dibooking
  Future<List<String>> getBookedTimes(int lapanganId, String tanggal) async {
    Database db = await instance.database;

    // Cari di tabel bookings yang ID lapangannya sama dan Tanggalnya sama
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
}
