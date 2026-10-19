# NetCoreConfMadrid2026

	La idea principal es poder mostrar desde mi punto de vista, como poder productivizar una idea haciendo AI. Y luego en cómo podemos aplicarlo en entornos .net.
	
	
	Experiencia con AI. Siempre me ha entrado la curiosidad de cómo la AI pudiera trabajar con música, llevo dos años mirando períodicamente. MVP-> Desde unas isntrucciones podría obtener una partitura compleja para poder masterizar? La última itreación fue de la siguiente manera.
	
	Quiero crear un micro musical, enfocado en la vida e Rasputin., y quiero que muestre ese efecto WOW que me encanta de cómo en series o pelis, el malo malisimo que empieza siendo odiado acaba siendo querido. La música quiero que sea parecida a estos estilos de musicales con este set de sintrumentos. 
	
	Después de conversar con la AI de las posibilidades, veo que llegamos hasta el midi, pero no es capaz de hacer una postproduccion con librerias de instrumentos reales. Pero conozco Suno, que desde un promt puedes sacar musica chula. Ahí salió mi idea de MVP inicial. Si desde un Midi y un promt especídifo de SUNO. Podría tener un output controlado independientemente de las iteraciones? Porque con el mismo promt en suno a día de hoy el no determinismo es brutal y puedes tener desde un muscial rock a una ranchera.
	
	Iterando sobre la conversación, obtuve el midi y el promt. Se lo pase a Suno varias veces y tuve un resultado bastante similar que me encanta y que no puedo parar de tararear.
	
	Hasta ahí todo bonito, tengo un mp3 que me flipa. Pero la pregunta es, como puedo productivizar esto? Que pueda replicarlo muchas veces, distribuirlo, usarlo, siempre de la misma manera. Porque aunque entienda como se ha hecho, si habro una sesion nueva, probablemente andemos con rework y no termine teniendo el mismo resultado.
	
	- Importancia del Harnes.  Ahora es muy popular hablar de este concepto. Que es? Para que vale? Explicar que es el Harness, como dotando con Contexto, una buena coonstitucion de AI, Skills especificas, agentes, guardarailes, commands, hooks, podemos minimizar le no determinismo y tener una capa que abraza a ala AI para que tenga resultados adecuados a mi planteamiento.

	Pero, como se construye esto? Como desde este MVP, como he cosntruido un harness sencillo. 
	
	Lo primero que hice fue, abrazar en una skill este paso a paso de construcción. Una vez extraida la probé y vi que el resultado era el mismo. Después de esto, la hice invocable. Definí un input específico (Set de instrumentos, estulo, velocidad, etc..) y como resultado un mp3 y un promt de Suno. A esa Skill la llamamos 'maqueta-suno'
	
	Vale, ahora con esa skill, mandandole los parámetros de entrada correctos mi resultado era el esperado. Aquí es importante hacer un refinamiento de la skill para que sea agnotica, una habilidad una finalidad.
	
	Por ahora esto el modo de uso es, invoco la skill y le paso el promt de entrada. Si no tiene los valores los pido. Un ejemplo.  Mostrar el ejemplo de invocación de la skill.
	
	Siguente paso:
	
	Abstraer ese promt en un comando, que acaba llamando a la skill. Ahora ya si llamo a /command directamente me ejecuta todo como quiero. PROS. No elegamos al usuario a poner el promt adecuado
	
	Ahora ya tenemos Command y Skill. -> enseñamos como funciona
	
	Queríendo incrementar esto, yo no soy letrista, y si genero una habilidad de letras y que también le mande esa letra a la skill de suno para que tengamos las dos versiones, instrumental y canción.
	
	Creo la skill y el comando lo mantengo como orquestador. Que tiene que tener de entrada, que llame al letrista y objtenga una letra, que esa letra se la pase al suno compositor y que al final tengamos letra + midi + promt.
	
	Metemos también el Hook de trazas,para ver que se invoca y cómo. Explicamos la telemetría y el enfoque.
	
	Ahora ya podría tener este comando /compositor, siguiente fase. Cómo puedo exportar esto? Paquetizar?
	Aqui hablamos del plugin y del marketplace
	
	Enseñamos la instalación y enseñamos la canción?
	
	FASE de .Net. Porque no replicamos esto a nivel de proyecto? Muy bien. Aqui quiero poder explicar que el expertise que tenemos en las cabezas de cada persona es lo que tenemos que concetrar y tener para que la AI pueda leerlo y tenerlo como contexto, habilidades, etc..
	
	Ejemplo de diferencias de VibeCodign y con método o harness.
	
	Implementamos una skill de .net guardarailes, test, ci. Un comando de generar api por ejemplo y que antes de que termine el plan que pase la ci o los tests?
	
	
	Conclusión?
	
	
	
	
	Quiero hacer un plan.
	
	
	Para ello, vamos, a definir unos giardarrailes de .net,  luego unos test que validen esos giardarrailes, etc..
	
	1. Voy a github a coger una issue con su MCP. Y voy a hacer un plan.  
	2. Voy a github a hacerle un plan ahciendo mención a los gaurdarrailes.

	3. Comando Plan que reciba una issue, que haga el plan teniendo en cuetna a los guardarailes y que antes de ahcer el plan que valide los tests.
Hook? De ejecución de test de forma determinística?
---

## Repositorio de la charla

| Carpeta | Qué hay |
|---|---|
| [`steps/`](steps/README.md) | Guion, tiempos, chuleta y `step.ps1` para avanzar la demo paso a paso |
| `src/`, `tests/` | `Musicales`: API .NET con Aspire siguiendo Platform, con tests de arquitectura y de aceptación (Testcontainers) |
| [`plugins/dotnet-team/`](plugins/dotnet-team/README.md) | El harness que se construye en el acto 2 |

Instalar el harness en cualquier proyecto:

```text
/plugin marketplace add RubenGomGar/NetCoreConfMadrid2026
/plugin install dotnet-team@netcoreconf-2026
```
