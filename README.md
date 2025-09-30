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
Se introducen ademas los tan utiles linteres, con los cuales analizaremos codigo sin ejecutar, ``shellcheck`` y ``shfmt`` para errores de sintaxis e identacion respectivamente.
