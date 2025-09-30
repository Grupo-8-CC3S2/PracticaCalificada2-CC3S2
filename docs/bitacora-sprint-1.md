## Bitácora Sprint-1: Script para monitoreo de endpoints

- Estudiante: Quispe Villena Renzo

- [Video Sprint 1 - Quispe Villena Renzo](https://drive.google.com/file/d/1AdOG4_2TtodTTUVzU8rHmtlm9IPov9MP/view?usp=sharing)

Desarrollé un script `check-endpoint.sh` para monitoreo de endpoints. Para cada URL definida en la variable `TARGETS`, guarda en un CSV el momento, la URL, el código de respuesta y la latencia.

Comandos usados para las pruebas:

```sh
TARGETS="https://github.com http://localhost:3001" ./src/check-endpoint.sh
TARGETS="https://endpoint-no-existe.com http://localhost:3002 http://github.com" ./src/check-endpoint.sh
```

Información guardada en `out/latencias.csv`:

```
timestamp,target,http_codigo,tiempo_ms
2025-09-28T22:42:43Z,https://github.com,200,897
2025-09-28T22:42:43Z,http://localhost:3001,200,2
2025-09-28T22:44:35Z,https://endpoint-no-existe.com,0,0
2025-09-28T22:44:35Z,http://localhost:3002,0,0
2025-09-28T22:44:35Z,http://github.com,301,356
```
Explicación de cada fila del archivo `out/latencias.csv`:

- `https://github.com` OK (200, 897 ms). Funciona correctamente, servicio accesible a través de internet, 897ms como latencia es aceptable.
- `http://localhost:3001` OK (200, 2 ms). Exit code = 0. (Se creo un servidor http basico con `python3 -m http.server 3001` para estas pruebas, por eso latencia es muy baja)
- `https://endpoint-no-existe.com` falló (0 — DNS/host no existente)
- `http://localhost:3002` falló (0 — servicio no escuchando). En las pruebas si tenía un servicio http en el puerto 3001 pero no el 3002.
- `http://github.com` respondió 301 (redirección a HTTPS) en 356 ms. Exit code = 1 por los fallos de conexión. Servicio funcionando en https no en http.

