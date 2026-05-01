import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? _pickedLocation;
  // Titik tengah default kita set ke Jogja (UPNVYK area)
  final LatLng _initialCenter = const LatLng(-7.7613, 110.4090); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi di Peta', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF64E42),
        foregroundColor: Colors.white,
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: _initialCenter,
          initialZoom: 14.0,
          // FUNGSI INI YANG NANGKEP TITIK KLIK
          onTap: (tapPosition, point) {
            setState(() {
              _pickedLocation = point;
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.lapangin.mobile',
          ),
          if (_pickedLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _pickedLocation!,
                  width: 50,
                  height: 50,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 50,
                  ),
                ),
              ],
            ),
        ],
      ),
      // Tombol Konfirmasi muncul kalau udah ada titik yang dipilih
      floatingActionButton: _pickedLocation != null
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFFF64E42),
              onPressed: () {
                // Lempar data koordinat balik ke halaman sebelumnya
                Navigator.pop(context, _pickedLocation);
              },
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text('Konfirmasi Lokasi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}