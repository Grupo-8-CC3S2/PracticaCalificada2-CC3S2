# Bitácora Sprint-1: Script para monitoreo de endpoints

## Estudiante: Quispe Villena Renzo

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

## Estudiante: Flores Esau

Se pretende conseguir automatizar la construccion y el empaquetado
1. Creacion de directorios y variables en Makefile
```bash
SRC_DIR := src
OUT_DIR := out
DIST_DIR := dist
```
y configuracion de las opciones de ejecucion
```bash
.SHELLFLAGS := -o errexit -o nounset -o pipefail -c
MAKEFLAGS += --warn-undefined-variables --no-builtin-rules
.DELETE_ON_ERROR:
```
2. Targets<br>
Ademas de los targets tools , deps, clean, help se implementó build  y package.
```bash
build: $(OUT_DIR)/monitor.log

$(OUT_DIR)/monitor.log: $(SRC_DIR)/monitor.sh
	mkdir -p $(@D)
	$(SHELL) $< > $@

package: $(DIST_DIR)/monitor.tar.gz

$(DIST_DIR)/monitor.tar.gz: $(OUT_DIR)/monitor.log
	mkdir -p $(@D)
	tar --sort=name --owner=0 --group=0 --numeric-owner --mtime='UTC 1970-01-01' -czf $@ -C $(OUT_DIR) monitor.log
```
3. El script monitor.sh que a futuro sera sustituido,ocupando su lugar la implementacion de grupo.
```bash
resultado=$(curl --write-out "%{http_code} %{time_total}" "$ENDPOINT" )
http_code=$(echo "$resultado" | awk '{print $1}')
time_total=$(echo "$resultado" | awk '{print $2}')
```
### Resultados obtenidos
Targets operativos<br>
Artefacto monitor.log a partir de monitor.sh<br>
Empaquetado monitor.tar.gz

## Estudiante: Sanchez Vega Andre (rama feature/parser)
### Rama: feature/parser
#### Rol en Sprint 1: Definición de contrato CSV + helper lib_csv.sh + prueba Bats

## Tareas realizadas
- Implementé src/lib_csv.sh con la función csv_append que asegura cabecera y valida campos.

- Creé el archivo docs/contrato-salidas.md con la definición formal del CSV (cabecera, campos, validaciones).

- Desarrollé la primera prueba automatizada en tests/test_monitor.bats siguiendo la técnica AAA/RGR.

- Ajusté el Makefile junto al equipo para que el target test corra Bats.

## Comandos ejecutados

```
# Ejecutar monitor y generar CSV
make run

# Validar manualmente que existe el archivo CSV
ls -l out/latencias.csv


# Ejecutar pruebas Bats
bats tests/test_monitor.bats
```

## Evidencia de Salida

```
$ bats tests/test_monitor.bats
 ✓ monitor genera out/latencias.csv con fila válida

1 test, 0 failures
```

- Del archivo out/latencias.csv generado:
```
ts,target,http_code,time_ms
2025-09-30T20:19:36Z,http://facebook.com/login,301,69
2025-09-30T20:19:39Z,http://facebook.com/login,301,29
```

#### Decisiones tomadas

- Definimos que la cabecera oficial será ts,target,http_code,time_ms.
- Los tiempos se normalizan en milisegundos enteros para simplificar validación.4
- La prueba Bats valida que exista el CSV y que cada fila cumpla con el contrato.