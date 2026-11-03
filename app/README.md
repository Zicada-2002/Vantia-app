# app/ — Vantia (Flutter)

## Ejecutar

```bash
flutter pub get
# Contra emuladores locales (levantar antes: cd ../functions && npm run serve)
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=env/emulator.json

# Contra un proyecto real (env/dev.json no se versiona; ver env/dev.json.example)
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=env/dev.json
flutter run --flavor prod -t lib/main_prod.dart --dart-define-from-file=env/prod.json
```

## Calidad

```bash
dart format lib test
flutter analyze
flutter test
```

## Estructura

```
lib/
  app/        arranque, flavors, router (guards), shell, tema
  core/       Money (céntimos), LimaTime, Result/Failure, analítica, widgets compartidos
  features/   una carpeta por feature: data / domain / presentation
  l10n/       textos es-PE (app_es.arb); gen/ se genera con `flutter gen-l10n`
```

Convenciones: montos siempre como `Money` (céntimos), fechas agrupadas con `LimaTime`, textos en `app_es.arb`. Ver `../docs/ARQUITECTURA.md`.

Fuente Poppins bajo licencia SIL OFL (`assets/fonts/OFL.txt`).
