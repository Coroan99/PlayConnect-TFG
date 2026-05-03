#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$PROJECT_ROOT/backend"
MOBILE_DIR="$PROJECT_ROOT/mobile"
STATE_DIR="$PROJECT_ROOT/scripts/.demo-state"
BACKEND_LOG="$STATE_DIR/backend.log"
BACKEND_PID_FILE="$STATE_DIR/backend.pid"
API_URL="http://localhost:3000/api/publicaciones"
ANDROID_API_URL="http://10.0.2.2:3000/api"

mkdir -p "$STATE_DIR"

info() {
  printf '[INFO] %s\n' "$1"
}

warn() {
  printf '[WARN] %s\n' "$1"
}

fail() {
  printf '[ERROR] %s\n' "$1" >&2
  exit 1
}

cleanup_stale_pid() {
  if [[ -f "$BACKEND_PID_FILE" ]]; then
    local pid
    pid="$(cat "$BACKEND_PID_FILE")"

    if [[ -n "$pid" ]] && ! kill -0 "$pid" 2>/dev/null; then
      rm -f "$BACKEND_PID_FILE"
    fi
  fi
}

ensure_project_root() {
  if [[ "$(pwd -P)" != "$PROJECT_ROOT" ]]; then
    fail "Debes ejecutar este script desde la raiz del proyecto: $PROJECT_ROOT"
  fi

  if [[ ! -d "$BACKEND_DIR" || ! -d "$MOBILE_DIR" ]]; then
    fail "Ejecuta este script desde la raiz del proyecto PlayConnect."
  fi

  if [[ ! -f "$BACKEND_DIR/package.json" ]]; then
    fail "No se ha encontrado backend/package.json."
  fi

  if [[ ! -f "$MOBILE_DIR/pubspec.yaml" ]]; then
    fail "No se ha encontrado mobile/pubspec.yaml."
  fi
}

wait_for_api() {
  local retries=20
  local delay_seconds=2

  for ((i = 1; i <= retries; i++)); do
    if curl -fsS "$API_URL" >/dev/null 2>&1; then
      return 0
    fi

    sleep "$delay_seconds"
  done

  return 1
}

start_backend() {
  cleanup_stale_pid

  if curl -fsS "$API_URL" >/dev/null 2>&1; then
    info "Backend ya disponible en http://localhost:3000."
    return 0
  fi

  info "Recuerda arrancar MySQL desde XAMPP antes de continuar."
  info "Levantando backend en http://localhost:3000 ..."

  (
    cd "$BACKEND_DIR"
    nohup npm start >"$BACKEND_LOG" 2>&1 &
    echo $! >"$BACKEND_PID_FILE"
  )

  sleep 3

  if ! wait_for_api; then
    warn "No se pudo validar la API en $API_URL."
    if [[ -f "$BACKEND_LOG" ]]; then
      warn "Ultimas lineas del log del backend:"
      tail -n 20 "$BACKEND_LOG" || true
    fi
    fail "El backend no ha arrancado correctamente. Revisa XAMPP/MySQL y backend/.env."
  fi

  info "Backend operativo."
}

find_android_sdk_dir() {
  local candidates=()

  if [[ -n "${ANDROID_HOME:-}" ]]; then
    candidates+=("$ANDROID_HOME")
  fi

  if [[ -n "${ANDROID_SDK_ROOT:-}" ]]; then
    candidates+=("$ANDROID_SDK_ROOT")
  fi

  candidates+=("$HOME/Library/Android/sdk")

  for dir in "${candidates[@]}"; do
    if [[ -x "$dir/platform-tools/adb" ]]; then
      printf '%s\n' "$dir"
      return 0
    fi
  done

  return 1
}

ensure_android_emulator() {
  local sdk_dir adb_bin emulator_bin avd_name

  sdk_dir="$(find_android_sdk_dir || true)"

  if [[ -z "$sdk_dir" ]]; then
    warn "No se ha encontrado Android SDK automaticamente. Se intentara seguir con flutter run."
    return 0
  fi

  adb_bin="$sdk_dir/platform-tools/adb"
  emulator_bin="$sdk_dir/emulator/emulator"

  if "$adb_bin" devices | awk 'NR>1 && $2 == "device" { found=1 } END { exit found ? 0 : 1 }'; then
    info "Emulador/dispositivo Android detectado."
    return 0
  fi

  if [[ ! -x "$emulator_bin" ]]; then
    warn "No se ha encontrado el binario del emulador Android. Abre un emulador manualmente si flutter run no encuentra dispositivo."
    return 0
  fi

  avd_name="$("$emulator_bin" -list-avds | head -n 1)"

  if [[ -z "$avd_name" ]]; then
    warn "No hay AVDs configurados. Abre un emulador Android manualmente antes de continuar."
    return 0
  fi

  info "No hay emulador activo. Abriendo AVD '$avd_name' ..."
  nohup "$emulator_bin" "@$avd_name" >"$STATE_DIR/emulator.log" 2>&1 &

  info "Esperando a que el emulador este listo ..."
  "$adb_bin" wait-for-device >/dev/null 2>&1 || true
  sleep 10
}

run_flutter() {
  info "Lanzando Flutter en emulador con API_BASE_URL=$ANDROID_API_URL"
  (
    cd "$MOBILE_DIR"
    flutter run --dart-define="API_BASE_URL=$ANDROID_API_URL"
  ) || fail "No se pudo iniciar Flutter en el emulador."
}

main() {
  ensure_project_root
  start_backend
  info "Probando API publica: $API_URL"
  curl -fsS "$API_URL" >/dev/null
  info "API respondiendo correctamente."
  ensure_android_emulator
  run_flutter
}

main "$@"
