# PlayConnect-TFG
Proyecto TFG - Aplicación móvil para gestión y compraventa de juegos

## Cómo ejecutar la demo

### Arranque rápido en emulador

1. Abre XAMPP y arranca MySQL.
2. Desde la raíz del proyecto, ejecuta:

```bash
./scripts/start-demo.sh
```

3. Usa estos usuarios demo en la app:
   - `vendedor.demo@playconnect.local` / `Demo1234`
   - `comprador.demo@playconnect.local` / `Demo1234`

El script `start-demo.sh`:
- comprueba que estás en la raíz del proyecto
- intenta levantar el backend en `http://localhost:3000`
- valida `GET /api/publicaciones`
- lanza Flutter con `API_BASE_URL=http://10.0.2.2:3000/api`

### Comprobación del entorno de demo

Para validar rápidamente que el proyecto está listo para la defensa:

```bash
./scripts/check-demo.sh
```

Este script comprueba:
- backend en `http://localhost:3000`
- conectividad básica con la API
- `flutter analyze`
- `flutter test`

### Generar APK para móvil real

Para móvil real necesitas usar la IP local del Mac, por ejemplo `192.168.1.34`.
Puedes pasarla como argumento:

```bash
./scripts/build-apk-demo.sh 192.168.1.34
```

O ejecutar el script sin argumentos para que te la pida:

```bash
./scripts/build-apk-demo.sh
```

El comando usado es:

```bash
flutter build apk --release --dart-define=API_BASE_URL=http://IP_LOCAL_DEL_PC:3000/api
```

La APK queda en:

```text
mobile/build/app/outputs/flutter-apk/app-release.apk
```
