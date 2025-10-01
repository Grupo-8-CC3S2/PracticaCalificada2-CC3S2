#!/usr/bin/env bash
set -euo pipefail

IN="${1:-out/latencias.csv}"
OUT_DIR="out"
OUT_RESUMEN="$OUT_DIR/resumen_por_target.csv"
OUT_ALERTAS="$OUT_DIR/alertas_resumen.csv"

mkdir -p "$OUT_DIR"

# Umbral por defecto si no viene de entorno (no romper contrato).
: "${BUDGET_MS:=1000}"

# ---- Validaciones de contrato de entrada ----
if [[ ! -f "$IN" ]]; then
  echo "[parser] no existe archivo de entrada: $IN" >&2
  exit 5
fi

if ! head -1 "$IN" | grep -q '^timestamp,target,p50,p75,p90,http_codigo$'; then
  echo "[parser] cabecera inesperada; se requería: timestamp,target,p50,p75,p90,http_codigo" >&2
  exit 5
fi

# ---- Idempotencia ----
# Si AMBOS outputs existen y son más nuevos que IN, no recalcular.
if [[ -f "$OUT_RESUMEN" && -f "$OUT_ALERTAS" && "$OUT_RESUMEN" -nt "$IN" && "$OUT_ALERTAS" -nt "$IN" ]]; then
  echo "[parser] cache vigente: $OUT_RESUMEN ; $OUT_ALERTAS (no se recalcula)"
  exit 0
fi

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

# ---- Normalización segura de filas (fuerza enteros) ----
tail -n +2 "$IN" | awk -F',' '
  function isnum(x){ return (x ~ /^[0-9]+$/) }
  {
    ts=$1; tgt=$2; p50=$3; p75=$4; p90=$5; code=$6;
    if (ts=="" || tgt=="") next;
    if (!isnum(p50)) p50=0;
    if (!isnum(p75)) p75=0;
    if (!isnum(p90)) p90=0;
    if (!isnum(code)) code=0;
    print ts "," tgt "," p50 "," p75 "," p90 "," code;
  }
' > "$TMP"

# ---- Alertas fila a fila (p90 vs BUDGET_MS) ----
echo "timestamp,target,p90_ms,http_codigo,alerta_p90_excede" > "$OUT_ALERTAS"
awk -F',' -v B="$BUDGET_MS" '
  { alert = ($5 > B ? "SI" : "NO"); print $1 "," $2 "," $5 "," $6 "," alert }
' "$TMP" >> "$OUT_ALERTAS"

# ---- Resumen por target ----
# - Promedios p50/p75/p90
# - p90 máximo
# - tasas por familia HTTP (2xx,3xx,4xx,5xx,000)
# - conteo de alertas por target (p90 > BUDGET_MS)
# - último timestamp lexicográficamente mayor (RFC3339)
echo "target,muestras,p50_avg_ms,p75_avg_ms,p90_avg_ms,p90_max_ms,rate_2xx,rate_3xx,rate_4xx,rate_5xx,rate_000,alertas_p90_excedidas,ult_ts" > "$OUT_RESUMEN"

awk -F',' -v B="$BUDGET_MS" '
{
  tgt=$2; p50=$3+0; p75=$4+0; p90=$5+0; code=$6+0; ts=$1;

  n[tgt]++; s50[tgt]+=p50; s75[tgt]+=p75; s90[tgt]+=p90;
  if (p90 > m90[tgt]) m90[tgt]=p90;

  if (code>=200 && code<300) c2[tgt]++;
  else if (code>=300 && code<400) c3[tgt]++;
  else if (code>=400 && code<500) c4[tgt]++;
  else if (code>=500 && code<600) c5[tgt]++;
  else c0[tgt]++;

  if (p90 > B) a[tgt]++;
  if (ts > last[tgt]) last[tgt]=ts;
}
END{
  for (t in n) {
    nn=n[t]+0
    printf "%s,%d,%.0f,%.0f,%.0f,%.0f,%.4f,%.4f,%.4f,%.4f,%.4f,%d,%s\n",
      t, nn,
      (nn? s50[t]/nn:0),(nn? s75[t]/nn:0),(nn? s90[t]/nn:0),(m90[t]+0),
      (nn? c2[t]/nn:0),(nn? c3[t]/nn:0),(nn? c4[t]/nn:0),(nn? c5[t]/nn:0),(nn? c0[t]/nn:0),
      (a[t]+0),(last[t]?last[t]:"")
  }
}
' "$TMP" | sort -t, -k1,1 >> "$OUT_RESUMEN"

echo "[parser] generado: $OUT_RESUMEN y $OUT_ALERTAS"