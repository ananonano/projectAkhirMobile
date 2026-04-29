import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../database/database.dart';
import '../services/gemini_service.dart';
import 'detail_lapangan_screen.dart'; // IMPORT INI JANGAN LUPA BRE

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LatLng? _currentPosition;
  List<Map<String, dynamic>> _lapangans = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  bool _isGeminiLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _getCurrentLocation();
    await _fetchLapangans();
  }

  Future<void> _fetchLapangans() async {
    final db = await DatabaseHelper.instance.database;
    final data = await db.query('lapangans');
    setState(() {
      _lapangans = data;
    });
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLoading = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLoading = false);
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _isLoading = false;
    });
  }

  Future<void> _tanyaGemini(String teks) async {
    if (teks.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isGeminiLoading = true;
    });

    String jawaban = await GeminiService.askGemini(teks);

    setState(() {
      _isGeminiLoading = false;
    });

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.blueAccent),
              SizedBox(width: 8),
              Text('Jawaban Gemini'),
            ],
          ),
          content: SingleChildScrollView(child: Text(jawaban)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Cari Lapangan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (value) => _tanyaGemini(value),
                    decoration: InputDecoration(
                      hintText: 'Tanya Gemini: "Tips main futsal..."',
                      prefixIcon: const Icon(
                        Icons.auto_awesome,
                        color: Colors.blueAccent,
                      ),
                      suffixIcon: _isGeminiLoading
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon: const Icon(
                                Icons.send,
                                color: Colors.blueAccent,
                              ),
                              onPressed: () =>
                                  _tanyaGemini(_searchController.text),
                            ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _currentPosition == null
                      ? const Center(
                          child: Text('Gagal mendapatkan lokasi GPS'),
                        )
                      : FlutterMap(
                          options: MapOptions(
                            initialCenter: _currentPosition!,
                            initialZoom: 13.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.lapangin.mobile',
                            ),
                            MarkerLayer(
                              markers: [
                                // Marker 1: Lokasi User (Biru)
                                Marker(
                                  point: _currentPosition!,
                                  width: 50,
                                  height: 50,
                                  child: const Icon(
                                    Icons.my_location,
                                    color: Colors.blue,
                                    size: 40,
                                  ),
                                ),
                                // Marker 2: Lapangan dari Database (Merah + Bisa Diklik)
                                ..._lapangans.map((lap) {
                                  return Marker(
                                    point: LatLng(lap['lat'], lap['lng']),
                                    width: 40,
                                    height: 40,
                                    child: GestureDetector(
                                      onTap: () {
                                        // LOGIKA PINDAH KE DETAIL PAS PIN DIKLIK
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                DetailLapanganScreen(
                                              lapangan: lap,
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Icon(
                                        Icons.location_on,
                                        color: Colors.red,
                                        size: 40,
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }
}