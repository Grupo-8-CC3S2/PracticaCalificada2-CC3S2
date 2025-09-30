# Proyecto: Práctica Calificada 2 – Monitor de Endpoints
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
## Resultados obtenidos
Targets operativos<br>
Artefacto monitor.log a partir de monitor.sh<br>
Empaquetado monitor.tar.gz