
## Script `check-endpoint.sh` para monitoreo de endpoints

Comandos usados:

```sh
TARGETS="https://github.com http://localhost:3001" ./src/check-endpoint.sh
TARGETS="https://endpoint-no-existe.com http://localhost:3002 http://github.com" ./src/check-endpoint.sh
```

Información guardada en `out/latencias.csv` :

```
timestamp,target,http_codigo,tiempo_ms
2025-09-28T22:42:43Z,https://github.com,200,897
2025-09-28T22:42:43Z,http://localhost:3001,200,2
2025-09-28T22:44:35Z,https://endpoint-no-existe.com,0,0
2025-09-28T22:44:35Z,http://localhost:3002,0,0
2025-09-28T22:44:35Z,http://github.com,301,356
```
Tenemos que:

- `https://github.com` OK (200, 897 ms)
- `http://localhost:3001` OK (200, 2 ms). Exit code = 0. (Se creo un servidor http basico con `python3 -m http.server 3001` para estas pruebas)
- `https://endpoint-no-existe.com` falló (0 — probable DNS/host no existente)
- `http://localhost:3002` falló (0 — servicio no escuchando)
- `http://github.com` respondió 301 (redirección a HTTPS) en 356 ms. Exit code = 1 por los fallos de conexión.


#### Ejemplo de salida para endpoints con errores: 

```
jquispe@pc1-quispe:~/Escritorio/cursos/Actividades/PracticaCalificada2-CC3S2$ TARGETS="http://localhost:5001 https://endpoint-no-existe.com" ./src/check-endpoint.sh
curl: (7) Failed to connect to localhost port 5001 after 0 ms: Could not connect to server
curl: (6) Could not resolve host: endpoint-no-existe.com
```