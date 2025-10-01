# Contrato de salida: `out/latencias.csv`

## Estudiante: Sanchez Vega Andre Alvaro

### Definición formal (contrato)
- Cabecera: `ts,target,http_code,time_ms`
- Campos:
  - ts → ISO 8601 UTC
  - target → URL
  - http_code → número de 3 dígitos
  - time_ms → entero ≥ 0
- Delimitador: `,`
- Encoding: UTF-8
- Reglas de evolución: cabecera fija, columnas extra solo en S2/S3.

### Validar que existe al menos una fila de datos (además de cabecera)

```bash
[ "$(wc -l < out/latencias.csv)" -ge 2 ] echo "OK: tiene filas"
```

### Validar formato de cada fila: ts,target,http_code,time_ms
```bash
tail -n +2 out/latencias.csv | grep -Eq '^[^,]+,[^,]+,[0-9]{3},[0-9]+$' && echo "OK: formato válido"
```

### Ejemplo de contenido esperado
```
ts,target,http_code,time_ms
2025-09-30T15:12:45Z,https://example.com,200,234
2025-09-30T15:12:45Z,https://facebook.com/login,302,421
```
```
OK: tiene filas
OK: formato válido
```
## Estudiante: Quispe Villena Renzo

### Script `check-endpoint.sh` para monitoreo de endpoints

Comandos usados:

```sh
TARGETS="https://github.com http://github.com https://httpbin.org/status/404 http://localhost:3001" BUDGET_MS=950 ./src/check-endpoint.sh
```

Información guardada en `out/latencias.csv` :

```
timestamp,target,p50,p75,p90,http_codigo
2025-10-01T02:17:52Z,https://github.com,892,1268,2103,200
2025-10-01T02:17:52Z,http://github.com,209,211,211,301
2025-10-01T02:17:52Z,https://httpbin.org/status/404,436,797,927,404
2025-10-01T02:17:52Z,http://localhost:3001,0,0,0,000
```
Tenemos que:

- Umbral de latencia: `BUDGET_MS=950`(950 ms)
- `https://github.com`: 200 OK, con latencias percentil p50=892 ms, p75=1268 ms y p90=2103 ms. Servicio accesible a través de internet, tiempos relativamente altos pero aceptables considerando el tráfico hacia GitHub.
- `http://github.com`: 301 Redirección a HTTPS, con latencias bajas (209–211 ms). El servicio solo funciona en HTTPS, por eso devuelve redirección cuando se accede por HTTP.
- `https://httpbin.org/status/404`: 404 Not Found, con latencias entre 436 ms y 927 ms. El host responde correctamente, pero el endpoint solicitado no existe(se uso un endpoint de pruebas)
- `http://localhost:3001`: falló (0 — servicio no escuchando).


### Ejemplo de salida(logs) 

```
jquispe@pc1-quispe:~/Escritorio/cursos/Actividades/PracticaCalificada2-CC3S2$ TARGETS="https://github.com http://github.com https://httpbin.org/status/404 http://localhost:3001" BUDGET_MS=950 ./src/check-endpoint.sh
latencias.csv actualizado: (2025-10-01T02:15:14Z,https://github.com,882,885,889,200)
latencias.csv actualizado: (2025-10-01T02:15:14Z,http://github.com,209,209,213,301)
latencias.csv actualizado: (2025-10-01T02:15:14Z,https://httpbin.org/status/404,440,464,952,404)
ALERTA: Error http 404 en https://httpbin.org/status/404
ALERTA: el percentil p90 (952 ms) excede el presupuesto de 950 ms para https://httpbin.org/status/404
latencias.csv actualizado: (2025-10-01T02:15:14Z,http://localhost:3001,0,0,0,000)
```