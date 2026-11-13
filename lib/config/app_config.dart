import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Acceso centralizado a las API keys.
/// Los valores se leen del archivo `.env` (que NO se sube a GitHub).
class AppConfig {
  AppConfig._();

  static String _leer(String nombre) {
    if (!dotenv.isInitialized) return '';
    return (dotenv.env[nombre] ?? '').trim();
  }

  static String get tmdbKey => _leer('TMDB_KEY');
  static String get owmKey => _leer('OWM_KEY');
}
