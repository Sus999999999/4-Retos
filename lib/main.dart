import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'retos/reto1_peliculas.dart';
import 'retos/reto2_gatos.dart';
import 'retos/reto3_clima.dart';
import 'retos/reto4_cripto.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Sin .env la app abre igual; los retos que necesitan key mostrarán un aviso.
  }
  runApp(const CuatroRetosApp());
}

class CuatroRetosApp extends StatelessWidget {
  const CuatroRetosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Los Cuatro Retos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final retos = <_Reto>[
      _Reto('🚀', 'Reto 1', 'Recomendador de Películas', const Reto1Peliculas()),
      _Reto('🐱', 'Reto 2', 'Memes de Gatos', const Reto2Gatos()),
      _Reto('🌦️', 'Reto 3', 'Clima Minimalista', const Reto3Clima()),
      _Reto('🪙', 'Reto 4', 'Convertidor Cripto', const Reto4Cripto()),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Los Cuatro Retos')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: retos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final r = retos[i];
          return Card(
            elevation: 2,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              leading: Text(r.emoji, style: const TextStyle(fontSize: 36)),
              title: Text(r.titulo,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(r.subtitulo),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => r.pagina),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Reto {
  final String emoji, titulo, subtitulo;
  final Widget pagina;
  _Reto(this.emoji, this.titulo, this.subtitulo, this.pagina);
}
