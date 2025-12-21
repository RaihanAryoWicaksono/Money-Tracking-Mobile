// MAULANA
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PickLocationPage extends StatefulWidget {
  const PickLocationPage({super.key});

  @override
  State<PickLocationPage> createState() => _PickLocationPageState();
}

class _PickLocationPageState extends State<PickLocationPage> {
  LatLng? _pickedLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Lokasi')),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(-7.2575, 112.7521), // Surabaya
          zoom: 14,
        ),
        onTap: (latLng) {
          setState(() {
            _pickedLocation = latLng;
          });
        },
        markers: _pickedLocation == null
            ? {}
            : {
                Marker(
                  markerId: const MarkerId('picked'),
                  position: _pickedLocation!,
                ),
              },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickedLocation == null
            ? null
            : () {
                Navigator.pop(context, _pickedLocation);
              },
        label: const Text('Pilih'),
        icon: const Icon(Icons.check),
      ),
    );
  }
}
