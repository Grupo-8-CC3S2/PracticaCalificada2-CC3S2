#!/usr/bin/env bash

set -euo pipefail

mkdir -p out

CSV="out/latencias.csv"

if [[ ! -f "$CSV" ]]; then
  echo "timestamp,target,p50,p75,p90,http_codigo" > "$CSV"
fi

if [[ -z "${TARGETS:-}" ]]; then
  echo "Error: definir la variable TARGETS" >&2
  exit 1
fi

timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# checkeo para cada endpoint
for objetivo in $TARGETS; do
  latencias=()
  http_codigo=0

  # 20 veces curl para cada target, para despues hallar percentiles
  for i in {1..20}; do
    salida=$(curl -sS -o /dev/null -w "%{http_code} %{time_total}" "$objetivo" 2>/dev/null || echo "0 0")
    http_codigo=$(awk '{print $1}' <<< "$salida")
    tiempo_ms=$(awk '{printf("%d", $2*1000)}' <<< "$salida")
    latencias+=("$tiempo_ms")
  done

  # hallamos percentiles
  ordenar_latencias=$(printf "%s\n" "${latencias[@]}" | sort -n)

  p50=$(echo "$ordenar_latencias" | awk 'NR==10 {print $1}')   # latencia mediana (percentil 50)
  p75=$(echo "$ordenar_latencias" | awk 'NR==15 {print $1}')   # latencia que no supera el 75 % de las muestras
  p90=$(echo "$ordenar_latencias" | awk 'NR==18 {print $1}')   # latencia que no supera el 90 % de las muestras

  # logs(alertas)
  echo "latencias.csv actualizado: ($timestamp,$objetivo,$p50,$p75,$p90,$http_codigo)"

  if [[ "$http_codigo" == "404" || "$http_codigo" == "500" || "$http_codigo" == "000" ]]; then
    echo "ALERTA: Error http $http_codigo en $objetivo"
  fi

  if (( p90 > $BUDGET_MS )); then
    echo "ALERTA: el percentil p90 ($p90 ms) excede el presupuesto de $BUDGET_MS ms para $objetivo"
  fi

  # guardar en el CSV
  echo "$timestamp,$objetivo,$p50,$p75,$p90,$http_codigo" >> "$CSV"
done
