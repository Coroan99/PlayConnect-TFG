#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MOBILE_DIR="$PROJECT_ROOT/mobile"
DEFAULT_IP=""

info() {
  printf '[INFO] %s\n' "$1"
}

fail() {
  printf '[ERROR] %s\n' "$1" >&2
  exit 1
}

detect_local_ip() {
  local candidates=(en0 en1)

  for iface in "${candidates[@]}"; do
    if ip="$(ipconfig getifaddr "$iface" 2>/dev/null)" && [[ -n "$ip" ]]; then
      printf '%s\n' "$ip"
      return 0
    fi
  done

  return 1
}

ensure_project_root() {
  [[ "$(pwd -P)" == "$PROJECT_ROOT" ]] || fail "Debes ejecutar este script desde la raiz del proyecto: $PROJECT_ROOT"
  [[ -d "$MOBILE_DIR" ]] || fail "No existe mobile/."
  [[ -f "$MOBILE_DIR/pubspec.yaml" ]] || fail "No se ha encontrado mobile/pubspec.yaml."
}

resolve_ip() {
  local provided_ip="${1:-}"

  if [[ -n "$provided_ip" ]]; then
    printf '%s\n' "$provided_ip"
    return 0
  fi

  if [[ -n "$DEFAULT_IP" ]]; then
    info "IP local detectada: $DEFAULT_IP"
  else
    info "No se ha detectado automaticamente la IP local."
  fi

  printf 'Introduce la IP local del Mac para el movil real: ' >&2
  read -r typed_ip

  if [[ -z "$typed_ip" ]]; then
    fail "Debes indicar una IP local para generar la APK de demo."
  fi

  printf '%s\n' "$typed_ip"
}

build_apk() {
  local ip="$1"
  local api_url="http://$ip:3000/api"

  info "Generando APK release con API_BASE_URL=$api_url"
  (
    cd "$MOBILE_DIR"
    flutter build apk --release --dart-define="API_BASE_URL=$api_url"
  ) || fail "No se pudo generar la APK release."

  printf '\n'
  printf 'APK generada en:\n'
  printf '%s\n' "$MOBILE_DIR/build/app/outputs/flutter-apk/app-release.apk"
}

main() {
  ensure_project_root
  DEFAULT_IP="$(detect_local_ip || true)"
  local ip
  ip="$(resolve_ip "${1:-}")"
  build_apk "$ip"
}

main "$@"
