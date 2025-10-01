# Bitácora Sprint-1: Script para monitoreo de endpoints

## Estudiante: Flores Villar Esau

-  
1. Se amplia suite de pruebas con Bats (tests/): - Positivos: verifica código 200 y latencia dentro de presupuesto. - Negativos: endpoint con 404, con 500 y con timeout (--max-time).
 

```bash
TARGETS="https://httpbin.org/status/200"
TARGETS="https://httpbin.org/status/404"
TARGETS="https://httpbin.org/status/500"
TARGETS="https://httpbin.org/delay/5"
```

Información guardada en `out/latencias.csv`:
 

Explicación de cada fila del archivo `out/latencias.csv`:

Resultados:

```bash
✓ endpoint valido http_code 200
 ✓ endpoint inexistente devuelve 404
 ✓ endpoint devuelve 500
 ✓ endpoint con timeout
```
ejecutar : bats tests/test_http.bats

2. Makefile - Se Mejora test: para correr todas las pruebas Bats. Usando globbing  
``bats $(TEST_DIR)/*.bats``

ejecutar: make test

3. (administración/procesos):
Se implementa el target monitor para sondear cada ciertos segundos 
```bash
while true;do\
		bash $(SCRIPT);\
		sleep 3;\
	done

```
ejecutar: make monitor & 
finalizar : 
```bash
ps aux | grep check-endpoint.sh 
kill ID
```
