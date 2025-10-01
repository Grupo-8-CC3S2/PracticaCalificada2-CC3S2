# PracticaCalificada2-CC3S2
Monitor de endpoints con pipeline CLI seguro

En palabras digeribles pero sin perder rigurosidad, lo que vamos a implementar son varios scripts en bash para que estos sondeen endpoints, estas tareas de comprobaciones se haran usando herramientas unix ya conocidas como : curl, ss, awk , etc.<br>
Entonces para entender incluso en etapa inicial que se pretende lograr presentamos este ejemplo: se quiere monitorear ` http://ejemplo.com/endpoint`<br>
Se quiere saber cuanto tiempo demora en responder `latencia`.<br>
Nos interesa cierta informacion `header` especifica del endpoint `Content Type` y por su puesto queremos alertar ciertos comportamientos `umbral de latencia` , de modo que si la respuesta demora mas que este, estemos alertados. <br>
De modo que una primera tentativa  seria 
```bash
curl -s -INFORMACION "{CODIGO} {TIEMPO}\n" http://example.com/endpoint

curl -HEADERS - http://example.con/login -DESCARTAR /dev/null | grep -i "Content-Type"

curl -s --write-out "%{http_code} %{time_total}\n" http://example.com/login -o /dev/null

curl -D - -o /dev/null http://example.com/login | grep -i "Content-Type"
```
Makefile va a orquestar el pipeline mediante los targets,
para ello declaramos las variables Make usuales con algunas novedades interesantes como ``.SHELLFLAGS`` con el cual configuramos un modo estricto al mismo estilo que en bash, con ``MAKEFLAGS`` definimos una configuracion global para sobrellevar el uso de variables no declaradas y el uso de reglas implicitas, y en cuanto a``.DELETE_ON_ERROR`` elimina artefactos corruptos<br>
Se introducen ademas los tan utiles linteres, con los cuales analizaremos codigo sin ejecutar, ``shellcheck`` y ``shfmt`` para errores de sintaxis e identacion



En makefile se implementa el target build run que documentara la ejecucion del sondeo en latencias.csv<br>
Es este un prerrequisito suyo,siendo el ultimo tambien un target 
```bash
run:$(OUT_DIR)/latencias.csv #### ejecuta monitor y genera CSV

$(OUT_DIR)/latencias.csv: $(SRC_DIR)/check-endpoint.sh
	mkdir -p $(@D)
	@TARGETS=$${TARGETS:-https://example.com} $(SHELL) $<
```
De modo que se ejecuta ``test_monitor.bats`` alli exportamos el TARGETS de modo que make pueda asignarle valores<br>
Ejecutamos haciendo la llamada a make run o realizando la ejecucion manual
```bash
@test ".."
export TARGETS="https://example.com"
  run bash -lc 'make run'
  if [ "$status" -ne 0 ]; then
    run bash -lc './src/monitor.sh'
  fi
```
Se verifica que exista el archivo latencias.csv<br>
Y que contenga filas ademas de la cabecera<br>
Verificando ademas que las repuestas ya parseadas tengan el formato correspondiente
```bash
 run bash -lc 'tail -n +2 out/latencias.csv | head -n 1'
  [ "$status" -eq 0 ] 

  run bash -lc 'line=$(tail -n +2 out/latencias.csv | head -n1); [[ "$line" =~ ^[^,]+,[^,]+,[0-9]{3},[0-9]+$ ]] && echo OK'
  [ "$status" -eq 0 ]
```
En el cuerpo del archivo bats ``./src/check-endpoint.sh`` ejecutando ``check-endpoint.sh``<br>
Se verifica la existencia del archivo csv para la persistencia
creando este de ser necesario con los campos de interes como su primera fila
```bash
if [[ ! -f "$CSV" ]]; then
  echo "timestamp,target,http_codigo,tiempo_ms" > "$CSV"
fi
```
Ademas, es la variable TARGETS quien contiene el endpoint objetivo, de modo que se debe confirmar que no sea nula
en ``if [[ -z "${TARGETS:-}" ]]``<br>
A su vez es necesario detallar la hora del sondeo 
``
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
`` configurado esto se tiene el escenario listo para el sondeo 
```bash
for TARGETS:
    salida ← consulta curl
    if salida:
        http_code ← $1 de salida
        tiempo_ms ← $2 de salida
        if error
    else:
        no asignar http tiempo_ms
```
Que es 
```bash
for objetivo in $TARGETS; do
  if salida=$(curl ${CURL_OPTS:-} -sS -o /dev/null -w "%{http_code} %{time_total}" "$objetivo"); then
    http_codigo=$(echo "$salida" | awk '{print $1}')
    tiempo_ms=$(echo "$salida" | awk '{printf("%d", $2*1000)}')
    if [[ "$http_codigo" -ne 200 ]]; then
      fallo=1
    fi
  else
    http_codigo=0
    tiempo_ms=0  
    fallo=1
  fi
  # registrar en CSV
  echo "$timestamp,$objetivo,$http_codigo,$tiempo_ms" >> "$CSV"
done
```
Recorremos TARGETS ejecutando el sondeo para cada uno de los endpoint, se usa el ya conocido ``$()`` comando se sustitucion, el cliente curl es provisto de muchas opciones mediante flags, uno de los cuales es ``CURL_OPTS`` que permite usar ``--max-time`` tiempo maximo permitido para obtener el request.<br>
La ``salida `` de la consulta es parseado via ``àwk`` usando el separador espacio por defecto asignando los campos ``$1`` y ``$2`` 
```bash
http_codigo=$(echo "$salida" | awk '{print $1}')
    tiempo_ms=$(echo "$salida" | awk '{printf("%d", $2*1000)}')
  
```
a http_code y tiempo_ms respectivamente.<br>
Seguidamente se usa el ``[[ "$http_code" -ne 200]]`` que es el operador condicional evaluando si http_code es disntinto a 200, si lo es, significado que ha habiado un error.