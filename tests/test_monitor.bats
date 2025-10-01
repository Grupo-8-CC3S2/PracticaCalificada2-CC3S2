#!/usr/bin/env bats

setup() {
  rm -rf out
  mkdir -p out
}

@test "monitor genera out/latencias.csv con fila válida" {
  export TARGETS="https://example.com"

  # Intenta pipeline estándar (Makefile); si no existe, llama script directo
  run bash -lc 'make run'
  if [ "$status" -ne 0 ]; then
    run bash -lc './src/check-endpoint.sh'
  fi

  # Debe existir CSV
  [ -f "out/latencias.csv" ]

  # Debe existir una fila (no cabecera) y cumplir regex de validación
  run bash -lc 'tail -n +2 out/latencias.csv | head -n 1'
  [ "$status" -eq 0 ]

  # Validar formato: ts,target,http_code,time_ms
  run bash -lc 'line=$(tail -n +2 out/latencias.csv | head -n1); [[ "$line" =~ ^[^,]+,[^,]+,[0-9]{3},[0-9]+$ ]] && echo OK'
  [ "$status" -eq 0 ]
}