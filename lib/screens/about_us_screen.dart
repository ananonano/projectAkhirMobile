import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1C1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'About Us',
          style: TextStyle(
            color: Color(0xFF1A1C1A),
            fontSize: 18,
            fontFamily: 'Lexend',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E2DC)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0C000000),
                    blurRadius: 20,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // App Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEEA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'lapang-in.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.sports_soccer,
                            color: Color(0xFF6B8F71),
                            size: 40,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'LAPANG.IN',
                    style: TextStyle(
                      color: Color(0xFF416448),
                      fontSize: 28,
                      fontFamily: 'Lexend',
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Booking Lapangan Olahraga',
                    style: TextStyle(
                      color: Color(0xFF78716C),
                      fontSize: 14,
                      fontFamily: 'Lexend',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: const Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 12,
                        fontFamily: 'Lexend',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Project Info
            const Text(
              'Tentang Proyek',
              style: TextStyle(
                color: Color(0xFF1A1C1A),
                fontSize: 18,
                fontFamily: 'Lexend',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E2DC)),
              ),
              child: const Text(
                'Lapang.in adalah aplikasi booking lapangan olahraga yang dibuat sebagai Proyek Akhir Mata Kuliah Teknologi Pemrograman Mobile (TPM). '
                'Aplikasi ini memudahkan pengguna untuk mencari, memesan, dan mengelola booking lapangan olahraga dengan fitur-fitur modern seperti '
                'maps, recommendations, real-time booking, dan admin dashboard.',
                style: TextStyle(
                  color: Color(0xFF78716C),
                  fontSize: 14,
                  fontFamily: 'Lexend',
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Team Section
            const Text(
              'Tim Pengembang',
              style: TextStyle(
                color: Color(0xFF1A1C1A),
                fontSize: 18,
                fontFamily: 'Lexend',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            
            // Member 1 - Danang
            _buildMemberCard(
              name: 'Danang Adiwibowo',
              nim: '123230143',
              imagePath: 'danankmobile.jpeg',
              role: 'Full Stack Developer',
              quote: '"Coding sambil ngopi, bug sambil ngamuk, tapi tetep jadi kok!"',
            ),
            const SizedBox(height: 16),
            
            // Member 2 - Gorga
            _buildMemberCard(
              name: 'Gorga Doli L N',
              nim: '123230147',
              imagePath: 'gorokmobile.jpeg',
              role: 'Full Stack Developer',
              quote: '"Deadline mepet? Tenang, adrenalin adalah teman terbaik developer!"',
            ),
            const SizedBox(height: 24),
            
            // Kesan & Pesan
            const Text(
              'Kesan & Pesan TPM',
              style: TextStyle(
                color: Color(0xFF1A1C1A),
                fontSize: 18,
                fontFamily: 'Lexend',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6B8F71),
                    Color(0xFF416448),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x19000000),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Kesan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Lexend',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Jujur aja, TPM ini bikin gila tapi gila yang produktif. Dari awal semester '
                    'udah dikasih tugas yang bikin mikir "ini beneran bisa kelar?" tapi somehow '
                    'ya kelar juga. Materinya padat banget, dari database, maps, sensor, sampe AI, '
                    'semua dimasukin dalam satu semester. Berasa kayak speedrun belajar mobile development. '
                    'Yang bikin survive? Dosennya santai orangnya, jadi kita bisa nanya-nanya tanpa takut. '
                    'Tapi jangan salah, santai bukan berarti gampang ya, tetep aja bikin begadang berkali-kali.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Lexend',
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: const [
                      Icon(Icons.message_rounded, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Pesan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Lexend',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Buat adik-adik angkatan yang mau ambil TPM, saran dari kami: mental harus kuat, '
                    'stok kopi harus banyak, dan jangan lupa siapin playlist buat nemenin begadang. '
                    'Matkul ini emang bikin stress, tapi stress yang worth it karena skill yang didapet '
                    'beneran applicable. Error itu temen sehari-hari, jadi jangan panik kalo ketemu bug. '
                    'Google, Stack Overflow, sama ChatGPT boleh jadi temen, tapi jangan lupa logika sendiri '
                    'tetep nomor satu. Oh iya, satu lagi yang penting banget: rajin commit dan push ke Git, '
                    'jangan sampe kehilangan progress gara-gara lupa save. Trust us, we learned it the hard way.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Lexend',
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Tech Stack
            const Text(
              'Tech Stack',
              style: TextStyle(
                color: Color(0xFF1A1C1A),
                fontSize: 18,
                fontFamily: 'Lexend',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTechChip('Flutter', Icons.flutter_dash),
                _buildTechChip('Dart', Icons.code),
                _buildTechChip('SQLite', Icons.storage),
                _buildTechChip('Google Maps', Icons.map),
                _buildTechChip('Gemini AI', Icons.auto_awesome),
                _buildTechChip('Git', Icons.source),
              ],
            ),
            const SizedBox(height: 24),
            
            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F1EC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: const [
                  Text(
                    '© 2026 Lapang.in',
                    style: TextStyle(
                      color: Color(0xFF78716C),
                      fontSize: 12,
                      fontFamily: 'Lexend',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Proyek Akhir Mata Kuliah TPM',
                    style: TextStyle(
                      color: Color(0xFF78716C),
                      fontSize: 11,
                      fontFamily: 'Lexend',
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'UPN "Veteran" Yogyakarta',
                    style: TextStyle(
                      color: Color(0xFF78716C),
                      fontSize: 11,
                      fontFamily: 'Lexend',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMemberCard({
    required String name,
    required String nim,
    required String imagePath,
    required String role,
    required String quote,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E2DC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFEEEEEA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF6B8F71), width: 3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.person_rounded,
                    color: Color(0xFF6B8F71),
                    size: 40,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFF1A1C1A),
                    fontSize: 16,
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'NIM: $nim',
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 11,
                      fontFamily: 'Lexend',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  role,
                  style: const TextStyle(
                    color: Color(0xFF6B8F71),
                    fontSize: 12,
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9E6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFE082)),
                  ),
                  child: Text(
                    quote,
                    style: const TextStyle(
                      color: Color(0xFF78716C),
                      fontSize: 12,
                      fontFamily: 'Lexend',
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTechChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: const Color(0xFFE5E2DC)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6B8F71)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF1A1C1A),
              fontSize: 12,
              fontFamily: 'Lexend',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
