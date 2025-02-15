import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as flutterMap;
import 'package:latlong2/latlong.dart';
import 'package:lottie/lottie.dart';
import 'dart:math';

void main() {
  runApp(TarimHaritasiApp());
}

class TarimHaritasiApp extends StatefulWidget {
  @override
  _TarimHaritasiAppState createState() => _TarimHaritasiAppState();
}

class _TarimHaritasiAppState extends State<TarimHaritasiApp> {
  bool _isDarkMode = false;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: TarimHaritasi(toggleTheme: _toggleTheme, isDarkMode: _isDarkMode),
    );
  }
}

class TarimHaritasi extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;
  TarimHaritasi({required this.toggleTheme, required this.isDarkMode});

  @override
  _TarimHaritasiState createState() => _TarimHaritasiState();
}

class _TarimHaritasiState extends State<TarimHaritasi> with TickerProviderStateMixin {
  final flutterMap.MapController _mapController = flutterMap.MapController();
  late AnimationController _animationController;
  late AnimationController _moveController;
  late AnimationController _compassController;
  late Animation<double> _scaleAnimation;
  double _rotationAngle = 0.0;

  final List<Map<String, dynamic>> sehirler = [
    {"isim": "Bişkek", "konum": LatLng(42.8746, 74.5698), "urunler": ["Elma", "Buğday", "Mısır"]},
    {"isim": "Oş", "konum": LatLng(40.5333, 72.8000), "urunler": ["Pamuk", "Üzüm", "Kayısı"]},
    {"isim": "Talas", "konum": LatLng(42.5228, 72.2427), "urunler": ["Patates", "Soğan", "Havuç"]},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.2).animate(_animationController);
    _animationController.repeat(reverse: true);
    
    _moveController = AnimationController(duration: Duration(milliseconds: 1000), vsync: this);
    _compassController = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _moveController.dispose();
    _compassController.dispose();
    super.dispose();
  }

  void animatedMove(LatLng konum, double zoom) {
    final latTween = Tween<double>(begin: _mapController.center.latitude, end: konum.latitude);
    final lngTween = Tween<double>(begin: _mapController.center.longitude, end: konum.longitude);
    final zoomTween = Tween<double>(begin: _mapController.zoom, end: zoom);

    final animation = CurvedAnimation(parent: _moveController, curve: Curves.easeInOut);
    _moveController.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });
    _moveController.forward(from: 0.0);
  }

  void updateCompassRotation() {
    setState(() {
      _rotationAngle = -_mapController.rotation;
    });
  }

  void resetRotation() {
    setState(() {
      _rotationAngle = 0.0;
    });
    _mapController.rotate(0);
  }

  void sehirSec(LatLng konum, String isim, List<String> urunler) {
    animatedMove(konum, 10.0);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isim, style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: urunler.map((urun) {
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    children: [
                      Image.asset("assets/${urun.toLowerCase()}.png", width: 40, height: 40, errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.local_florist, size: 40);
                      }),
                      SizedBox(width: 10),
                      Text(urun, style: TextStyle(fontSize: 16)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Kapat"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Kırgızistan Tarım Haritası"),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.wb_sunny : Icons.nights_stay),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: Stack(
        children: [
          flutterMap.FlutterMap(
            mapController: _mapController,
            options: flutterMap.MapOptions(
              initialCenter: LatLng(41.2044, 74.7661),
              initialZoom: 6.0,
              onMapEvent: (event) {
                if (event is flutterMap.MapEventRotate) {
                  updateCompassRotation();
                }
              },
            ),
            children: [
              flutterMap.TileLayer(
                urlTemplate: widget.isDarkMode
                    ? "https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
                    : "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
                retinaMode: true,
              ),
              flutterMap.MarkerLayer(
                markers: sehirler.map((sehir) {
                  return flutterMap.Marker(
                    point: sehir["konum"],
                    width: 50,
                    height: 50,
                    child: GestureDetector(
                      onTap: () => sehirSec(sehir["konum"], sehir["isim"], sehir["urunler"]),
                      child: Lottie.asset(
                        "assets/marker_animation.json",
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.location_on, color: Colors.red, size: 40),
                      ),
                    ),
                  );
                }).toList().cast<flutterMap.Marker>(),
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton(onPressed: () => _mapController.move(_mapController.center, _mapController.zoom + 1), child: Icon(Icons.add)),
                SizedBox(height: 10),
                FloatingActionButton(onPressed: () => _mapController.move(_mapController.center, _mapController.zoom - 1), child: Icon(Icons.remove)),
                SizedBox(height: 10),
                FloatingActionButton(onPressed: resetRotation, child: AnimatedRotation(turns: _rotationAngle / (2 * pi), duration: Duration(milliseconds: 500), child: Icon(Icons.explore))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}