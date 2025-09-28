#!/usr/bin/env bash

set -euo pipefail

mkdir -p out

CSV="out/latencias.csv"

if [[ ! -f "$CSV" ]]; then
  echo "timestamp,target,http_codigo,tiempo_ms" > "$CSV"
fi

if [[ -z "${TARGETS:-}" ]]; then
  echo "Error: definir la variable TARGETS" >&2
  exit 1
fi

fallo=0
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# checkeo para cada endpoint
for objetivo in $TARGETS; do
  if salida=$(curl -sS -o /dev/null -w "%{http_code} %{time_total}" "$objetivo"); then
    http_codigo=$(echo "$salida" | awk '{print $1}')
    tiempo_ms=$(echo "$salida" | awk '{printf("%d", $2*1000)}')
    exit_code=0
  else
    http_codigo=0
    tiempo_ms=0
    exit_code=1 
    fallo=1
  fi
  # registrar en CSV
  echo "$timestamp,$objetivo,$http_codigo,$tiempo_ms" >> "$CSV"
done

exit $fallo
