# Requirements Document

## Introduction

Lapang.in adalah aplikasi mobile Flutter yang berfungsi sebagai marketplace digital untuk pemesanan lapangan olahraga (futsal, basket, badminton, mini soccer, tenis) di Yogyakarta, Indonesia. Aplikasi ini merupakan Tugas Akhir mata kuliah Teknologi Pemrograman Mobile (TPM) dan harus memenuhi 11 kriteria wajib yang telah ditetapkan.

Dokumen ini mencakup seluruh fitur aplikasi — baik yang sudah diimplementasikan maupun yang masih perlu dibangun atau diperbaiki — beserta bug yang teridentifikasi dari review kode.

**Status Implementasi:**
- ✅ = Sudah diimplementasikan dan berfungsi
- ⚠️ = Sudah ada tapi perlu perbaikan/verifikasi
- ❌ = Belum diimplementasikan / ada bug kritis

---

## Glossary

- **App**: Aplikasi mobile Lapang.in (Flutter)
- **User**: Pengguna terdaftar dengan role `user`
- **Admin**: Pengguna dengan role `admin` yang mengelola data lapangan
- **Session**: Data login yang disimpan di SharedPreferences
- **Lapangan**: Data lapangan olahraga yang tersimpan di tabel `lapangans` SQLite
- **Booking**: Reservasi lapangan yang tersimpan di tabel `bookings` SQLite
- **DatabaseHelper**: Singleton class yang mengelola koneksi dan operasi SQLite
- **LoginScreen**: Halaman login dengan enkripsi SHA-1 dan opsi biometrik
- **RootScreen**: Halaman utama dengan bottom navigation (Home, Riwayat, Profil)
- **HomeScreen**: Halaman daftar lapangan dengan fitur pencarian dan filter
- **BookingScreen**: Halaman riwayat booking (tab "Riwayat")
- **ProfileScreen**: Halaman profil pengguna dengan jam zona waktu dan pengaturan
- **DetailLapanganScreen**: Halaman detail lapangan dengan pemilihan jadwal
- **PaymentScreen**: Halaman pembayaran dengan konversi mata uang
- **ReceiptScreen**: Halaman struk pembayaran (PDF)
- **AdminDashboardScreen**: Halaman CRUD lapangan untuk admin
- **ChatScreen**: Halaman AI chat menggunakan Gemini API
- **SentimentAnalysisScreen**: Halaman analisis sentimen ulasan lapangan
- **DodgeBallScreen**: Halaman mini game Dodge Ball menggunakan sensor akselerometer
- **CurrencyConverterScreen**: Halaman konverter mata uang mandiri
- **TimeConverterScreen**: Halaman konverter zona waktu mandiri
- **MapPickerScreen**: Halaman peta interaktif menggunakan flutter_map
- **GeminiService**: Service HTTP untuk komunikasi dengan Gemini API
- **SHA-1**: Algoritma hash yang digunakan untuk enkripsi password
- **SharedPreferences**: Penyimpanan key-value lokal untuk session management
- **sensors_plus**: Package Flutter untuk mengakses sensor akselerometer dan giroskop
- **local_auth**: Package Flutter untuk autentikasi biometrik (sidik jari)
- **WIB**: Waktu Indonesia Barat (UTC+7)
- **WITA**: Waktu Indonesia Tengah (UTC+8)
- **WIT**: Waktu Indonesia Timur (UTC+9)
- **IDR**: Indonesian Rupiah
- **USD**: US Dollar
- **SGD**: Singapore Dollar
- **THB**: Thai Baht
- **PHP**: Philippine Peso

---

## Requirements

---

### Requirement 1: Autentikasi Login dengan Enkripsi ✅

**User Story:** Sebagai User, saya ingin login dengan username dan password yang terenkripsi, sehingga kredensial saya tersimpan dengan aman tanpa menggunakan layanan pihak ketiga seperti Firebase.

#### Acceptance Criteria

1. WHEN User memasukkan username dan password lalu menekan tombol Login, THE LoginScreen SHALL mengenkripsi password menggunakan algoritma SHA-1 sebelum membandingkan dengan data di database.
2. WHEN kredensial yang dimasukkan cocok dengan data di tabel `users`, THE LoginScreen SHALL menyimpan `isLoggedIn`, `username`, `role`, dan `user_id` ke SharedPreferences.
3. WHEN User dengan role `admin` berhasil login, THE LoginScreen SHALL mengarahkan User ke AdminDashboardScreen.
4. WHEN User dengan role `user` berhasil login, THE LoginScreen SHALL mengarahkan User ke RootScreen.
5. IF username atau password tidak cocok dengan data di database, THEN THE LoginScreen SHALL menampilkan pesan error "Username atau Password salah!".
6. IF kolom username atau password dibiarkan kosong, THEN THE LoginScreen SHALL menampilkan pesan peringatan tanpa melakukan query ke database.
7. THE App SHALL menyediakan halaman RegisterScreen sehingga User baru dapat membuat akun dengan username unik.
8. WHEN User baru mendaftar, THE RegisterScreen SHALL memvalidasi bahwa username belum digunakan sebelum menyimpan data ke tabel `users`.

---

### Requirement 2: Login Biometrik ✅ (dengan bug kritis ⚠️)

**User Story:** Sebagai User, saya ingin login menggunakan sidik jari, sehingga saya dapat masuk ke aplikasi dengan cepat tanpa mengetik password.

#### Acceptance Criteria

1. WHEN User membuka LoginScreen dan biometrik sudah diaktifkan, THE LoginScreen SHALL secara otomatis memicu prompt autentikasi biometrik.
2. WHEN autentikasi biometrik berhasil, THE LoginScreen SHALL memulihkan session lengkap termasuk `username`, `role`, **dan `user_id`** ke SharedPreferences.
3. IF perangkat tidak mendukung biometrik, THEN THE LoginScreen SHALL menyembunyikan tombol sidik jari dan tidak menawarkan opsi biometrik.
4. IF User belum mendaftarkan sidik jari di ProfileScreen, THEN THE LoginScreen SHALL menampilkan pesan "Belum ada akun yang daftarin sidik jari bre!" ketika tombol sidik jari ditekan.
5. WHEN User mengaktifkan biometrik di ProfileScreen, THE ProfileScreen SHALL menyimpan `biometric_username` dan `biometric_role` ke SharedPreferences sehingga login biometrik dapat mengidentifikasi pemilik sidik jari.
6. THE App SHALL memastikan bahwa login biometrik hanya mengaktifkan session untuk akun yang mendaftarkan sidik jari tersebut.

> **Bug Teridentifikasi (⚠️ HARUS DIPERBAIKI):** Pada `_handleBiometricAuth()` di `login_screen.dart`, setelah autentikasi biometrik berhasil, `user_id` tidak dipulihkan ke SharedPreferences. Akibatnya, booking yang dilakukan setelah login biometrik akan menggunakan `user_id` default (2) bukan `user_id` milik pengguna yang sebenarnya. Perbaikan: query database berdasarkan `biometric_username` untuk mendapatkan `user_id` yang benar, lalu simpan ke SharedPreferences.

---

### Requirement 3: Database SQLite Lokal ✅

**User Story:** Sebagai App, saya ingin menyimpan semua data (pengguna, lapangan, booking, pembayaran) di database lokal SQLite, sehingga aplikasi dapat berfungsi tanpa koneksi internet untuk operasi inti.

#### Acceptance Criteria

1. THE DatabaseHelper SHALL mengelola database SQLite dengan tabel: `users`, `lapangans`, `amenities`, `lapangan_amenities`, `bookings`, dan `payments`.
2. WHEN aplikasi dijalankan pertama kali, THE DatabaseHelper SHALL membuat semua tabel dan mengisi data awal (seeder) termasuk akun admin, akun user, dan 30 data lapangan nyata di Yogyakarta.
3. WHEN Admin menambahkan lapangan baru melalui AdminDashboardScreen, THE DatabaseHelper SHALL menyimpan data lapangan ke tabel `lapangans`.
4. WHEN Admin menghapus lapangan, THE DatabaseHelper SHALL menghapus data lapangan beserta relasi di `lapangan_amenities` menggunakan CASCADE DELETE.
5. WHEN User menyelesaikan pembayaran, THE DatabaseHelper SHALL menyimpan data booking ke tabel `bookings` dengan `user_id` yang benar dari session aktif.
6. THE DatabaseHelper SHALL menyediakan fungsi `getBookedTimes(lapanganId, tanggal)` yang mengembalikan daftar jam yang sudah dipesan untuk lapangan dan tanggal tertentu.

---

### Requirement 4: Pencarian dan Filter Lapangan ✅

**User Story:** Sebagai User, saya ingin mencari lapangan berdasarkan jenis olahraga dan lokasi, sehingga saya dapat menemukan lapangan yang sesuai dengan kebutuhan saya dengan cepat.

#### Acceptance Criteria

1. THE HomeScreen SHALL menampilkan daftar semua lapangan yang tersedia dari database SQLite saat pertama kali dibuka.
2. WHEN User memilih jenis olahraga dari dropdown dan menekan tombol Cari, THE HomeScreen SHALL memfilter daftar lapangan berdasarkan kolom `jenis` di database.
3. WHEN User memasukkan teks lokasi dan menekan tombol Cari, THE HomeScreen SHALL memfilter daftar lapangan menggunakan query `LIKE '%keyword%'` pada kolom `address`.
4. WHEN User menggunakan filter jenis olahraga dan lokasi secara bersamaan, THE HomeScreen SHALL menggabungkan kedua filter dengan operator `AND`.
5. IF tidak ada lapangan yang cocok dengan filter yang diterapkan, THEN THE HomeScreen SHALL menampilkan pesan "Waduh, lapangan yang dicari gak ketemu nih."
6. WHEN User menekan kartu lapangan, THE HomeScreen SHALL membuka DetailLapanganScreen dengan data lapangan yang dipilih.

---

### Requirement 5: Pemesanan Lapangan (Booking Flow) ✅

**User Story:** Sebagai User, saya ingin memilih tanggal dan jam untuk memesan lapangan, sehingga saya dapat memastikan lapangan tersedia pada waktu yang saya inginkan.

#### Acceptance Criteria

1. THE DetailLapanganScreen SHALL menampilkan slider gambar lapangan, informasi detail, fasilitas, dan kalender pemilihan jadwal.
2. THE DetailLapanganScreen SHALL menampilkan pilihan tanggal untuk 31 hari ke depan dalam format horizontal scrollable.
3. WHEN User memilih tanggal, THE DetailLapanganScreen SHALL mengambil data jam yang sudah dipesan dari database dan menampilkan jam tersebut dengan tampilan dicoret (strikethrough) dan tidak dapat dipilih.
4. WHEN User memilih satu atau lebih slot jam yang tersedia, THE DetailLapanganScreen SHALL menghitung total harga secara dinamis (harga per jam × jumlah jam dipilih).
5. IF User menekan tombol "Book Now" tanpa memilih jam, THEN THE DetailLapanganScreen SHALL menampilkan pesan "Pilih jam mainnya dulu bre!".
6. WHEN User menekan "Book Now" dengan jam yang sudah dipilih, THE DetailLapanganScreen SHALL membuka PaymentScreen dengan data lapangan, tanggal, dan jam yang dipilih.

---

### Requirement 6: Pembayaran dengan Konversi Mata Uang ✅

**User Story:** Sebagai User, saya ingin membayar sewa lapangan dalam berbagai mata uang internasional, sehingga aplikasi dapat melayani pengguna dari berbagai negara.

#### Acceptance Criteria

1. THE PaymentScreen SHALL menampilkan ringkasan pesanan, pilihan mata uang, metode pembayaran, dan rincian total harga.
2. THE PaymentScreen SHALL mendukung minimal 5 mata uang: IDR (Rupiah), USD (Dollar AS), SGD (Dollar Singapura), THB (Baht Thailand), dan PHP (Peso Filipina).
3. WHEN User memilih mata uang selain IDR, THE PaymentScreen SHALL mengkonversi total harga menggunakan nilai tukar yang telah ditentukan dan menambahkan biaya layanan internasional.
4. WHEN User memilih mata uang IDR, SGD, atau THB, THE PaymentScreen SHALL menampilkan opsi pembayaran QRIS sebagai metode yang tersedia.
5. WHEN User menekan tombol "Bayar Sekarang", THE PaymentScreen SHALL meminta konfirmasi biometrik (sidik jari) sebelum memproses pembayaran.
6. IF biometrik belum diaktifkan di ProfileScreen, THEN THE PaymentScreen SHALL menampilkan pesan peringatan dan membatalkan proses pembayaran.
7. WHEN autentikasi biometrik berhasil, THE PaymentScreen SHALL menyimpan data booking ke database menggunakan `user_id` dari session aktif dan mengarahkan User ke ReceiptScreen.
8. THE ReceiptScreen SHALL menampilkan struk pembayaran yang dapat diekspor sebagai file PDF.

---

### Requirement 7: Riwayat Booking per User ⚠️ (ada bug kritis)

**User Story:** Sebagai User, saya ingin melihat riwayat booking saya sendiri, sehingga saya dapat memantau jadwal yang sudah saya pesan.

#### Acceptance Criteria

1. THE BookingScreen SHALL menampilkan daftar booking yang diurutkan dari yang terbaru.
2. THE BookingScreen SHALL hanya menampilkan booking milik User yang sedang login, difilter berdasarkan `user_id` dari session aktif.
3. WHEN waktu booking sudah lewat dari waktu sekarang, THE BookingScreen SHALL menampilkan label "Selesai" dengan warna abu-abu.
4. WHEN waktu booking belum lewat, THE BookingScreen SHALL menampilkan label "Akan Datang" dengan warna hijau.
5. WHEN User menekan item booking, THE BookingScreen SHALL membuka ReceiptScreen dengan detail booking tersebut.
6. IF User belum memiliki riwayat booking, THEN THE BookingScreen SHALL menampilkan pesan "Belum ada riwayat booking nih bre."

> **Bug Teridentifikasi (⚠️ HARUS DIPERBAIKI):** Fungsi `getBookings()` di `database.dart` mengambil **semua** data dari tabel `bookings` tanpa filter `user_id`. Akibatnya, semua User dapat melihat booking milik User lain. Perbaikan: tambahkan parameter `userId` pada fungsi `getBookings()` dan tambahkan klausa `WHERE user_id = ?` pada query.

---

### Requirement 8: Web Service / API (Gemini AI) ✅

**User Story:** Sebagai User, saya ingin berkonsultasi dengan asisten AI tentang lapangan olahraga, sehingga saya mendapatkan rekomendasi dan informasi yang relevan secara real-time.

#### Acceptance Criteria

1. THE ChatScreen SHALL menyediakan antarmuka chat untuk berkomunikasi dengan AI asisten Lapang.in.
2. WHEN User mengirim pesan, THE GeminiService SHALL mengirim HTTP POST request ke endpoint Gemini API dengan API key yang dimuat dari file `.env`.
3. WHEN Gemini API mengembalikan respons sukses (HTTP 200), THE ChatScreen SHALL menampilkan teks respons dari AI.
4. IF Gemini API mengembalikan error atau koneksi gagal, THEN THE ChatScreen SHALL menampilkan pesan error yang informatif kepada User.
5. IF API key tidak ditemukan di file `.env`, THEN THE GeminiService SHALL mengembalikan pesan "Eh, API Key-nya belum lu masukin di .env bre!".
6. THE ChatScreen SHALL dapat diakses melalui tombol floating action button (FAB) di RootScreen.

---

### Requirement 9: Location-Based Service (LBS) dengan Peta ✅

**User Story:** Sebagai Admin, saya ingin memilih koordinat lokasi lapangan menggunakan peta interaktif, sehingga data lokasi lapangan akurat dan dapat digunakan untuk navigasi.

#### Acceptance Criteria

1. THE MapPickerScreen SHALL menampilkan peta interaktif menggunakan flutter_map dengan tile layer dari OpenStreetMap.
2. WHEN Admin membuka MapPickerScreen, THE MapPickerScreen SHALL meminta izin lokasi dan menampilkan posisi perangkat saat ini menggunakan geolocator.
3. WHEN Admin mengetuk titik di peta, THE MapPickerScreen SHALL menempatkan marker pada koordinat yang dipilih dan menampilkan nilai latitude dan longitude.
4. WHEN Admin mengkonfirmasi pilihan lokasi, THE MapPickerScreen SHALL mengembalikan nilai koordinat ke halaman pemanggil (FormLapanganScreen).
5. THE DetailLapanganScreen SHALL menampilkan informasi alamat lapangan yang tersimpan di database.

---

### Requirement 10: Sensor Perangkat (Akselerometer) ✅

**User Story:** Sebagai User, saya ingin mengontrol karakter dalam mini game menggunakan gerakan fisik perangkat, sehingga pengalaman bermain lebih imersif dan memanfaatkan sensor hardware.

#### Acceptance Criteria

1. THE DodgeBallScreen SHALL menggunakan stream `accelerometerEventStream()` dari package `sensors_plus` untuk membaca data sensor akselerometer secara real-time.
2. WHEN perangkat dimiringkan ke kiri atau kanan, THE DodgeBallScreen SHALL menggerakkan bola pemain secara proporsional terhadap nilai sumbu X akselerometer.
3. THE DodgeBallScreen SHALL membatasi pergerakan bola pemain agar tidak melampaui batas kiri dan kanan layar.
4. WHEN DodgeBallScreen ditutup, THE DodgeBallScreen SHALL membatalkan subscription sensor (`_accelSubscription?.cancel()`) untuk mencegah memory leak.
5. WHERE perangkat tidak memiliki akselerometer, THE DodgeBallScreen SHALL menyediakan kontrol alternatif menggunakan gesture drag (swipe) pada layar.

---

### Requirement 11: Sensor Perangkat (Giroskop) ❌ (BELUM DIIMPLEMENTASIKAN)

**User Story:** Sebagai User, saya ingin aplikasi memanfaatkan sensor giroskop perangkat, sehingga persyaratan minimal 2 sensor untuk Tugas Akhir terpenuhi.

#### Acceptance Criteria

1. THE App SHALL mengintegrasikan sensor giroskop menggunakan `gyroscopeEventStream()` dari package `sensors_plus` pada minimal satu fitur aplikasi.
2. WHEN sensor giroskop aktif, THE App SHALL membaca data rotasi perangkat pada sumbu X, Y, dan Z.
3. THE App SHALL menampilkan data giroskop secara visual kepada User sehingga penggunaan sensor dapat didemonstrasikan.
4. WHEN halaman yang menggunakan giroskop ditutup, THE App SHALL membatalkan subscription giroskop untuk mencegah memory leak.

> **Catatan Implementasi:** Opsi yang direkomendasikan adalah menambahkan widget "Sensor Monitor" di ProfileScreen atau membuat SensorDemoScreen terpisah yang menampilkan data akselerometer dan giroskop secara real-time. Ini memenuhi persyaratan "minimal 2 sensor" dari Tugas Akhir.

---

### Requirement 12: Konversi Mata Uang (Mandiri) ✅

**User Story:** Sebagai User, saya ingin mengkonversi nilai mata uang secara mandiri di luar konteks pembayaran, sehingga saya dapat mengetahui perkiraan biaya sewa lapangan dalam mata uang yang saya inginkan.

#### Acceptance Criteria

1. THE CurrencyConverterScreen SHALL menyediakan antarmuka untuk memasukkan nominal dan memilih mata uang asal serta mata uang tujuan.
2. THE CurrencyConverterScreen SHALL mendukung minimal 3 mata uang berbeda (IDR, USD, SGD, THB, PHP).
3. WHEN User memasukkan nominal dan memilih pasangan mata uang lalu menekan tombol konversi, THE CurrencyConverterScreen SHALL menampilkan hasil konversi menggunakan nilai tukar yang telah ditentukan.
4. THE CurrencyConverterScreen SHALL dapat diakses dari ProfileScreen atau menu navigasi yang tersedia.

---

### Requirement 13: Konversi Zona Waktu ✅

**User Story:** Sebagai User, saya ingin melihat dan mengkonversi waktu antar zona waktu Indonesia dan internasional, sehingga saya dapat merencanakan booking dengan mempertimbangkan perbedaan waktu.

#### Acceptance Criteria

1. THE ProfileScreen SHALL menampilkan jam digital real-time yang diperbarui setiap detik.
2. WHEN User memilih zona waktu dari dropdown, THE ProfileScreen SHALL menampilkan waktu yang sesuai untuk zona waktu WIB (UTC+7), WITA (UTC+8), WIT (UTC+9), dan London (UTC+0).
3. THE TimeConverterScreen SHALL menyediakan antarmuka untuk mengkonversi waktu tertentu antar zona waktu yang tersedia.
4. THE TimeConverterScreen SHALL dapat diakses dari ProfileScreen atau menu navigasi yang tersedia.

---

### Requirement 14: AI / ML — Analisis Sentimen ✅

**User Story:** Sebagai User, saya ingin menganalisis sentimen ulasan lapangan, sehingga saya dapat mengetahui apakah ulasan tersebut positif, negatif, atau netral sebelum memutuskan untuk memesan.

#### Acceptance Criteria

1. THE SentimentAnalysisScreen SHALL menyediakan kolom input teks untuk memasukkan ulasan lapangan.
2. WHEN User menekan tombol "Mulai Analisis", THE SentimentAnalysisScreen SHALL menganalisis teks menggunakan kamus kata kunci positif dan negatif.
3. WHEN skor analisis lebih dari 0, THE SentimentAnalysisScreen SHALL menampilkan label "SENTIMEN POSITIF" dengan warna hijau.
4. WHEN skor analisis kurang dari 0, THE SentimentAnalysisScreen SHALL menampilkan label "SENTIMEN NEGATIF" dengan warna merah.
5. WHEN skor analisis sama dengan 0, THE SentimentAnalysisScreen SHALL menampilkan label "SENTIMEN NETRAL" dengan warna oranye.
6. THE SentimentAnalysisScreen SHALL dapat diakses dari ChatScreen atau menu yang tersedia di aplikasi.

---

### Requirement 15: Mini Game (Dodge Ball) ✅

**User Story:** Sebagai User, saya ingin memainkan mini game di dalam aplikasi, sehingga pengalaman menggunakan Lapang.in lebih menyenangkan sambil menunggu konfirmasi booking.

#### Acceptance Criteria

1. THE DodgeBallScreen SHALL menampilkan game di mana pemain menghindari bola musuh yang jatuh dari atas layar.
2. WHEN game dimulai, THE DodgeBallScreen SHALL menjalankan game loop dengan interval 16ms (sekitar 60 FPS).
3. WHEN bola musuh berhasil dilewati (melewati batas bawah layar), THE DodgeBallScreen SHALL menambahkan 10 poin ke skor pemain.
4. WHEN skor mencapai kelipatan 100, THE DodgeBallScreen SHALL meningkatkan kecepatan bola musuh sebesar 1.2 unit.
5. WHEN bola pemain bertabrakan dengan bola musuh, THE DodgeBallScreen SHALL mengakhiri game dan menampilkan skor akhir.
6. WHEN skor akhir melebihi high score sebelumnya, THE DodgeBallScreen SHALL menampilkan label "NEW BEST!" dan memperbarui high score.
7. THE DodgeBallScreen SHALL dapat diakses dari ProfileScreen melalui menu "Main Dodge Ball".

---

### Requirement 16: Notifikasi Lokal ❌ (BELUM DIIMPLEMENTASIKAN)

**User Story:** Sebagai User, saya ingin menerima notifikasi pengingat sebelum jadwal booking saya, sehingga saya tidak lupa untuk datang ke lapangan yang sudah dipesan.

#### Acceptance Criteria

1. THE App SHALL mengintegrasikan package notifikasi lokal (misalnya `flutter_local_notifications`) untuk mengirim notifikasi tanpa memerlukan koneksi internet atau server.
2. WHEN User berhasil menyelesaikan pembayaran, THE App SHALL menjadwalkan notifikasi pengingat 1 jam sebelum waktu booking dimulai.
3. WHEN notifikasi pengingat muncul, THE App SHALL menampilkan judul lapangan, tanggal, dan jam booking dalam isi notifikasi.
4. IF waktu booking kurang dari 1 jam dari sekarang, THEN THE App SHALL menampilkan notifikasi segera setelah pembayaran berhasil.
5. THE App SHALL meminta izin notifikasi kepada User pada saat pertama kali fitur ini digunakan.

---

### Requirement 17: Profil Pengguna ✅ (dengan inkonsistensi key ⚠️)

**User Story:** Sebagai User, saya ingin mengelola profil saya termasuk foto profil, sehingga akun saya terasa personal dan dapat dibedakan dari pengguna lain.

#### Acceptance Criteria

1. THE ProfileScreen SHALL menampilkan nama pengguna, foto profil, dan informasi akun dari session aktif.
2. WHEN User mengetuk foto profil, THE ProfileScreen SHALL membuka galeri perangkat untuk memilih foto baru.
3. WHEN User memilih foto baru, THE ProfileScreen SHALL menyimpan path foto menggunakan key `profile_image_$username` di SharedPreferences.
4. THE RootScreen SHALL memuat foto profil menggunakan key yang konsisten dengan yang digunakan ProfileScreen untuk menampilkan avatar di bottom navigation bar.
5. THE ProfileScreen SHALL menampilkan tombol Logout yang menghapus data session (`isLoggedIn`, `user_id`, `username`, `role`) dari SharedPreferences tanpa menghapus data biometrik.
6. THE ProfileScreen SHALL menampilkan dialog "Saran & Kesan" yang berisi ulasan untuk mata kuliah TPM.

> **Inkonsistensi Teridentifikasi (⚠️ HARUS DIPERBAIKI):** `ProfileScreen` menyimpan foto profil dengan key `profile_image_$username` (per-user), tetapi `RootScreen` membacanya dengan key `profile_image` (global). Akibatnya, foto profil tidak pernah muncul di bottom navigation bar. Perbaikan: `RootScreen` harus membaca key yang sama dengan yang digunakan `ProfileScreen`, yaitu `profile_image_$username`.

---

### Requirement 18: Admin Dashboard (CRUD Lapangan) ✅

**User Story:** Sebagai Admin, saya ingin mengelola data lapangan (tambah, lihat, hapus), sehingga konten marketplace selalu up-to-date.

#### Acceptance Criteria

1. THE AdminDashboardScreen SHALL menampilkan daftar semua lapangan yang tersimpan di database.
2. WHEN Admin menekan tombol "Tambah Lapangan", THE AdminDashboardScreen SHALL membuka FormLapanganScreen untuk mengisi data lapangan baru.
3. THE FormLapanganScreen SHALL memungkinkan Admin mengisi nama, deskripsi, jenis olahraga, harga, alamat, koordinat, dan memilih beberapa foto dari galeri.
4. WHEN Admin menyimpan lapangan baru, THE FormLapanganScreen SHALL memvalidasi bahwa nama dan harga tidak kosong sebelum menyimpan ke database.
5. WHEN Admin menekan ikon hapus pada item lapangan, THE AdminDashboardScreen SHALL menghapus lapangan tersebut dari database.
6. WHEN Admin logout dari AdminDashboardScreen, THE AdminDashboardScreen SHALL menghapus data session dan mengarahkan Admin ke LoginScreen.

---

### Requirement 19: Bottom Navigation ✅

**User Story:** Sebagai User, saya ingin berpindah antar halaman utama dengan mudah menggunakan navigasi bawah, sehingga pengalaman menggunakan aplikasi terasa intuitif.

#### Acceptance Criteria

1. THE RootScreen SHALL menampilkan bottom navigation bar dengan 3 tab: Home, Riwayat, dan Profil.
2. WHEN User menekan tab Home, THE RootScreen SHALL menampilkan HomeScreen.
3. WHEN User menekan tab Riwayat, THE RootScreen SHALL menampilkan BookingScreen.
4. WHEN User menekan tab Profil, THE RootScreen SHALL menampilkan ProfileScreen.
5. THE RootScreen SHALL menampilkan foto profil User sebagai ikon tab Profil jika foto sudah diupload.
6. THE RootScreen SHALL menampilkan floating action button (FAB) untuk mengakses ChatScreen dari halaman manapun.

---

## Ringkasan Bug dan Fitur yang Perlu Diselesaikan

### Bug Kritis (Harus Diperbaiki)

| # | Lokasi | Deskripsi | Requirement |
|---|--------|-----------|-------------|
| B1 | `login_screen.dart` → `_handleBiometricAuth()` | Login biometrik tidak menyimpan `user_id` ke session, menyebabkan booking salah user | Req. 2 |
| B2 | `database.dart` → `getBookings()` | Menampilkan booking semua user, bukan hanya user yang login | Req. 7 |
| B3 | `root.dart` → `_loadProfileImage()` | Membaca key `profile_image` tapi ProfileScreen menyimpan dengan key `profile_image_$username` | Req. 17 |

### Fitur yang Belum Diimplementasikan

| # | Fitur | Requirement | Prioritas |
|---|-------|-------------|-----------|
| F1 | Sensor Giroskop | Req. 11 | **Wajib** (kriteria TA) |
| F2 | Notifikasi Lokal | Req. 16 | **Wajib** (kriteria TA) |
