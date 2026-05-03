#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$PROJECT_ROOT/backend"
MOBILE_DIR="$PROJECT_ROOT/mobile"
API_PUBLICACIONES_URL="http://localhost:3000/api/publicaciones"
API_DB_TEST_URL="http://localhost:3000/db-test"

info() {
  printf '[INFO] %s\n' "$1"
}

fail() {
  printf '[ERROR] %s\n' "$1" >&2
  exit 1
}

ensure_project_root() {
  [[ "$(pwd -P)" == "$PROJECT_ROOT" ]] || fail "Debes ejecutar este script desde la raiz del proyecto: $PROJECT_ROOT"
  [[ -d "$BACKEND_DIR" ]] || fail "No existe backend/."
  [[ -d "$MOBILE_DIR" ]] || fail "No existe mobile/."
}

check_backend() {
  info "Comprobando backend en http://localhost:3000 ..."

  if ! curl -fsS "$API_PUBLICACIONES_URL" >/dev/null 2>&1; then
    fail "El backend no responde en $API_PUBLICACIONES_URL. Arranca primero XAMPP/MySQL y el backend."
  fi

  info "Comprobando conexion con MySQL ..."

  if ! curl -fsS "$API_DB_TEST_URL" >/dev/null 2>&1; then
    fail "El endpoint /db-test no responde. Revisa MySQL/XAMPP o la configuracion de backend/.env."
  fi
}

run_flutter_checks() {
  info "Ejecutando flutter analyze ..."
  (
    cd "$MOBILE_DIR"
    flutter analyze
  ) || fail "flutter analyze ha fallado."

  info "Ejecutando flutter test ..."
  (
    cd "$MOBILE_DIR"
    flutter test
  ) || fail "flutter test ha fallado."
}

print_summary() {
  printf '\n'
  printf '========================================\n'
  printf 'Resumen de comprobacion de demo\n'
  printf '========================================\n'
  printf 'Backend: OK\n'
  printf 'API /api/publicaciones: OK\n'
  printf 'API /db-test: OK\n'
  printf 'flutter analyze: OK\n'
  printf 'flutter test: OK\n'
}

main() {
  ensure_project_root
  check_backend
  run_flutter_checks
  print_summary
}

main "$@"
