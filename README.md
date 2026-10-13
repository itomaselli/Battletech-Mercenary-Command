# BattleTech Mercenary Command — v0.46.0 · rama de rediseño

Juego personal independiente de MekHQ, en Godot 4/GDScript. Diriges una compañía desde una terminal de mando: contratas personal, preparas fuerzas, aceptas compromisos, das órdenes y recibes informes. La simulación propia conserva el estado y las consecuencias. No requiere conexión, claves ni assets descargados.

## Interfaz territorial y emblemas — v0.46

Rama `ui/territorial-redesign`: cabecera con identidad y fuerza, menú vertical, mapa central y panel contextual, siguiendo la captura de referencia del usuario. La selección de uno de los 50 emblemas se realiza en **Sistema → Identidad** o **Nueva carrera → Elegir emblema** y se guarda con la campaña. Sprites y generación low-res anteriores conservados.

[Alcance y comprobaciones](docs/UI-PROPUESTA-2.md). La v0.45 permanece en main; esta entrega no la reemplaza. El mapa territorial es ilustrativo: el encuentro jugable y las órdenes se consultan en Batalla.

## Escritorio de mando — v0.45

Bandeja con agenda compacta y paneles independientes; preparación de operaciones por fuerza, plan y confirmación; hangar de tarjetas con expediente lateral; finanzas divididas en previsión, movimientos y categorías; mapas con contexto y acciones laterales. Conserva todos los sprites y reglas de simulación existentes.

[Plan, alcance y validación](docs/UX-v045.md). El mapa local sigue siendo ilustrativo; los encuentros jugables se observan en Batalla.

## Organización de pantallas — v0.44

Operaciones se organiza en **Resumen → Contratos → Plan → Batalla → Informe**, con Encargos separado. Batalla mantiene el mapa, las órdenes laterales y los partes en áreas independientes. El botón de transmitir siempre muestra el sector de destino; grupo seleccionado, orden vigente y orden en tránsito se distinguen. El calendario de campaña queda desactivado mientras se observa un encuentro pendiente: vuelva a Resumen para avanzar días y delegarlo.

Personal, Hangar y Contratos tienen listas paginadas y un expediente identificado. Detalles, historial, negociación y acciones secundarias se despliegan a demanda. La bandeja filtra decisiones, operaciones, compañía y archivo; la crónica muestra primero lo reciente y se pagina. Encabezados, paneles, selección y acciones principales comparten estilos low-res.

[Plan y comprobaciones UX](docs/UX-v044.md). No se modificó el formato de las partidas.

## Operaciones en mapa — v0.38–v0.43

Los nuevos despliegues desde **Operaciones → Preparación** abren un encuentro autónomo en **En curso**. Observe, pause, acelere o delegue. Seleccione un sector y transmita órdenes a Alfa (primeras dos unidades) o Bravo (restantes): avanzar, reconocer, defender, presionar, escoltar, reserva o retirada. No se controlan movimientos ni disparos individuales.

Tablero procedural 80×25, sprites 16×24 con proporción conservada, cobertura, línea de visión, caminos, restricciones de agua para vehículos, calor, munición e integridad. Los contactos perdidos conservan su última posición, sin revelar la fuerza oculta. La actitud cautelosa permite repliegues según los valores del piloto; habilidad y fatiga afectan la ejecución.

Observar no avanza días administrativos. **Delegar** ejecuta el mismo motor, y **Continuar** termina el encuentro pendiente y procesa el regreso al vencer el plazo del contrato. Daños, liquidación y recuerdos se aplican una sola vez. Guardar conserva órdenes en tránsito y encuentro completo. Las operaciones antiguas ya iniciadas conservan el sistema previo.

[Diseño, alcance y verificación](docs/RELEASES-Battle.md). Es un sistema simplificado propio, no una reproducción de las reglas tácticas completas de BattleTech. Las misiones especiales sin tipo de mapa usan el encuentro de escolta como representación inicial.

## Windows y GitHub

La **v0.44** se obtiene como artefacto ZIP de una ejecución aprobada de [Windows build and smoke test](https://github.com/itomaselli/Battletech-Mercenary-Command/actions/workflows/windows.yml). La [release publicada v0.37.0](https://github.com/itomaselli/Battletech-Mercenary-Command/releases/tag/v0.37.0) es anterior al mapa de operaciones. La versión Windows es un ZIP portátil x64: extraé todo y abrí **MercenaryCommand.exe**, conservando el archivo PCK a su lado. El código está en [Battletech-Mercenary-Command](https://github.com/itomaselli/Battletech-Mercenary-Command). El flujo de GitHub Actions genera y prueba el ejecutable en Windows; sus ejecuciones aprobadas ofrecen el ZIP como artefacto.

[Instalación, traslado de partidas y exportación reproducible](docs/WINDOWS.md). El código del proyecto conserva la licencia GPL-3.0 del repositorio; los datos y componentes de terceros mantienen las atribuciones y licencias indicadas en data/README.md y GODOT-LICENSE.txt.

## Generador de historias — v0.33–v0.37

La compañía incorpora aspiraciones y peticiones personales, memoria causal, prácticas de compañía, vínculos con máquinas, iniciativas elegidas por el capitán y enlaces civiles que recuerdan la ayuda recibida. Se integra en las pantallas actuales, sin ventanas nuevas.

- **Mando → Bandeja:** apoyar, aplazar o rechazar peticiones; comunicaciones locales e invitaciones coordinadas, máximo dos propuestas opcionales.
- **Compañía → Personal/Hangar:** aspiraciones, valores, recuerdos, relaciones y servicio de unidades. Reparto de beneficios al pie de Personal.
- **Capitán → Asuntos:** iniciar desarrollo personal, apoyo comunitario o una red de contactos; elegir recursos, tiempo propio o delegación.
- **Mundo → Región:** enlaces civiles persistentes y reconocimiento local.
- **Mando → Crónica:** inspector de antecedentes con enlaces a personas y unidades.

Los guardados antiguos migran al esquema 25; los recuerdos nuevos empiezan desde su día de carga, sin alterar el pasado. RPG sigue en revisión 25. La simulación funciona sin IA ni conexión. [Reglas, costes, alcance y pruebas](docs/RELEASES-Story.md).

## Arte de unidades — v0.32

Cada uno de los 56 modelos del catálogo tiene su propio sprite: 48 variantes de 24 chasis Mech y ocho vehículos. Siluetas y detalles de armas adaptados de referencias de Sarna, manteniendo 16×24 píxeles, tres colores y escalado nítido. Las variantes de un chasis conservan su familia visual y cambian aperturas, lanzadores o carenados; los colores son artísticos, no uniformes canónicos de facción.

El aspecto se resuelve por ID de modelo: cambia también en carreras antiguas sin alterar estadísticas, personal ni guardados. [Galería completa](docs/unit-art-v032.png), [referencias y criterios](docs/UNIT-ART.md). Las máscaras editables están en `tools/build_unit_art.py`; `visual/unit_sprites.json` es el registro de ejecución y `assets/units/` contiene las 56 exportaciones PNG.

## Nueva interfaz y carreras

Abrí **Mercenary Command** desde el escritorio. Para una partida nueva elegí **Nueva carrera**: escenario e identidad → trasfondo del capitán → fuerza y personal → revisión y vínculo. Podés volver, cancelar y sortear unidades, personas o ambos sin modificar una campaña activa. La semilla y los resultados se conservan.

Se sortean **cuatro unidades totales** del catálogo disponible en 3027 o 3060, incluidos vehículos y variantes. Cada registro elegible tiene la misma probabilidad; se permiten duplicados, sin cuotas ni compensación por tonelaje. Se generan cuatro pilotos/dotaciones compatibles y dos empleados de apoyo, con nombres, perfiles, retratos, habilidades y salarios. Dotación sigue representando un grupo de tripulantes. El capital inicial se mantiene: 240.000 C-bills y 90 suministros. Algunas composiciones son más costosas que otras.

| Destino | Tareas |
|---|---|
| Mando | Bandeja de decisiones e informes, agenda y crónica |
| Compañía | Expedientes de personas, asignaciones, hangar y taller |
| Operaciones | Contratos y negociación, preparación, partes y encargos |
| Mundo | Atlas, entorno local, conflictos y contactos |
| Mercado | Unidades, catálogo/comparación, suministros y contratación |
| Finanzas | Previsión, deudas y movimientos |
| Capitán | Personaje, asuntos, progresión y legado |
| Campaña | Carreras guardadas, identidad y opciones visuales |

**Continuar** avanza hasta siete días, deteniéndose al recibir acontecimientos o decisiones; **+1 día** conserva el control manual. No responde escenas automáticamente. **Volver / Esc** recupera el destino anterior; dentro del asistente retrocede de paso. Las confirmaciones se reservan para acciones comprometidas. Opciones permite texto normal/grande/muy grande y efectos CRT independientes.

**Guardados:** cada carrera tiene un archivo en `user://careers/`. Al crear o cambiar de carrera se guarda primero la activa. Recargar la misma carrera con cambios exige confirmar el descarte. El antiguo `campaign.json` se importa una sola vez a `careers/legacy-import.json`, dejando intacto el original; no se sortea nada al cargar. No hay guardado periódico: pulsá **Guardar** antes de cerrar. Esquema general 25, revisión RPG 25.

Implementación y comprobaciones: [entregas UI/carrera](docs/RELEASES-UI-Career.md), [mapa de funciones](docs/UI-ROUTES.md). Las pruebas históricas de UI usan un fixture explícito del controlador anterior; las pruebas `shell`, `inbox`, `routes`, `career_wizard`, `layout` y `journey` prueban la interfaz actual.

## RPG del capitán — v0.16–v0.25

Las fases V–IX tienen una primera implementación jugable. Es un sistema ligero propio, inspirado en la experiencia de campaña de rol: **no reproduce las reglas de BattleTech Destiny ni depende de MekHQ**. Las pruebas técnicas están documentadas en [RELEASES-RPG.md](docs/RELEASES-RPG.md); el ritmo y la sensación de interpretar al capitán quedan pendientes de tu evaluación jugando.

Abrí **Capitán**, completá origen, especialidad, motivación y vínculo. No reemplaza ni duplica un piloto asalariado. Las partidas anteriores reciben estos sistemas sin recuerdos inventados; conservan sus operaciones.

- **Escena:** “La carga que no figuraba”, vinculada a una recuperación local. Aceptar compromete un contrato; prepararse consume días y fondos. La decisión entre personas, material y ambos cambia el objetivo y las condiciones materiales. Las escenas urgentes pausan el calendario.
- **Personaje:** vínculos, prioridades expresadas, promesas, conversaciones y mejoras por hitos. Una conversación ocupa un día; no da experiencia repetible. Mediador abre garantía, Analista asegura contraste y Organizador permite coordinar apoyo sin tirada.
- **Asuntos:** sabotaje, mediación y protección. Un expediente abierto a la vez, plazo de diez días, fuentes fechadas, entrevistas inciertas y documentos seguros con coste. Podés aplazar, transformar o abandonar. Son familias estructuradas, no conversaciones libres generadas por IA.
- **Agenda:** investigar, pedir audiencia, visitar enlaces y proponer mediaciones. El capitán hace una actividad temporal a la vez; oficiales disponibles pueden actuar en paralelo y quedan reservados. Metas de red de apoyo vinculan una persona con el sistema actual.
- **Contratos:** cinco paquetes negocian anticipo, pago, transporte local, cobertura y salvamento. Un favor y la fiabilidad pueden mejorar acceso a mayor pago. Condiciones congeladas al aceptar; se mantiene un contrato exclusivo. Los precios son reglas propias, no tablas canónicas.
- **Taller:** averías de movilidad/electrónica cuando una operación deja integridad menor a 65; arreglo provisional de siete días o reparación completa con dos repuestos, técnico, tres días y 6.000. Desmontar una unidad deja integridad cero: no tiene devolución automática. El salvamento pasa por derechos → transporte/evaluación → procesamiento. Incluye reserva de unidades, apoyo local contratado y compras rutinarias que respetan una reserva de caja.
- **Región:** conflictos en sistemas visitados. Operaciones, asuntos y ayuda civil afectan tensión y abastecimiento. Avance semanal local y quincenal remoto; no cambia las fronteras históricas del atlas.
- **Oficiales:** encargos rápidos o a medida con objetivo, enlace, presupuesto, plazo, autoridad y umbral de consulta. El presupuesto queda en depósito; el saldo se devuelve. Se reservan realmente personal y medios. La cotización considera competencia y prioridad personal. Representación construye favores y reputación específica.
- **Memoria:** diario, expedientes enlazados, resúmenes e invitaciones opcionales a descansar/reflexionar. Máximo una invitación pendiente; ignorarla no castiga la prosperidad.
- **Legado:** independencia, prestigio, protección de una comunidad o deuda personal elegida. Requisitos visibles, cierre voluntario y retiro reanudable. Mantenimiento, daño e intervalo narrativo se ajustan por separado; no modifican deudas anteriores ni salarios. El daño se fija para cada despliegue al iniciarlo.

**Para probar el nuevo bucle:** crear trasfondo → abrir un asunto → contrastar documentos → avanzar un día → resolver con pruebas → visitar un enlace → usar el favor al negociar → preparar/desplegar → conversar y elegir un arco. Para la aventura inicial, elegí Escena cuando no tengas otro contrato; el juego necesita una oferta de recuperación vigente.

**Compatibilidad RPG:** migraciones sucesivas conservan el estado. Una versión anterior puede rechazar un guardado actualizado; el archivo antiguo se conserva durante la importación. Las pruebas usan archivos propios.

## Aplicación para este Mac

El acceso **Mercenary Command.app** del escritorio apunta a una aplicación autocontenida en `exports/`. Incluye el motor y una copia del juego; funciona sin el proyecto de desarrollo y sin depender de `/tmp`. Abrila con doble clic y usá **Cargar** para continuar tu campaña guardada. No sobrescribe una sesión abierta; cerrá la anterior guardando antes de cambiar de versión.

Para generar otra copia local, con Python y una instalación de Godot disponible:

```sh
python3 tools/build_macos.py /Applications/Godot.app
```

Genera una carpeta `.app` versionada, conservando las anteriores. Es un empaquetado local con el motor incluido, sin notarización para distribución pública; los assets y datos mantienen sus licencias indicadas en `data/README.md`.

## Expansión v0.11–v0.15

- **Campaña → Partidas → Nueva carrera** permite elegir 3027 o 3060. Nombre de compañía y capitán siguen siendo editables.
- Navegación por Resumen, Operaciones, Compañía, Inner Sphere, Mercado, Finanzas y Crónica; búsqueda en crónica por fecha, persona, tipo o texto.
- **Inner Sphere**: atlas de 3.175 sistemas del conjunto de Sarna, búsqueda/alias, zoom, arrastre, sistemas cercanos, filtro de afiliación y vista completa. Selecciona un sistema y pulsa **Cotizar traslado**; revisa y confirma **Partir**.
- Quince entidades del lore en el catálogo conjunto, diez accesibles en 3027 y quince en 3060. Incluye las cinco Great Houses, ComStar, Word of Blake, Rasalhague, Taurus, Canopus, tres Clanes y dos compañías mercenarias. Sus boletines de juego evolucionan semanalmente; la actividad regional afecta seguridad/abastecimiento. Un contacto registrado mejora en 2.000 C-bills las futuras ofertas de ese empleador; no revela sus secretos.
- **Mercado → Catálogo**: 48 variantes de 24 chasis y ocho vehículos. Hay 34 registros disponibles en 3027 y 56 en 3060. Busca, filtra por clase y fija una ficha como referencia para comparar. Se compran los lotes disponibles, renovados cada 14 días, con entrega y coste explícitos. Cada tanda incluye ligero, medio, pesado y vehículo terrestre.
- Los vehículos requieren **Dotación**, disponible en Personal. Representa un grupo agregado de cuatro integrantes para esta simulación; no equivale al número canónico de tripulantes de cada diseño. No puede pilotar un Mech. Tiene salario, experiencia, fatiga y bajas como grupo. Se conserva el límite de cuatro elementos por despliegue y ocho plazas de hangar.
- Siete sprites originales, 16×24 y tres colores por sprite: dos ligeros, dos medios, dos pesados y uno terrestre. Son familias visuales compartidas entre chasis.
- **Operaciones → Misiones locales** ofrece reconocimiento, extracción, defensa, interdicción y recuperación. Cada uno usa su propio progreso y los perfiles de las unidades. En **Mando de operaciones**, elegí la prioridad específica antes del despliegue. Completo desde 75%: pago total; parcial desde 35%: 60%; fallo: 15%. Siempre se descuenta el anticipo. Retirarse devuelve el anticipo y no genera recompensa. Capturar puede recuperar suministros; destruir el convoy no recupera su carga.
- Las misiones procedurales nacen en la ubicación actual y consideran afiliación, necesidades regionales, relaciones, terreno y resultados anteriores. Se guardan sin volver a sortear al cargar. Los contratos antiguos mantienen su resolución original.
- Viajes: ruta conectada por saltos de hasta 30 años luz; **7 días por salto + 4 días locales**, coste **10.000 + 2.500 por salto + 40 por tonelada**. Son tiempos y precios simplificados del juego. Salarios y mantenimiento siguen corriendo. No se parte con contrato, reparaciones o entregas pendientes; durante el tránsito se bloquean compras, reclutamiento y nuevos contratos. Los asuntos urgentes pueden pausar el calendario. Las ofertas locales se actualizan al desembarcar. Sistemas sin servicios documentados no ofrecen compras/reclutamiento/contratos.

**Alcance cartográfico:** el conjunto importado usa afiliaciones de **3025 como referencia para 3027** y de **3059d para 3060**. La pantalla lo indica; no son fronteras exactas de esos años. Las afiliaciones y la disponibilidad tecnológica se fijan por escenario, sin reconstrucción automática de guerras históricas al avanzar el calendario. Hay contexto de la Periferia y sistemas aislados sin ruta de 30 años luz. El mapa local 80×25 sigue siendo ambiental, sin combate táctico por casillas.

La red ficticia de la campaña anterior sigue operando en Galatea; sus oportunidades exigen regresar allí. Los nuevos contactos, boletines y misiones complementan esos sistemas. Precios, perfiles de combate, actividad autónoma y necesidades locales son reglas de este juego, no acontecimientos históricos canónicos ni reglas oficiales de BattleTech.

**Guardados de la expansión:** los esquemas antiguos se migran al esquema actual al importar/cargar, conservando las operaciones y condiciones existentes.

Fuentes y licencias: [data/README.md](data/README.md). Plan, decisiones y comprobaciones: [docs/PLAN-Expansion-3027-3060.md](docs/PLAN-Expansion-3027-3060.md) y [docs/RELEASES-Expansion.md](docs/RELEASES-Expansion.md). Copias independientes de cada entrega en `releases/`.

## Pruebas de la expansión

Desde este directorio, con Python 3 y Godot instalado:

```sh
python3 tools/test_all.py /Applications/Godot.app/Contents/MacOS/Godot
python3 tools/test_ui.py /Applications/Godot.app/Contents/MacOS/Godot
python3 tools/test_snapshots.py /Applications/Godot.app/Contents/MacOS/Godot
python3 tools/test_rpg_snapshots.py /Applications/Godot.app/Contents/MacOS/Godot
godot --headless --path . --script tests/expansion_migrations.gd
```

`test_all.py` y `test_ui.py` comprueban también errores de script aunque Godot termine con código cero; sus informes se guardan en `docs/`. Las pruebas usan archivos propios, nunca `campaign.json`. El ensayo de migraciones reales requiere primero generar los archivos con `test_snapshots.py`; usa las entregas locales v0.11–v0.14; el ensayo RPG usa v0.16–v0.24. Ejecutá después `test_all.py` para validar las migraciones en la versión actual. Los ensayos largos incluyen seis campañas de 180 días, tres semillas en cada escenario, sin inyecciones de fondos.

## Ejecutar

Probado con **Godot 4.4.1**, edición estándar. Abre `Jugar.command` en este Mac, o importa `project.godot` en Godot y pulsa **F5**. El lanzador busca Godot en Aplicaciones, en la copia temporal de pruebas o en PATH; no descarga nada. Para uso permanente instala Godot: la copia de `/tmp` puede desaparecer.

```sh
godot --path .
```

En macOS puede sustituirse `godot` por `/Applications/Godot.app/Contents/MacOS/Godot`. La copia usada durante el desarrollo está en `/tmp/mercenary-godot/Godot.app/Contents/MacOS/Godot`. [Referencia oficial de comandos](https://docs.godotengine.org/en/4.4/tutorials/editor/command_line_tutorial.html).

## Primeros pasos

1. Creá una carrera o cargá una desde **Campaña / Partidas**.
2. Revisá **Mando / Bandeja** y los costes en **Finanzas**.
3. En **Operaciones / Contratos**, seleccioná una oferta, negociá o aceptá sus condiciones.
4. En **Preparación**, elegí hasta cuatro unidades, doctrina, jefe y órdenes. Autorizá el despliegue.
5. Avanzá el calendario; respondé las decisiones desde la bandeja o el parte de operación.
6. Revisá **Compañía / Taller** para reparaciones y abastecimiento; **Mercado / Personal** para contratar.
7. Explorá **Capitán / Asuntos** y **Mundo / Contactos** para actuar fuera de las operaciones.
8. Guardá antes de cerrar.

## Registro histórico de sistemas

Las secciones siguientes documentan entregas previas. Sus nombres de ventanas corresponden a la UI histórica; usá la tabla de destinos de arriba para la versión actual. La fuerza inicial fija descrita en entregas antiguas fue reemplazada por el sorteo de carrera.

## v0.2.1 — Personal y organización

Comienzas con cuatro BattleMechs, cuatro pilotos y dos empleados de apoyo. Los empleados tienen identificadores estables, habilidad, salario y baja temporal. El capitán representa al jugador y no ocupa una plaza de piloto.

- Cuatro candidatos por tanda, renovada cada 30 días: piloto, técnico, logística y dotación terrestre.
- Contratar paga un coste inicial y agrega el salario a la siguiente nómina. Límite: 30 empleados.
- Despedir cuesta un salario mensual; no se permite con deuda salarial o personal desplegado. Una máquina queda sin piloto si se despide al asignado.
- Cada piloto puede tener una sola máquina. Los pilotos incapacitados no pueden recibir una nueva asignación ni desplegar.
- Elegir jefe determina quién firma los informes; la fuerza de combate sigue dependiendo de todo el equipo, su integridad, moral y doctrina.

## v0.2.2 — Taller y abastecimiento

El taller conserva la reparación abstracta: 10 puntos de integridad por día, 1.000 C-bills y 2 suministros por máquina atendida. Por debajo del 40% de integridad no se puede desplegar.

La capacidad simultánea es la suma de habilidades técnicas dividida por 3, redondeada hacia abajo, con máximo de cuatro máquinas. Ada proporciona una plaza inicialmente. El taller sigue una cola; **Dar prioridad** mueve una máquina al principio. Las estimaciones muestran coste, suministros y días hasta terminar, suponiendo personal y recursos disponibles. Sin técnicos, dinero libre o suministros, el trabajo se detiene.

Cada pedido aporta 30 suministros:

| Pedido | Precio base | Entrega base |
|---|---:|---:|
| Normal | 10.000 | 4 días |
| Urgente | 15.000 | 1 día |

Logística reduce el precio un 2% por punto de habilidad total, hasta un 15%; reduce la entrega normal un día por cada 5 puntos, hasta un mínimo de 2 días. Se paga la mitad al confirmar y el resto queda **reservado** hasta la entrega. La contratación, indemnizaciones, reparaciones y nómina solo usan dinero libre. Los suministros ya no aparecen instantáneamente al comprar.

## v0.2.3 — Contratos y relaciones

Hay un contrato aceptado y una operación simultánea como máximo. Las ofertas se renuevan cada 14 días y muestran remuneración total, anticipo, fuerza mínima, duración e inteligencia estimativa. La fiabilidad es una etiqueta del informe; no revela fuerzas enemigas ni modifica por sí sola la tirada.

- Aceptar ingresa el anticipo una sola vez y abre cinco días de preparación. Se puede desplegar hasta el último día inclusive.
- El éxito paga el total menos el anticipo ya recibido.
- El fracaso reconoce un total del 15% del contrato: se descuenta el anticipo y, si corresponde, se devuelve la diferencia.
- Cancelar, retirarse o dejar vencer el plazo devuelve el anticipo completo, sin pago final: reputación -1, confianza del empleador -2 y moral -5. La retirada abstracta devuelve inmediatamente las unidades a disponibilidad, sin una batalla adicional.
- Una devolución sin fondos libres crea deuda contractual. Debe saldarse antes de aceptar otro contrato, para impedir encadenar anticipos sin cumplirlos.
- Éxito: confianza +1. Fracaso: confianza -1. Escala de confianza de -5 a +5.
- Las próximas ofertas ajustan el pago en 3.000 por punto de confianza y el anticipo en 2 puntos porcentuales, con límites del 10% al 40%. Las condiciones ya aceptadas no cambian.

La doctrina cautelosa agrega un día y reduce desgaste y consumo. La agresiva mejora presión sobre el objetivo a costa de mayores daños y suministros. La resolución sigue siendo abstracta y reproducible; no se muestran composición enemiga ni tiradas ocultas.

## v0.2.4 — Finanzas y decisiones

**Finanzas** muestra caja, saldo reservado, dinero libre, próxima nómina, deudas, reparaciones autorizadas e ingresos/gastos por categoría. La proyección a 30 días descuenta una nómina, deudas pendientes, saldos de pedidos y trabajo previsto de taller. Supone plantilla estable y suministros suficientes; no incluye nuevas compras ni contratos futuros. El posible cobro del contrato actual aparece separado y condicionado al éxito. Una proyección negativa es una alerta, no dinero que ya se haya gastado.

La nómina inicial es 37.000 cada 30 días; cambia con la plantilla. Los impagos reducen moral y acumulan deuda. Se puede regularizar deuda salarial o contractual desde Finanzas. Al llegar a moral cero durante la nómina, cierra la campaña.

Dos clases de asuntos urgentes surgen del estado real:

- **Plazo cercano:** a dos días del límite de despliegue, mantener el compromiso o cancelar. Desplegar también resuelve el aviso.
- **Impagos repetidos:** tras dos nóminas impagas, un empleado no desplegado exige pagar toda la deuda o aceptar su salida. La salida reduce moral en 5 y conserva la deuda.

Un asunto urgente detiene el calendario, incluso dentro de un salto de siete días. Puedes gestionar recursos mientras decides. El aviso de plazo no cambia la fecha límite ni se repite para el mismo contrato. Las decisiones quedan en la crónica.

## Guardados y compatibilidad

Formato actual: **17**. El formato 16 incorpora mando operacional sin alterar las operaciones que ya estaban en curso. El formato 14 incorpora oportunidades e informes desde el día de carga, conservando la actividad mundial en curso. El formato 13 activa las actividades autónomas en la fecha de carga sin simular el pasado. El formato 12 incorpora el mundo en la fecha de carga, conservando confianza, contratos y crónica sin inventar relaciones históricas. Los formatos 9–11 migran a expedientes, fatiga y vínculos sin inventar servicio previo. Los formatos 6–8 también migran a hangar, mercado y propiedad sin costes retroactivos. Los formatos 1 y 2 del prototipo original, y 3–5 de las etapas intermedias, migran al cargar. Se mantienen nombres, calendario, fondos, personal, daños, crónica y operaciones en curso. Las operaciones antiguas no reciben un anticipo retroactivo ni un mínimo de fuerza nuevo. Las reparaciones autorizadas se incorporan a la cola. La caja al migrar se toma como apertura del libro financiero: no se inventan movimientos históricos.

**Guardar** escribe el archivo de la carrera activa en `user://careers/` mediante archivo temporal y renombrado. Cargar datos inválidos conserva la campaña actual. La crónica, pedidos, contratos, asuntos y estado aleatorio se guardan juntos. El formato nuevo no está pensado para abrirse con el ejecutable antiguo.

La ubicación está en **Proyecto → Abrir carpeta de datos de usuario**, dentro del editor. En macOS se encuentra bajo `~/Library/Application Support/Godot/app_userdata/`. Los tests utilizan nombres de archivo distintos y no reemplazan `campaign.json`.

## Arquitectura conservada

- `sim/campaign.gd`: mismo núcleo `RefCounted`, ampliado con comandos y migraciones; no depende del árbol de escenas. `advance()` mantiene el paso temporal.
- `sim/world.gd`: catálogo de actores, relaciones del mundo y proyección de información pública, independiente de la interfaz.
- `ui/main.gd` y `ui/main.tscn`: misma terminal, con acceso a gestión y avisos urgentes.
- `ui/management.gd`: diálogo adicional de personal, taller, finanzas, asuntos, hangar y mercado. Presenta datos y emite comandos; no resuelve operaciones.
- `docs/PLAN-v0.2.md`: etapas y criterios de aceptación.

No se reemplazó la arquitectura ni el sistema de combate del prototipo. Se ampliaron las reglas existentes donde la nueva gestión lo requiere: asignaciones, capacidad técnica, pedidos y preparación contractual.

## Pruebas

```sh
godot --headless --path . --script res://tests/run.gd
godot --headless --path . --script res://tests/v02.gd
godot --headless --path . --script res://tests/identity_ui.gd
godot --headless --path . --script res://tests/ui_smoke.gd
godot --headless --path . --script res://tests/v02_ui.gd
```

`run.gd` conserva las comprobaciones anteriores, adaptando explícitamente la aceptación previa al despliegue. `v02.gd` cubre personal, taller, reservas de dinero, anticipos, plazos, relaciones, libro financiero, asuntos, migraciones 1–5 y veinte campañas de seis meses. `v02_ui.gd` acciona controles de contratación, asignación, pedido, aceptación, avance interrumpido, decisión y despliegue. Ejecutado con ventana también genera las vistas previas en `docs/` y `preview.png`.

## Límites deliberados

Hasta ocho máquinas y una operación simultánea con un máximo de cuatro desplegadas, suministros agregados, integridad abstracta, sin combate táctico, armamento individual, viajes, muerte permanente, préstamos, romances o política entre facciones. Los contratos usan plantillas y el equilibrio económico sigue siendo de prototipo. No hay integración con MekHQ ni IA generativa. Las máquinas dañadas se recuperan por remolque.

Proyecto de aficionado para uso personal. BattleTech y los nombres de sus máquinas pertenecen a sus titulares. La presentación utiliza controles originales y una paleta restringida; no copia assets de Caves of Qud.

### Resultado de validación de v0.2.4

**189 comprobaciones aprobadas:** 127 de los nuevos sistemas, 46 de regresión y 16 del flujo de interfaz. También pasaron las pruebas de apertura y personalización. Validado con Godot 4.4.1 en macOS, incluida ejecución con ventana y revisión de capturas. Las campañas automatizadas cubren hasta 180 días por semilla; esto valida consistencia, no sustituye el ajuste de equilibrio mediante juego real.


## v0.3.1–0.3.4 — Hangar y mercado

El acceso **Hangar / mercado** abre la flota. La pestaña **Mercado** muestra los lotes disponibles. Las páginas anteriores de gestión siguen disponibles.

- **Ocho plazas** en total, contando compras en tránsito. Cada máquina tiene un número único que conserva toda su vida. Se pueden desplegar como máximo cuatro por operación.
- **Compra:** pago completo con fondos libres, plaza reservada y entrega en dos o cuatro días según el lote. Las máquinas llegan sin piloto y con la integridad anunciada. La renovación del mercado no afecta compras ya pagadas.
- **Venta:** muestra cotización y pide confirmación. No se permite vender máquinas desplegadas o en reparación. El piloto permanece contratado, en reserva. Es posible vender toda la flota y volver a comprar después.
- **Mercado:** cuatro lotes renovados cada 14 días; catálogo inicial de los cuatro modelos del prototipo. Precios comprimidos para la economía del juego, no precios oficiales de BattleTech. El modelo todavía no introduce diferencias en la resolución de combate.
- **Comparación:** cada lote muestra precio, reparación, suministros, jornadas de taller, coste de propiedad de 30 días y reventa actual. El valor monetario de suministros es proporcional: las compras reales siguen siendo lotes de 30. Los plazos de reparación dependen de la cola y los recursos.

### Costes de propiedad

Cada máquina recibida devenga 10 C-bills de almacenamiento por día. Si está activa, añade mantenimiento: Locust 60, Shadow Hawk 90, Centurion 85 y Vindicator 70 al día. La flota inicial cuesta **345 al día**, o **10.350 en 30 días**. Las unidades en tránsito no devengan hasta su llegada.

El cobro ocurre cada 30 días, después de la nómina, usando fondos libres. Lo impago se convierte en deuda de propiedad y bloquea nuevas compras y despliegues; las operaciones ya iniciadas pueden terminar. Puede pagarse en **Finanzas → Pagar mantenimiento vencido**. Las ventas permiten obtener dinero para regularizarlo. El gasto ya devengado permanece aunque se venda la máquina.

**Almacenar** libera al piloto y elimina el mantenimiento, conservando solo 300 C-bills de almacenamiento por 30 días. No permite reparar ni desplegar. **Reactivar** cuesta 1.000 C-bills y tarda dos días; durante la reactivación ya devenga mantenimiento. No se puede almacenar una máquina desplegada, en taller o en reactivación.

Finanzas muestra gasto diario, devengado, vencido y próxima factura estimada. La proyección de caja descuenta esa factura, incluidas las compras que llegarán antes de su fecha. La estimación supone estados y plantilla sin nuevos cambios. No hay cobros retroactivos al migrar partidas anteriores.

### Pruebas adicionales

```sh
godot --headless --path . --script res://tests/v03.gd
godot --headless --path . --script res://tests/v03_ui.gd
```

El recorrido de interfaz comprueba compra y venta con confirmación y cancelación, entrega, almacenamiento y reactivación. Ejecutado con ventana genera capturas de mercado, hangar y propiedad en `docs/`. Las pruebas usan guardados de prueba separados; no sobrescriben la partida del jugador.

### Validación final de v0.3.4

**323 comprobaciones aprobadas**: 125 de hangar/mercado/propiedad, 127 de v0.2, 46 regresiones iniciales y 25 del recorrido de interfaz anterior y nuevo. También pasó la prueba de personalización. Las veinte campañas de mercado llegaron al día 180 con recursos y libro financiero conciliados. Se revisaron capturas de las pantallas de mercado, hangar y propiedad. El equilibrio sigue sujeto a pruebas de juego reales.


## v0.4 — Personal e historias

**Expedientes** en la barra principal abre las fichas de servicio. Incluyen experiencia, rango, habilidad, salario, operaciones, éxitos, fatiga, permisos, vínculos y recuerdos fechados. También pueden consultarse empleados que dejaron la compañía: se conserva su historial y su relación con compañeros.

### Experiencia y ascensos

Los pilotos reciben 2 puntos por operación cumplida y 1 por retirada al resolver una operación. Cancelar un contrato no concede experiencia. Los técnicos disponibles reciben 1 punto cuando termina una reparación; logística recibe 1 por entrega de suministros atendida. Son puntos por hechos reales, no por esperar días.

El capitán puede autorizar un ascenso desde el expediente: cuesta 3.000 C-bills libres, aumenta habilidad en 1 y salario mensual en 1.000. Requiere 6 puntos para el primero y 12 para el segundo; máximo dos ascensos y habilidad máxima 5. No puede formalizarse durante un despliegue. El aviso de elegibilidad queda en la crónica y no detiene el calendario.

### Fatiga y descanso

- Una operación resuelta añade 18 de fatiga, más 6 por nivel de doctrina (0/1/2) y 8 adicionales si falla.
- Un día de trabajo de taller añade 10 a los técnicos disponibles; una entrega atendida añade 5 a logística.
- En base se recuperan 6 puntos por día. Los desplegados no recuperan fatiga hasta volver.
- Un permiso de tres días recupera 14 por día; el empleado conserva el salario pero no está disponible durante el permiso. Se concede desde el expediente y no puede darse durante un despliegue.
- Con fatiga 80 o superior, una persona no puede trabajar ni desplegar. Lesiones y permisos también impiden participar. Los apoyos indisponibles dejan de aportar capacidad técnica o descuentos logísticos.
- En combate, la contribución de un piloto se multiplica por `1 - fatiga/200`. No altera los daños ya existentes ni la resolución guardada de operaciones anteriores.

### Compañeros e historias causales

Cada pareja que termina una operación acumula servicio compartido. El éxito aumenta el vínculo en 1 y el fracaso lo reduce en 1, con límites de -5 a +5. A partir de +3 se registra confianza consolidada; en -2 o menos, tensión reflejada en los informes. El promedio de los vínculos del equipo dividido por 3 se añade a su fuerza efectiva, con límite de ±2. Es un efecto pequeño, no una garantía de victoria.

Hay dos historias personales nuevas:

| Informe | Opciones del capitán |
|---|---|
| Sanidad solicita atención para un piloto herido | Pagar 2.000: reducir la baja en 3 días, dejando al menos uno, y moral +2; o mantener tratamiento habitual sin coste adicional |
| Dos compañeros discrepan tras fracasos compartidos | Revisión conjunta: vínculo +2 y dos días sin despliegue; o separar asignaciones: segundo piloto a reserva y vínculo +1 |

Se genera como máximo un incidente personal por operación, dando prioridad a heridos. Cada persona tiene 30 días de espera entre solicitudes médicas; cada pareja, 30 días entre conflictos. Los eventos usan informes y resultados conocidos, sin afirmar motivos privados. No usan IA generativa ni consumen tiradas adicionales.

Estos asuntos aparecen en **Asuntos y relaciones** y detienen el calendario hasta decidir. Los implicados no pueden desplegar mientras su asunto siga pendiente. Los demás preparativos siguen disponibles. Las decisiones quedan en la crónica y en los recuerdos de los participantes. La salida de un implicado archiva su expediente y cierra el asunto obsoleto.

### Compatibilidad y validación

Los guardados anteriores conservan nombres, fondos, personal, contratos, compras, daños, calendario y crónica. Los nuevos expedientes empiezan sin experiencia ni fatiga retroactiva; no se reconstruyen vínculos a partir de textos antiguos. Las decisiones pendientes, permisos y recuerdos se guardan y cargan junto al resto de la campaña.

```sh
godot --headless --path . --script res://tests/v04.gd
godot --headless --path . --script res://tests/v04_ui.gd
```

Las pruebas adicionales cubren ascensos, límites, descanso, efectos sobre apoyo, vínculos, atención médica, conflictos, archivo de bajas, migraciones y veinte campañas de hasta 180 días. El recorrido de interfaz comprueba ascenso, permiso, asunto médico, reanudación del calendario y expediente archivado. Las capturas están en `docs/`.

### Validación final de v0.4.4

**434 comprobaciones aprobadas**: 104 de personal/historias, 125 de hangar/mercado, 127 de gestión, 46 regresiones iniciales y 32 del recorrido de interfaz. También pasó la prueba de nombres. Se verificaron historias disparadas por lesiones y fracasos de operaciones, migraciones, guardado de asuntos pendientes, archivo de bajas y veinte campañas de personal de hasta 180 días. Se ejecutó la interfaz con ventana y se revisaron los expedientes, historias y archivos de exempleados.


## v0.5.0 — Fase II: actores y relaciones

**Mundo**, en la barra principal, abre el directorio de cuatro organizaciones contratantes y tres compañías rivales. Cada ficha muestra especialidad e intereses declarados, afiliación, procedencia y fecha de la información. La fuerza y disponibilidad actuales de los rivales no están confirmadas. Son actores ficticios de esta campaña, incluido el enlace local de la Casa Davion.

- La confianza de cada empleador reutiliza las relaciones existentes y sigue afectando las próximas ofertas. Se distingue de la reputación general y de los vínculos conocidos entre organizaciones. Trabajar para alguien no aplica penalizaciones automáticas con terceros.
- **Establecer contacto** cuesta 1.000 C-bills libres, una sola vez por organización y con confirmación. Registra un canal y su fecha en la ficha, la crónica y las finanzas. En esta entrega no mejora confianza ni promete contratos o ventajas.
- Siguen apareciendo tres ofertas cada 14 días. El tercer puesto alterna entre el enlace Davion y el Consorcio de talleres. Los contratos aceptados mantienen sus condiciones.
- Los perfiles, contactos y vínculos persisten al guardar. Las partidas anteriores incorporan el directorio en su fecha actual, sin costes ni acontecimientos retroactivos.

Esta entrega inicia la Fase II. Los rivales todavía no actúan de forma autónoma: esa actividad corresponde a v0.6; las oportunidades causales y la evolución de la información vendrán después. El módulo conserva estado interno separado, pero la interfaz recibe únicamente información pública. Los archivos de guardado locales no están cifrados.

### Pruebas de mundo

```sh
godot --headless --path . --script res://tests/v05.gd
godot --headless --path . --script res://tests/v05_ui.gd
```

El recorrido con ventana genera `docs/world-employer-preview.png` y `docs/world-rival-preview.png`. El plan y sus criterios están en `docs/PLAN-v0.5.md`.

**465 comprobaciones aprobadas**, incluyendo 25 del mundo, 6 de su interfaz y las 434 anteriores. También pasó la personalización de nombres. Se verificaron migración desde formato 12, continuidad de operaciones y aleatoriedad tras guardar/cargar, reserva de fondos, rechazo de contactos duplicados, exclusión de datos internos y conservación de las condiciones contractuales. Se revisaron las capturas de ambas clases de actor con Godot 4.4.1. Las pruebas utilizan archivos separados de la partida del jugador.


## v0.6.0 — Actividad autónoma del mundo

Las organizaciones ya actúan al avanzar el calendario. Los contratantes acumulan necesidades y presupuesto; las compañías rivales eligen encargos según especialidad, antecedentes, capacidad y fondos. Sus trabajos duran siete días y pueden terminar en éxito o fracaso, con gastos, desgaste, recuperación y cambios en las relaciones entre ellas.

Abre **Mundo** y selecciona una organización para leer **Actividad comunicada**, debajo de sus vínculos. Los primeros resultados pueden aparecer tras catorce días; también llegan a la crónica. Cada comunicado incluye fecha y fuente, sin revelar fuerzas, fondos ni agendas internas. No hace falta pagar un contacto para recibir comunicados públicos. El contacto sigue siendo un canal registrado, sin ventajas adicionales en esta entrega.

El mundo se detiene cuando un asunto pendiente detiene el calendario o termina la campaña. Guardar/cargar conserva los encargos rivales en curso. Una partida de v0.5 inicia la actividad desde su fecha de carga. Las mismas condiciones producen la misma evolución: este ciclo no usa azar ni modifica las tiradas militares del jugador.

Las ofertas actuales del jugador y su confianza con los empleadores mantienen sus reglas. La generación de oportunidades a partir de los sucesos del mundo queda para v0.7. Las reglas, presupuestos abstractos y límites están en [el plan de v0.6](docs/PLAN-v0.6.md).

```sh
godot --headless --path . --script res://tests/v06.gd
godot --headless --path . --script res://tests/v06_ui.gd
```


### Validación final de v0.6.0

**1.225 comprobaciones aprobadas**: 465 de las etapas anteriores, 753 del ciclo autónomo (incluidas 730 verificaciones diarias de una simulación de dos años) y 7 del recorrido de su interfaz. También pasó la personalización de nombres. Se ejecutó con Godot 4.4.1 y se revisó la captura del comunicado dentro del perfil rival. Las pruebas usan guardados propios; no reemplazan la partida del jugador.


## v0.7–v0.8 — Cierre de Fase II: oportunidades e información

El mundo genera solicitudes extraordinarias cuando las necesidades de un contratante quedan sin cubrir. Abre **Mundo**, elige un contratante y desplázate hasta **Oportunidades del mundo**. Allí figuran causa declarada, procedencia, fecha, pago y condiciones. Aceptar requiere confirmación y utiliza la preparación y el despliegue habituales. Solo puedes mantener un contrato activo.

Las ofertas duran siete días y pueden retirarse si cambia la necesidad antes de aceptarlas. Cumplirlas reduce esa necesidad; fallar o cancelar la aumenta. Esto influye en futuras solicitudes y decisiones rivales. Cada empleador espera al menos 28 días entre solicitudes. Las condiciones firmadas no cambian y las tres ofertas periódicas anteriores permanecen disponibles.

En **Informes del contacto**, un canal ya establecido permite una consulta por **500 C-bills**, con **dos días de demora**. Se muestra cuándo se observó la situación y cuándo llegó la respuesta. Es una declaración de la organización, sin corroboración ni composición exacta de fuerzas. A partir de siete días, la información aparece como antigua. Se puede pedir otra consulta siete días después de la recepción. Las revisiones quedan en la crónica; los resultados rivales también actualizan los vínculos públicos conocidos.

Las partidas de v0.6 migran al cargar. No se reconstruye historia anterior. Las oportunidades aceptadas y consultas en curso persisten junto a la campaña. La simulación conserva su arquitectura y no consume azar adicional del combate.

Las reglas y límites de alcance están en [Plan de cierre de Fase II](docs/PLAN-Fase-II.md). Los pagos extraordinarios usan la economía contractual abstracta existente; no existe una economía monetaria cerrada ni competencia exclusiva por las mismas ofertas. Las fuentes pueden estar desactualizadas, pero todavía no se genera desinformación deliberada.

```sh
godot --headless --path . --script res://tests/phase2.gd
godot --headless --path . --script res://tests/phase2_ui.gd
```

Para una prueba rápida: en partida nueva avanza 14 días, abre el perfil del Consorcio de talleres y revisa sus oportunidades. Para ver los informes, establece un contacto, solicita una consulta y avanza dos días, resolviendo antes cualquier asunto que detenga el calendario.


### Validación del cierre v0.8.0

**1.455 comprobaciones aprobadas**: 1.225 de las entregas anteriores, 223 de los nuevos sistemas (incluyendo 180 controles diarios) y siete del flujo de interfaz. También pasó la personalización de nombres. Godot 4.4.1 ejecutó el recorrido con ventana y se revisó la captura de oportunidad aceptada e informe recibido. Se probaron migraciones, guardado con consultas y contratos pendientes, consecuencias por éxito/fracaso, confirmaciones y límites contra duplicación. Los guardados de prueba no reemplazan `campaign.json`.


## v0.9.0 — Fase III: operaciones militares

En **Órdenes / contratos**, abre **MANDO DE OPERACIONES** antes de desplegar:

1. Elige avance directo o reconocimiento previo (+1 día y 4 suministros).
2. Decide si el jefe resolverá por delegación o consultará al comandante.
3. Prioriza el objetivo o la preservación de la fuerza y pulsa **Guardar plan**.
4. Cierra el panel, acepta un contrato, selecciona unidades, jefe y doctrina, y autoriza el despliegue.
5. Avanza el calendario. Si el jefe consulta, abre de nuevo **Mando de operaciones** para continuar, maniobrar o retirar.

El reconocimiento produce una evaluación preliminar de los accesos. El contacto introduce fricción y un parte incompleto. Maniobrar consume cuatro suministros y añade un día a cambio de mejorar posición y reducir desgaste. Continuar depende de la experiencia del jefe para mitigar la fricción. Consultar mantiene posición durante el día del parte y detiene los avances posteriores hasta decidir.

Con autoridad delegada y prioridad de preservación, el jefe se retira si la integridad media es inferior al 65% al contacto; de lo contrario intenta maniobrar si dispone de suministros. Retirarse conserva las penalizaciones contractuales y, tras contacto, causa tres puntos de daño de extracción por máquina. La extracción es abstracta.

Las directivas nuevas tardan un día en llegar. Solo cambian autoridad y prioridad; no rehacen preparación ni decisiones ya ejecutadas. El panel muestra partes atribuidos, su antigüedad y el archivo de resultados con daños propios. No revela tiradas ni composición enemiga. Se conservan treinta operaciones en el archivo y se muestran las tres recientes.

Las misiones que ya estaban en curso en una partida anterior terminan con su resolución original. Las siguientes incorporan el mando nuevo. Las consultas y órdenes en tránsito se guardan junto a la campaña.

```sh
godot --headless --path . --script res://tests/phase3.gd
godot --headless --path . --script res://tests/phase3_ui.gd
```

[Plan, reglas y límites de Fase III](docs/PLAN-Fase-III.md). Continúa siendo un simulador de mando con resolución abstracta: un contacto por misión, sin mapa táctico ni control individual de combate.


### Validación final de v0.9.0

**1.757 comprobaciones aprobadas**: 1.455 de versiones anteriores, 295 del mando operacional y siete del recorrido de interfaz. También pasaron las pruebas de apertura y personalización. Se verificaron veinte operaciones con distintas semillas y órdenes, consultas guardadas, directivas en tránsito, retirada autónoma, efectos de la habilidad del jefe, archivos y migración de una operación previa. Godot 4.4.1 ejecutó el recorrido con ventana y se revisaron las capturas de contacto y resultado. No se modificó la partida real del jugador.


## v0.10.0 — Fase IV: centro de mando y arte procedural

La pantalla se divide en **Centro de mando**, **Órdenes y flota** y **Crónica**. Los controles anteriores de aceptación y despliegue están en Órdenes y flota. La gestión, mundo, expedientes y mando operacional conservan sus funciones.

- Tres zonas visuales de **80 × 25 celdas** con tiles originales de **16 × 24 píxeles**; imagen nativa de **1280 × 600**, escalada proporcionalmente.
- Paleta propia fija de **18 colores**, máximo **tres por tile y retrato completo**. Arte construido con máscaras y piezas reutilizables, sin assets copiados.
- Retratos reproducibles del capitán y personal, compartidos entre el centro de mando, los expedientes y el jefe operacional. Se conservan por semilla e ID, independientemente del nombre.
- **Opciones visuales** permite apagar scanlines, viñeta y animación del indicador de enlace. Las preferencias se guardan por separado y no alteran campañas.

Los mapas son representaciones ambientales, sin posiciones enemigas ni efectos sobre el combate. Seleccionar una zona no viaja, despliega ni revela inteligencia. El formato de campaña sigue siendo **17** y la generación visual no consume las tiradas de la simulación.

```sh
godot --headless --path . --script res://tests/phase4.gd
godot --headless --path . --script res://tests/phase4_ui.gd
```

[Plan y restricciones visuales](docs/PLAN-Fase-IV.md). Las hojas de tiles y ejemplos de retratos están en `assets/`; su fuente editable está en `visual/art.gd`. Los efectos de terminal sombrean la imagen final; para inspeccionar la paleta base hay que desactivarlos. La restricción cromática de los sprites no se aplica al antialiasing tipográfico.

Validación: **6.159 comprobaciones gráficas**, incluyendo las 6.000 celdas de los tres mapas, **10 comprobaciones de interfaz** y las **1.757 anteriores**, todas aprobadas. También pasó personalización. Se ejecutó con ventana y se revisaron el centro de mando y los expedientes. Los archivos de prueba no reemplazan la partida ni las preferencias reales.
