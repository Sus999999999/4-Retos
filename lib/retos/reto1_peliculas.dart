import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';


// ---------- Modelo ----------
class Pelicula {
  final int id;
  final String titulo;
  final String sinopsis;
  final String? posterPath;
  final double puntuacion;
  final String fecha;

  Pelicula({
    required this.id,
    required this.titulo,
    required this.sinopsis,
    required this.posterPath,
    required this.puntuacion,
    required this.fecha,
  });

  factory Pelicula.fromJson(Map<String, dynamic> j) => Pelicula(
        id: j['id'] as int,
        titulo: (j['title'] ?? 'Sin título') as String,
        sinopsis: (j['overview'] ?? '') as String,
        posterPath: j['poster_path'] as String?,
        puntuacion: (j['vote_average'] as num?)?.toDouble() ?? 0,
        fecha: (j['release_date'] ?? '') as String,
      );

  String? get posterUrl =>
      posterPath == null ? null : 'https://image.tmdb.org/t/p/w500$posterPath';
}

// ---------- Servicio ----------
class TmdbService {
  static const _base = 'https://api.themoviedb.org/3';

  /// Películas según género. Si [generoId] es null trae las tendencias.
  Future<List<Pelicula>> obtener({int? generoId}) async {
    final apiKey = AppConfig.tmdbKey;
    if (apiKey.isEmpty) {
      throw Exception('Falta TMDB_KEY. Agrégala en el archivo .env y reinicia la app.');
    }

    final Uri uri;
    if (generoId == null) {
      uri = Uri.parse('$_base/trending/movie/week').replace(queryParameters: {
        'api_key': apiKey,
        'language': 'es-MX',
      });
    } else {
      // Página aleatoria para que cada vez salgan películas distintas.
      final page = Random().nextInt(5) + 1;
      uri = Uri.parse('$_base/discover/movie').replace(queryParameters: {
        'api_key': apiKey,
        'language': 'es-MX',
        'with_genres': '$generoId',
        'sort_by': 'popularity.desc',
        'vote_count.gte': '200',
        'page': '$page',
      });
    }

    final resp = await http.get(uri).timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) {
      throw Exception('TMDB respondió ${resp.statusCode}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return (data['results'] as List)
        .map((e) => Pelicula.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// ---------- UI ----------
class Reto1Peliculas extends StatefulWidget {
  const Reto1Peliculas({super.key});

  @override
  State<Reto1Peliculas> createState() => _Reto1PeliculasState();
}

class _Animo {
  final String emoji, nombre;
  final int? genero;
  const _Animo(this.emoji, this.nombre, this.genero);
}

class _Reto1PeliculasState extends State<Reto1Peliculas> {
  static const _animos = [
    _Animo('😄', 'Feliz', 35), // Comedia
    _Animo('😢', 'Triste', 18), // Drama
    _Animo('🤩', 'Emocionado', 28), // Acción
    _Animo('😍', 'Romántico', 10749), // Romance
    _Animo('😱', 'Con ganas de miedo', 27), // Terror
    _Animo('🔥', 'Tendencias', null),
  ];

  final _service = TmdbService();
  _Animo _animo = _animos.first;
  List<Pelicula> _peliculas = [];
  Pelicula? _azar;
  bool _cargando = false;
  String? _error;

  Future<void> _buscar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final lista = await _service.obtener(generoId: _animo.genero);
      lista.shuffle();
      setState(() {
        _peliculas = lista;
        _azar = lista.isNotEmpty ? lista.first : null;
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🎬 Película del fin de semana')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('¿Cómo te sientes hoy?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _animos
                  .map((a) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text('${a.emoji} ${a.nombre}'),
                          selected: _animo == a,
                          onSelected: (_) => setState(() => _animo = a),
                        ),
                      ))
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: _cargando ? null : _buscar,
              icon: const Icon(Icons.casino),
              label: const Text('Recomiéndame algo'),
            ),
          ),
          Expanded(child: _contenido()),
        ],
      ),
    );
  }

  Widget _contenido() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red)),
        ),
      );
    }
    if (_azar == null) {
      return const Center(child: Text('Elige tu ánimo y pulsa el botón 🍿'));
    }
    final otras = _peliculas.skip(1).take(10).toList();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('⭐ Tu recomendación',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        PeliculaCard(pelicula: _azar!, grande: true),
        if (otras.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Otras opciones',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...otras.map((p) => PeliculaCard(pelicula: p)),
        ],
      ],
    );
  }
}

// ---------- Card ----------
class PeliculaCard extends StatelessWidget {
  final Pelicula pelicula;
  final bool grande;
  const PeliculaCard({super.key, required this.pelicula, this.grande = false});

  @override
  Widget build(BuildContext context) {
    final poster = pelicula.posterUrl;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: grande ? 130 : 90,
            height: grande ? 195 : 135,
            child: poster == null
                ? const ColoredBox(
                    color: Colors.black12,
                    child: Center(child: Icon(Icons.movie, size: 40)))
                : Image.network(poster,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pelicula.titulo,
                      style: TextStyle(
                          fontSize: grande ? 18 : 15,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(pelicula.puntuacion.toStringAsFixed(1)),
                    const SizedBox(width: 12),
                    Text(pelicula.fecha.length >= 4
                        ? pelicula.fecha.substring(0, 4)
                        : ''),
                  ]),
                  const SizedBox(height: 6),
                  Text(
                    pelicula.sinopsis.isEmpty
                        ? 'Sin sinopsis disponible.'
                        : pelicula.sinopsis,
                    maxLines: grande ? 6 : 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
