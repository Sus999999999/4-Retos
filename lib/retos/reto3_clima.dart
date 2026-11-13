import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';


// ---------- Modelo ----------
class Clima {
  final String ciudad, pais, descripcion, icono;
  final double temp, sensacion;
  final int humedad;
  final double viento; // m/s

  Clima({
    required this.ciudad,
    required this.pais,
    required this.descripcion,
    required this.icono,
    required this.temp,
    required this.sensacion,
    required this.humedad,
    required this.viento,
  });

  factory Clima.fromJson(Map<String, dynamic> j) => Clima(
        ciudad: j['name'] as String? ?? '—',
        pais: (j['sys']?['country'] ?? '') as String,
        descripcion: (j['weather'][0]['description'] ?? '') as String,
        icono: (j['weather'][0]['icon'] ?? '01d') as String,
        temp: (j['main']['temp'] as num).toDouble(),
        sensacion: (j['main']['feels_like'] as num).toDouble(),
        humedad: (j['main']['humidity'] as num).toInt(),
        viento: (j['wind']?['speed'] as num?)?.toDouble() ?? 0,
      );
}

// ---------- Servicio ----------
class ClimaService {
  static const _url = 'https://api.openweathermap.org/data/2.5/weather';

  Future<Clima> porCiudad(String ciudad) =>
      _pedir({'q': ciudad});

  Future<Clima> porCoordenadas(double lat, double lon) =>
      _pedir({'lat': '$lat', 'lon': '$lon'});

  Future<Clima> _pedir(Map<String, String> params) async {
    final apiKey = AppConfig.owmKey;
    if (apiKey.isEmpty) {
      throw Exception('Falta OWM_KEY. Agrégala en el archivo .env y reinicia la app.');
    }
    final uri = Uri.parse(_url).replace(queryParameters: {
      ...params,
      'appid': apiKey,
      'units': 'metric',
      'lang': 'es',
    });
    final resp = await http.get(uri).timeout(const Duration(seconds: 15));
    if (resp.statusCode == 404) throw Exception('Ciudad no encontrada');
    if (resp.statusCode == 401) throw Exception('API key inválida o aún no activada');
    if (resp.statusCode != 200) throw Exception('Error ${resp.statusCode}');
    return Clima.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  /// Plus: ubicación automática con geolocator.
  Future<Position> posicion() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('El GPS está desactivado');
    }
    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.denied ||
        permiso == LocationPermission.deniedForever) {
      throw Exception('Permiso de ubicación denegado');
    }
    return Geolocator.getCurrentPosition();
  }
}

// ---------- UI ----------
class Reto3Clima extends StatefulWidget {
  const Reto3Clima({super.key});

  @override
  State<Reto3Clima> createState() => _Reto3ClimaState();
}

class _Reto3ClimaState extends State<Reto3Clima> {
  final _service = ClimaService();
  final _ctrl = TextEditingController(text: 'Dolores Hidalgo');
  Clima? _clima;
  bool _cargando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _buscarCiudad();
  }

  Future<void> _ejecutar(Future<Clima> Function() op) async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final c = await op();
      setState(() => _clima = c);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _cargando = false);
    }
  }

  void _buscarCiudad() {
    final ciudad = _ctrl.text.trim();
    if (ciudad.isEmpty) return;
    _ejecutar(() => _service.porCiudad(ciudad));
  }

  void _usarUbicacion() => _ejecutar(() async {
        final p = await _service.posicion();
        return _service.porCoordenadas(p.latitude, p.longitude);
      });

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌦️ Clima'),
        actions: [
          IconButton(
            tooltip: 'Usar mi ubicación',
            icon: const Icon(Icons.my_location),
            onPressed: _cargando ? null : _usarUbicacion,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _ctrl,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _buscarCiudad(),
              decoration: InputDecoration(
                labelText: 'Ciudad',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                    icon: const Icon(Icons.search), onPressed: _buscarCiudad),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(child: Center(child: _contenido())),
          ],
        ),
      ),
    );
  }

  Widget _contenido() {
    if (_cargando) return const CircularProgressIndicator();
    if (_error != null) {
      return Text(_error!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red, fontSize: 16));
    }
    final c = _clima;
    if (c == null) return const Text('Busca una ciudad');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${c.ciudad}${c.pais.isEmpty ? '' : ', ${c.pais}'}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
        Image.network(
          'https://openweathermap.org/img/wn/${c.icono}@4x.png',
          width: 150,
          height: 150,
          errorBuilder: (_, __, ___) => const Icon(Icons.cloud, size: 100),
        ),
        Text('${c.temp.round()}°C',
            style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w200)),
        Text(
          c.descripcion.isEmpty
              ? ''
              : c.descripcion[0].toUpperCase() + c.descripcion.substring(1),
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _dato(Icons.thermostat, 'Sensación', '${c.sensacion.round()}°C'),
            _dato(Icons.water_drop, 'Humedad', '${c.humedad}%'),
            _dato(Icons.air, 'Viento', '${(c.viento * 3.6).round()} km/h'),
          ],
        ),
      ],
    );
  }

  Widget _dato(IconData i, String t, String v) => Column(
        children: [
          Icon(i, size: 28),
          const SizedBox(height: 4),
          Text(t, style: const TextStyle(color: Colors.grey)),
          Text(v, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      );
}
