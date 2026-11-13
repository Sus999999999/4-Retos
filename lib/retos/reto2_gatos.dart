import 'package:flutter/material.dart';

class Reto2Gatos extends StatefulWidget {
  const Reto2Gatos({super.key});

  @override
  State<Reto2Gatos> createState() => _Reto2GatosState();
}

class _Reto2GatosState extends State<Reto2Gatos> {
  final _textoCtrl = TextEditingController();

  static const _filtros = <String, String>{
    'Ninguno': '',
    'Blanco y negro': 'mono',
    'Sepia': 'sepia',
    'Negativo': 'negative',
    'Pintura': 'paint',
    'Pixelado': 'pixel',
    'Desenfoque': 'blur',
  };
  static const _colores = <String, Color>{
    'white': Colors.white,
    'yellow': Colors.yellow,
    'red': Colors.red,
    'black': Colors.black,
  };

  String _filtro = 'Ninguno';
  String _color = 'white';
  double _tamano = 40;
  int _semilla = DateTime.now().millisecondsSinceEpoch;

  /// Construye la URL dinámica de Cataas.
  /// - Con texto:  https://cataas.com/cat/says/<texto>?...
  /// - Sin texto:  https://cataas.com/cat?...
  /// El parámetro `_` (semilla) evita que se reutilice la imagen en caché.
  String get _url {
    final texto = _textoCtrl.text.trim();
    final base = texto.isEmpty
        ? 'https://cataas.com/cat'
        : 'https://cataas.com/cat/says/${Uri.encodeComponent(texto)}';
    final params = <String, String>{
      'fontSize': _tamano.round().toString(),
      'fontColor': _color,
      if (_filtros[_filtro]!.isNotEmpty) 'filter': _filtros[_filtro]!,
      '_': '$_semilla',
    };
    return Uri.parse(base).replace(queryParameters: params).toString();
  }

  void _nuevoGato() => setState(() => _semilla = DateTime.now().millisecondsSinceEpoch);

  @override
  void dispose() {
    _textoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🐱 Memes de Gatos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _textoCtrl,
            decoration: const InputDecoration(
              labelText: 'Escribe tu frase',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.edit),
            ),
            onSubmitted: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filtro,
                  decoration: const InputDecoration(
                      labelText: 'Filtro', border: OutlineInputBorder()),
                  items: _filtros.keys
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) => setState(() => _filtro = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _color,
                  decoration: const InputDecoration(
                      labelText: 'Color texto', border: OutlineInputBorder()),
                  items: _colores.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Row(children: [
                              Icon(Icons.circle, color: e.value, size: 18),
                              const SizedBox(width: 8),
                              Text(e.key),
                            ]),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _color = v!),
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Text('Tamaño'),
              Expanded(
                child: Slider(
                  value: _tamano,
                  min: 20,
                  max: 80,
                  divisions: 12,
                  label: _tamano.round().toString(),
                  onChanged: (v) => setState(() => _tamano = v),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.check),
                  label: const Text('Aplicar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _nuevoGato,
                  icon: const Icon(Icons.shuffle),
                  label: const Text('Otro gato'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 250),
              child: Image.network(
                _url,
                key: ValueKey(_url),
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const SizedBox(
                    height: 250,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (_, __, ___) => const SizedBox(
                  height: 250,
                  child: Center(
                    child: Text('No se pudo cargar el gato 😿\nRevisa tu conexión.',
                        textAlign: TextAlign.center),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(_url,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
