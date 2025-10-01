# Bitácora Sprint-2

## Estudiante: Quispe Villena Renzo

- [Video Sprint 2 - Quispe Villena Renzo](https://drive.google.com/file/d/1KZjdAIglchqHLy9Lo0dI4QPUUBWSHGVl/view?usp=sharing)

En esta nueva versión de `check-endpoint.sh` añadí un umbral de latencia configurable (variable `BUDGET_MS` como límite de latencia aceptable) que permite evaluar si la respuesta de un endpoint es aceptable en tiempo de respuesta, cuando la latencia percentil p90 (se usa 20 muestras de latencia) medida supera el limite definido, el script genera una alerta en la salida, tambien agregue un control más estricto para códigos de estado HTTP negativos(404, 500 o 000), estos se marcan como alertas.

Explicación de percentiles:

- p50: el 50% de las peticiones son más rápidas que este valor.
- p90: El 90 % de las peticiones no superan este tiempo, el 10 % restante son más lentas (usuarios en la cola larga).

Comandos usados para las pruebas:

```sh
TARGETS="https://github.com http://github.com https://httpbin.org/status/404 http://localhost:3001" BUDGET_MS=950 ./src/check-endpoint.sh
```

Información guardada en `out/latencias.csv`:

```
timestamp,target,p50,p75,p90,http_codigo
2025-10-01T02:17:52Z,https://github.com,892,1268,2103,200
2025-10-01T02:17:52Z,http://github.com,209,211,211,301
2025-10-01T02:17:52Z,https://httpbin.org/status/404,436,797,927,404
2025-10-01T02:17:52Z,http://localhost:3001,0,0,0,000
```
Explicación de cada fila del archivo `out/latencias.csv`:

- `https://github.com`: 200 OK, con latencias percentil p50=892 ms, p75=1268 ms y p90=2103 ms. Servicio accesible a través de internet, tiempos relativamente altos pero aceptables considerando el tráfico hacia GitHub.
- `http://github.com`: 301 Redirección a HTTPS, con latencias bajas (209–211 ms). El servicio solo funciona en HTTPS, por eso devuelve redirección cuando se accede por HTTP.
- `https://httpbin.org/status/404`: 404 Not Found, con latencias entre 436 ms y 927 ms. El host responde correctamente, pero el endpoint solicitado no existe(se uso un endpoint de pruebas)
- `http://localhost:3001`: falló (0 — servicio no escuchando).

En casos donde el host no exista (por ejemplo `https://endpoint-no-existe.com`) o el puerto no tenga un servicio escuchando (como `http://localhost:3001`), se obtiene código 000 y latencias en 0, lo que indica fallo de conexión.


## Estudiante: Sanchez Vega Andre Alvaro

### Objetivo de mi parte en Sprint 2
Implementar un **parser robusto en Bash** (`src/parser_resumen.sh`) que procese el archivo de entrada `out/latencias.csv` generado por el Integrante A y produzca:
1. `out/resumen_por_target.csv` → métricas agregadas por cada endpoint (p50/p75/p90 promedio, p90 máximo, tasas de códigos HTTP, alertas acumuladas, último timestamp).
2. `out/alertas_resumen.csv` → registro de alertas fila a fila (si p90 excede `$BUDGET_MS`).

Además:
- Integrar el parser con el **Makefile** (`make parse`).
- Validar **idempotencia** (no recalcular si no cambian entradas).
- Escribir **pruebas Bats** que confirmen cabeceras, idempotencia y manejo de errores.

### Entrada consumida
Archivo `out/latencias.csv` generado por el script `check-endpoint.sh` (Integrante A).

Cabecera esperada en Sprint 2:
```
timestamp,target,p50,p75,p90,http_codigo
```

### Artefactos generados por mi parser
- **out/resumen_por_target.csv**
  ```
  target,muestras,p50_avg_ms,p75_avg_ms,p90_avg_ms,p90_max_ms,rate_2xx,rate_3xx,rate_4xx,rate_5xx,rate_000,alertas_p90_excedidas,ult_ts
  https://github.com,1,892,1268,2103,2103,1.0000,0.0000,0.0000,0.0000,0.0000,1,2025-10-01T02:17:52Z
  http://github.com,1,209,211,211,211,0.0000,1.0000,0.0000,0.0000,0.0000,0,2025-10-01T02:17:52Z
  https://httpbin.org/status/404,1,436,797,927,927,0.0000,0.0000,1.0000,0.0000,0.0000,0,2025-10-01T02:17:52Z
  http://localhost:3001,1,0,0,0,0,0.0000,0.0000,0.0000,0.0000,1.0000,0,2025-10-01T02:17:52Z
  ```

- **out/alertas_resumen.csv**
  ```
  timestamp,target,p90_ms,http_codigo,alerta_p90_excede
  2025-10-01T02:17:52Z,https://github.com,2103,200,SI
  2025-10-01T02:17:52Z,http://github.com,211,301,NO
  2025-10-01T02:17:52Z,https://httpbin.org/status/404,927,404,NO
  2025-10-01T02:17:52Z,http://localhost:3001,0,000,NO
  ```

### Ejecución y validaciones

**1. Generar artefactos**
```bash
BUDGET_MS=950 make parse
[parser] generado: out/resumen_por_target.csv y out/alertas_resumen.csv
[parse] listo: out/resumen_por_target.csv ; out/alertas_resumen.csv
```

**2. Validar cabeceras (contrato de salida)**
```bash
head -1 out/resumen_por_target.csv | grep -qx 'target,muestras,p50_avg_ms,p75_avg_ms,p90_avg_ms,p90_max_ms,rate_2xx,rate_3xx,rate_4xx,rate_5xx,rate_000,alertas_p90_excedidas,ult_ts' && echo "OK resumen"
# Resultado: OK resumen

head -1 out/alertas_resumen.csv | grep -qx 'timestamp,target,p90_ms,http_codigo,alerta_p90_excede' && echo "OK alertas"
# Resultado: OK alertas
```

**3. Verificar alertas activas**
```bash
grep ',SI$' out/alertas_resumen.csv || echo "Sin alertas por p90"
# Resultado: 2025-10-01T02:17:52Z,https://github.com,2103,200,SI
```

**4. Idempotencia con Make**
```bash
time make parse
# real    0m0.059s
time make parse
# real    0m0.031s
time make parse
# real    0m0.026s
```
> La segunda y tercera ejecución fueron inmediatas porque los archivos de salida ya estaban actualizados. Esto demuestra **caché incremental e idempotencia**.

---

### Pruebas Bats

Archivo: `tests/test_parser_resumen.bats`

Ejecutando:
```bash
make test
```

Resultados:
```
test_monitor.bats
 ✓ monitor genera out/latencias.csv con fila válida
test_parser_resumen.bats
 ✓ Parser: genera resumen y alertas con cabeceras correctas
 ✓ Parser: idempotencia (no recalcula si no cambian entradas)
 ✓ Parser: falla con cabecera inválida (código 5)

4 tests, 0 failures
```

