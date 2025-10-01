SHELL := bash
.SHELLFLAGS := -o errexit -o nounset -o pipefail -c
MAKEFLAGS += --warn-undefined-variables --no-builtin-rules
.DELETE_ON_ERROR:

.PHONY: tools build test run package clean help deps parse metrics verify-contratos

SHELLCHECK :=shellcheck
SHFMT :=shfmt
SRC_DIR :=src
TEST_DIR :=tests
OUT_DIR :=out
DIST_DIR :=dist
SCRIPT :=$(SRC_DIR)/check-endpoint.sh
all: tools lint build test package

build: $(OUT_DIR)/monitor.log ## build dummy (evidencia)
$(OUT_DIR)/monitor.log: $(SRC_DIR)/check-endpoint.sh
	mkdir -p $(@D)
	$(SHELL) $< > $@

test: ## ejecuta pruebas bats
	@bats tests/*.bats

package: $(DIST_DIR)/monitor.tar.gz ## Empaqueta artefactos determinísticamente

$(DIST_DIR)/monitor.tar.gz: $(OUT_DIR)/monitor.log
	mkdir -p $(@D)
	tar --sort=name --owner=0 --group=0 --numeric-owner --mtime='UTC 1970-01-01' -czf $@ -C $(OUT_DIR) monitor.log

deps: ##este target instala dependencias
	@command -v $(SHELLCHECK) >/dev/null || { echo "instalando  shellcheck"; sudo apt update && sudo apt install shellcheck -y; }
	@command -v $(SHFMT) >/dev/null || { echo "instalando shfmt"; sudo apt update && sudo apt install shfmt -y; }
	@tar --version 2 >/dev/null | grep -q 'GNU tar' || { echo "instalando tar"; sudo apt update && sudo apt install tar -y ; }

tools: deps##este target verifica dependencias
	@command -v $(SHELLCHECK) >/dev/null || { echo "shellcheck no instalado "; exit 1; }
	@command -v $(SHFMT) >/dev/null || { echo "shfmt no instalado"; exit 1 ; }
	@command -v grep >/dev/null || { echo "falta grep "; exit 1; }
	@command -v awk >/dev/null || { echo "awk ausente "; exit 1; }
	@tar --version 2>/dev/null | grep -q 'GNU tar' || { echo "Se debe instalar GNU tar"; exit 1; }
	@command -v sha256sum >/dev/null || { echo "Falta sha256sum"; exit 1; }

clean: ## target de limpieza
	@rm -rf $(OUT_DIR) $(DIST_DIR)

help: ## visualizacion de descripcion de targets
	@grep -E '^[a-zA-Z0-9_-]+:.*##' $(MAKEFILE_LIST) | awk -F ':|##' '{printf " %s %s\n" ,$$1,$$3}'

run: ## ejecuta monitor y genera CSV
	@TARGETS=$${TARGETS:-https://example.com} $(SHELL) $(SRC_DIR)/check-endpoint.sh

## Calcula métricas agregadas (resumen) y alertas desde out/latencias.csv
parse: $(OUT_DIR)/resumen_por_target.csv $(OUT_DIR)/alertas_resumen.csv
	@echo "[parse] listo: $(OUT_DIR)/resumen_por_target.csv ; $(OUT_DIR)/alertas_resumen.csv"

$(OUT_DIR)/resumen_por_target.csv $(OUT_DIR)/alertas_resumen.csv: $(OUT_DIR)/latencias.csv src/parser_resumen.sh
	@./src/parser_resumen.sh $(OUT_DIR)/latencias.csv

## Alias de métricas
metrics: parse

verify-contratos: ## Verifica cabeceras de artefactos
	@head -1 out/resumen_por_target.csv | grep -qx 'target,muestras,p50_avg_ms,p75_avg_ms,p90_avg_ms,p90_max_ms,rate_2xx,rate_3xx,rate_4xx,rate_5xx,rate_000,alertas_p90_excedidas,ult_ts'
	@head -1 out/alertas_resumen.csv | grep -qx 'timestamp,target,p90_ms,http_codigo,alerta_p90_excede'
	@echo "[verify] contratos OK"

monitor:
	while true;do\
		bash $(SCRIPT);\
		sleep 3;\
	done