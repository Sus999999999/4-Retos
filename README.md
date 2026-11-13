# Los Cuatro Retos (Flutter)

App con 4 pantallas: Películas (TMDB), Gatos (Cataas), Clima (OpenWeatherMap + geolocator), Cripto (CoinGecko).

## Puesta en marcha

```bash
flutter create --org com.ejemplo --project-name cuatro_retos .   # genera android/ios/web (no pisa lib/ ni pubspec.yaml)
flutter pub get
flutter run \
  --dart-define=TMDB_KEY=TU_KEY_TMDB \
  --dart-define=OWM_KEY=TU_KEY_OPENWEATHERMAP
```

Reto 2 (Cataas) y Reto 4 (CoinGecko) no requieren API key.

## Keys gratuitas
- TMDB: https://www.themoviedb.org/settings/api  (usa la "API Key (v3 auth)")
- OpenWeatherMap: https://home.openweathermap.org/api_keys (puede tardar unos minutos en activarse)

## Permisos
**Android** – `android/app/src/main/AndroidManifest.xml`, dentro de `<manifest>`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```
**iOS** – `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Para mostrar el clima de tu ubicación</string>
```
