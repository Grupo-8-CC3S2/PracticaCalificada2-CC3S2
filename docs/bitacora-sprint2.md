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