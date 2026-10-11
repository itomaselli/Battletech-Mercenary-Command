# Fase III — Operaciones militares / v0.9.0

## Objetivo y plan ejecutado

Dar al comandante decisiones operacionales con consecuencias, conservando contratos, gestión de compañía, personal, mundo y combate abstracto.

1. **Preparación:** plan persistente con aproximación directa o reconocimiento, autoridad del jefe y prioridad del despliegue. El objetivo sigue siendo el del contrato; doctrina, fuerza y jefe mantienen los controles existentes.
2. **Conducción:** aproximación, informe de reconocimiento si corresponde, contacto, fricción y respuesta por decisión del comandante o iniciativa del jefe.
3. **Comunicaciones:** partes atribuidos y fechados; directivas en tránsito durante un día; confirmación de recepción; consultas que detienen el avance.
4. **Consecuencias:** efectos sobre tiempo, suministros, posibilidad de éxito y desgaste; retirada con consecuencias contractuales y extracción abstracta.
5. **Cierre:** archivo de órdenes, partes y daños propios; compatibilidad con operaciones antiguas; pruebas de persistencia, información pública y regresión.

Los pasos se entregan juntos en v0.9.0, formato 17. La simulación adicional está en `sim/operations.gd`, los comandos se integran en el núcleo existente y la interfaz vive en `ui/operations.gd`. No se reemplaza la arquitectura anterior.

## Preparación y órdenes

El plan por defecto es avance directo, autoridad delegada y prioridad al objetivo. No agrega costes ni demora de preparación. El reconocimiento añade cuatro suministros y un día al desplegar; produce una evaluación cualitativa de los accesos y exposición probable. Preparación queda fijada al salir. El plan permanece para despliegues posteriores hasta cambiarlo.

Delegar permite al jefe resolver el contacto. Priorizar el objetivo continúa el encargo y la habilidad del jefe mitiga la fricción. Preservar permite maniobrar con cuatro suministros disponibles; si la integridad media de la fuerza al contacto es inferior al 65%, el jefe ordena retirada. Sin suministros para maniobrar y por encima del umbral, continúa con los medios disponibles y deja constancia. Consultar siempre eleva la elección al comandante: la prioridad no fuerza una retirada mientras espera su decisión.

En marcha se pueden transmitir cambios de autoridad y prioridad. Hay una sola directiva en tránsito; tarda un día y las órdenes vigentes no cambian antes de la recepción. Preparación no se modifica. La nueva autoridad no reabre contactos ya resueltos: solo afecta decisiones posteriores. No se permite enviar otra directiva mientras el jefe espera una respuesta a su consulta.

## Contacto y decisiones

El primer día comunica aproximación o reconocimiento. El segundo comunica un episodio de fricción: acceso obstaculizado, cobertura de radio irregular o movimiento sin identificar. La severidad y el episodio proceden de un generador propio a partir de semilla y número de operación, y se conservan en el guardado. No consumen las tiradas del combate existente ni se vuelven a sortear al cargar.

Si el jefe consulta, la fuerza mantiene posición y el calendario se detiene tras completar ese día. Ese día no reduce el tiempo restante de ejecución, por lo que consultar introduce una jornada adicional en la duración total. Mientras el juego espera la respuesta no pasan días ni se cobran costes diarios. Al responder:

- **Continuar:** sin gasto adicional, el jefe mitiga la fricción según su habilidad.
- **Maniobrar:** cuatro suministros y un día adicional, con mejor posición y menor exposición.
- **Retirarse:** cancelación contractual normal y, tras contacto, tres puntos de daño de extracción por máquina. Antes del contacto no se añade daño. La extracción sigue siendo abstracta e inmediata.

Una decisión solo se aplica una vez. No se puede repetir maniobrar para acumular ventajas. Siempre existe una opción gratuita para continuar o retirarse. Los asuntos de personal siguen bloqueando el calendario según las reglas anteriores.

## Resolución y balance inicial

Se conserva la tirada abstracta, los pagos, lesiones, fatiga, experiencia, historias, confianza y consecuencias del mundo. El reconocimiento suma dos puntos a la fuerza efectiva y resta dos de desgaste por máquina. Maniobrar añade otros dos puntos y reduce otros dos de desgaste. Continuar aplica una presión igual al máximo entre cero y severidad menos habilidad del jefe dividida por tres (división entera); resta esa presión de fuerza y añade el doble al desgaste. Los daños nunca son negativos. Son parámetros de prototipo, sujetos a ajuste de juego.

La nueva incertidumbre no equivale a un orden de batalla enemigo. Las evaluaciones son parciales y no identifican composición ni intención exactas. Las tiradas, severidad y modificadores internos no se exponen en los partes. El plazo principal está marcado como estimación.

## Archivo y compatibilidad

El archivo conserva las últimas 30 operaciones nuevas; la pantalla muestra las tres recientes con todos sus partes y daños por máquina. La crónica sigue conservando las decisiones e informes recibidos. Se archivan tanto éxitos como fracasos y retiradas. Una directiva que no llegó al finalizar queda sin efecto y se informa.

Las partidas hasta v0.8 migran sin modificar su operación en curso ni reconstruir hechos anteriores. Esa operación termina mediante el comportamiento previo. El mando nuevo se aplica al siguiente despliegue. Guardar/cargar conserva consultas, directivas pendientes, fricción ya determinada, órdenes, informes y archivos. Las pruebas usan archivos distintos de la partida del jugador.

## Validación

`tests/phase3.gd`: preparación, costes, pausa de varios días, respuestas inválidas, decisiones repetidas, falta de recursos, órdenes en tránsito, conservación al cargar, retirada delegada, consecuencias, habilidad del jefe, guardados antiguos e inválidos; veinte operaciones con combinaciones de órdenes y semillas, verificadas paso a paso.

`tests/phase3_ui.gd`: preparar plan, aceptar y desplegar desde los controles, avanzar hasta consulta, maniobrar y leer el archivo. Capturas: `operations-plan-preview.png`, `operations-contact-preview.png`, `operations-result-preview.png`. Se ejecutan también todas las suites anteriores.

## Límites deliberados

Una operación simultánea y hasta cuatro máquinas, un episodio de contacto por misión, daño agregado al resolver y extracción simplificada. No incluye mapa táctico, órdenes individuales a cada Mech, maniobras geográficas, refuerzos físicos, armamento por localización ni combate MegaMek. La autonomía depende de órdenes, recursos e integridad y habilidad del jefe; no se inventan rasgos psicológicos privados. La Fase IV queda dedicada a la presentación visual definitiva.


### Validación final de v0.9.0

**1.757 comprobaciones aprobadas**: 1.455 de versiones anteriores, 295 del mando operacional y siete del recorrido de interfaz. También pasaron las pruebas de apertura y personalización. Se verificaron veinte operaciones con distintas semillas y órdenes, consultas guardadas, directivas en tránsito, retirada autónoma, efectos de la habilidad del jefe, archivos y migración de una operación previa. Godot 4.4.1 ejecutó el recorrido con ventana y se revisaron las capturas de contacto y resultado. No se modificó la partida real del jugador.
