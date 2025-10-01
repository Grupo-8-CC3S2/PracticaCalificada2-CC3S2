#!/usr/bin/env bats

setup() {
  rm -rf out
  mkdir -p out
}

@test "endpoint valido http_code 200" {
  export TARGETS="https://httpbin.org/status/200"
  run bash -lc './src/check-endpoint.sh'
  [ "$status" -eq 0 ]
  grep 200 out/latencias.csv
}

@test "endpoint inexistente devuelve 404" {
  export TARGETS="https://httpbin.org/status/404"
  run bash -lc './src/check-endpoint.sh'
  [ "$status" -ne 0 ]
  grep "404" out/latencias.csv
}

@test "endpoint devuelve 500" {
  export TARGETS="https://httpbin.org/status/500"
  run bash -lc './src/check-endpoint.sh'
  [ "$status" -ne 0 ]
  grep "500" out/latencias.csv
}

@test "endpoint con timeout" {
  # Endpoint que demora 5s, configuramos timeout a 2s
  export TARGETS="https://httpbin.org/delay/5"
  run bash -lc 'CURL_OPTS="--max-time 2" ./src/check-endpoint.sh'
  [ "$status" -ne 0 ]
  grep "0,0" out/latencias.csv
}