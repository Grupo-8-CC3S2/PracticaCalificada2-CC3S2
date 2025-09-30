#!/usr/bin/env bash
set -euo pipefail

# Archivo CSV configurable por variable de entorno
CSV_FILE="${CSV_FILE:-out/latencias.csv}"

csv_header() { echo "ts,target,http_code,time_ms"; }

ensure_csv() {
  mkdir -p "$(dirname "$CSV_FILE")"
  [[ -f "$CSV_FILE" ]] || csv_header > "$CSV_FILE"
}

is_http_code() { [[ "${1:-}" =~ ^[0-9]{3}$ ]]; }
is_uint()      { [[ "${1:-}" =~ ^[0-9]+$   ]]; }

csv_append() {
  local ts="${1:-}" target="${2:-}" code="${3:-}" ms="${4:-}"
  ensure_csv

  [[ -n "$ts" && -n "$target" ]] || { echo "csv_append: ts/target vacíos" >&2; return 1; }
  is_http_code "$code"           || { echo "csv_append: http_code inválido: $code" >&2; return 1; }
  is_uint "$ms"                  || { echo "csv_append: time_ms inválido: $ms" >&2; return 1; }

  printf '%s,%s,%s,%s\n' "$ts" "$target" "$code" "$ms" >> "$CSV_FILE"
}