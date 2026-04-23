# PlayConnect Mobile

Base Flutter de la aplicacion movil de PlayConnect.

## Estructura

```text
lib/
  main.dart
  src/
    app/              # MaterialApp, tema y rutas
    core/             # Configuracion, red y almacenamiento local
    features/         # Funcionalidades por dominio
    shared/           # Widgets reutilizables
```

## API

La URL base se configura con `API_BASE_URL`.

```bash
# iOS simulator o escritorio
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api

# Android emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

El registro ya apunta a `POST /api/usuarios`, compatible con el backend actual.
El login queda preparado para `POST /api/auth/login`.

## Comandos

```bash
flutter pub get
flutter analyze
flutter test
```
