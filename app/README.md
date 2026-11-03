# app/ — Vantia (Flutter)

## Ejecutar

```bash
flutter pub get
flutter run --flavor dev -t lib/main_dev.dart      # Vantia Dev (pe.vantia.app.dev)
flutter run --flavor prod -t lib/main_prod.dart    # Vantia (pe.vantia.app)
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
