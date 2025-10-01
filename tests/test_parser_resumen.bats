#!/usr/bin/env bats

setup() {
  rm -rf out
  mkdir -p out
  cat > out/latencias.csv <<'CSV'
timestamp,target,p50,p75,p90,http_codigo
2025-10-01T02:17:52Z,https://github.com,892,1268,2103,200
2025-10-01T02:17:52Z,http://github.com,209,211,211,301
2025-10-01T02:17:52Z,https://httpbin.org/status/404,436,797,927,404
2025-10-01T02:17:52Z,http://localhost:3001,0,0,0,000
2025-10-01T02:20:00Z,https://github.com,500,800,1200,200
CSV
}

@test "Parser: genera resumen y alertas con cabeceras correctas" {
  run env BUDGET_MS=1000 ./src/parser_resumen.sh out/latencias.csv
  [ "$status" -eq 0 ]
  [ -f "out/resumen_por_target.csv" ]
  [ -f "out/alertas_resumen.csv" ]

  run head -1 out/resumen_por_target.csv
  [[ "$output" =~ target,muestras,p50_avg_ms,p75_avg_ms,p90_avg_ms,p90_max_ms,rate_2xx,rate_3xx,rate_4xx,rate_5xx,rate_000,alertas_p90_excedidas,ult_ts ]]

  run head -1 out/alertas_resumen.csv
  [[ "$output" =~ timestamp,target,p90_ms,http_codigo,alerta_p90_excede ]]
}

@test "Parser: idempotencia (no recalcula si no cambian entradas)" {
  env BUDGET_MS=1000 ./src/parser_resumen.sh out/latencias.csv
  ts1=$(stat -c %Y out/resumen_por_target.csv)
  sleep 1
  run env BUDGET_MS=1000 ./src/parser_resumen.sh out/latencias.csv
  [ "$status" -eq 0 ]
  ts2=$(stat -c %Y out/resumen_por_target.csv)
  [ "$ts1" -eq "$ts2" ]
}

@test "Parser: falla con cabecera inválida (código 5)" {
  echo "bad,header" > out/latencias.csv
  run ./src/parser_resumen.sh out/latencias.csv
  [ "$status" -eq 5 ]
}
