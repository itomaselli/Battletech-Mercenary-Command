# Próxima etapa — Inner Sphere, fuerzas y contratos

Estado: propuesta de implementación, no cambios de jugabilidad implementados.
Decisión del usuario: elegir entre escenarios iniciales de 3027 y 3060.
Base inspeccionada: v0.10.0, formato de campaña 17.

## Diagnóstico

La UI ya separa centro de mando, órdenes/flota y crónica, pero gestión aparece repartida entre botones superiores y ocho pestañas desplazables. Los asuntos urgentes y las decisiones operacionales tienen accesos distintos. Los mapas actuales son tres ilustraciones procedurales, no sistemas estelares con coordenadas.

El calendario tiene el inicio 3027-05-17 fijado en código. El catálogo contiene cuatro variantes, identificadas por posición de lista. El modelo cambia compra y mantenimiento, pero la fuerza abstracta depende principalmente de piloto, integridad, doctrina, vínculos y órdenes. Los empleados asignados a máquinas son pilotos; no existe una dotación vehicular. Las ofertas periódicas usan tres plantillas, complementadas por solicitudes de refuerzo causales.

## Principios

- Dos escenarios iniciales con fecha explícita: 3027 y 3060. Mantener las partidas antiguas en su fecha, con el mismo inventario, dinero e historia.
- Fecha exacta propuesta para nuevas partidas: 17 de mayo de cada año, preservando la convención actual; validar las fronteras a esa fecha, sin adelantar hechos posteriores del mismo año.
- Datos canónicos iniciales separados de lo que ocurre en la campaña. Los resultados posteriores son historia de la partida, no acontecimientos oficiales inventados.
- Fuentes y fecha de vigencia por registro. Una fecha de introducción no garantiza disponibilidad comercial: contemplar producción, rareza, región, facción y extinciones/reintroducciones.
- Refactor acotado: conservar calendario, economía, guardados, órdenes e informes existentes mediante migraciones explícitas. Extraer catálogos y evaluadores; no reescribir todo el motor.
- Mantener la estética original: tiles de 16×24, tres colores por sprite de la paleta fija de 18. La cuadrícula local 80×25 se conserva; no se usa para deformar coordenadas estelares.

## 1. Navegación

Navegación principal propuesta, en este orden:

1. Resumen: compañía, caja, situación, acción recomendada y decisiones urgentes.
2. Operaciones: contratos, preparación, despliegue, partes y archivo.
3. Compañía: personal/expedientes, hangar, taller y suministros.
4. Inner Sphere: mapa, sistemas, actores y relaciones.
5. Mercado: unidades, variantes, filtros, comparador y pedidos.
6. Finanzas: nómina, mantenimiento, reservas, deudas y previsiones.
7. Crónica: lectura con filtros por fecha, personaje y tipo.

Guardar/cargar, opciones y nueva partida en un menú de campaña. Calendario y alertas siempre visibles. Una bandeja de decisiones reúne los asuntos de personal y las consultas del jefe sin fusionar sus reglas. Conservar selección, posición de lectura y contexto al regresar. Usar filtros y fichas de detalle en vez de volcar todo en un listado. Ninguna acción importante debe depender de una pestaña horizontal oculta.

Verificar mediante recorridos: contratar/asignar, comprar/comparar, reparar/abastecer, aceptar/preparar/desplegar, responder un parte y localizar un planeta. Revisar ventanas 1100×740 y tamaño predeterminado; evitar texto cortado y controles fuera de alcance.

## 2. Escenarios y mapa completo

Separar tres escalas:
- Mapa estratégico canónico de sistemas y territorios.
- Ficha del sistema seleccionado, con servicios y oportunidades conocidas.
- Zona local procedural 80×25, conservando su papel ambiental hasta que exista movimiento táctico.

El atlas debe abarcar toda la Inner Sphere documentada por el conjunto de datos auditado, no solo capitales y planetas de misión. Mostrar contexto de la Periferia inmediata; no implica añadir también todos los mundos de origen de los Clanes o la Deep Periphery como destinos jugables.

Funciones: zoom, arrastre, búsqueda por nombre y alias, filtros por afiliación, capitales y contratos, ubicación de la compañía, selección con ficha y leyenda. La etiqueta de capital o territorio no revela guarniciones ni operaciones secretas.

Datos: ID estable de sistema, nombre/alias, coordenadas y convención, afiliación histórica por fecha, fuente y nivel de certeza. Las fronteras gráficas son una representación política; no calcularlas como hechos exactos a partir de unas pocas capitales. Los servicios económicos sin fuente histórica se identifican internamente como parámetros de juego.

Primera tarea de atlas: localizar y auditar coordenadas y afiliaciones reutilizables, contrastadas con Sarna y las fuentes que cita. Producir inventario de cobertura, duplicados, alias, huecos y casos disputados. No prometer un número de planetas antes de esa auditoría. No marcar el mapa completo hasta conciliar los registros del conjunto adoptado; los huecos se documentan, no se rellenan con planetas inventados. Un mapa cercano en fecha no sustituye silenciosamente uno de 3027 o 3060.

Los viajes se conectan después de validar el atlas: transporte contratado, itinerario, duración estimada, coste y confirmación antes de partir. Emplear reglas de distancia/saltos y tránsito contrastadas; no asumir viaje instantáneo entre estrellas cercanas. Durante el traslado corren salarios, mantenimiento y calendario. Las ofertas consideran ubicación y tiempo de llegada; el jugador no pierde un contrato por un plazo inicial imposible.

## 3. Quince actores del lore

Roster propuesto para integración como actores de campaña:

1. Casa Davion / dominio correspondiente a la fecha.
2. Casa Steiner / dominio correspondiente a la fecha.
3. Casa Kurita / Draconis Combine.
4. Casa Marik / Free Worlds League.
5. Casa Liao / Capellan Confederation.
6. ComStar.
7. Word of Blake.
8. Free Rasalhague Republic.
9. Taurian Concordat.
10. Magistracy of Canopus.
11. Clan Wolf.
12. Clan Jade Falcon.
13. Clan Ghost Bear.
14. Wolf's Dragoons.
15. Kell Hounds.

Esta es la lista del catálogo conjunto, no quince actores públicos y disponibles en ambos años. Las entidades no existentes o no conocidas por un comandante local en 3027 no aparecen como contactos accesibles. Las Great Houses son familias gobernantes: distinguirlas de sus estados y cambios de denominación. No representar a los Clanes simplemente como empleadores mercenarios equivalentes a una oficina local. Priorizar su función regional, militar y diplomática según el escenario.

Cada actor tiene tipo, sede/ámbito, relaciones iniciales, política de contratación, mercado y tecnología, fuentes y fecha de disponibilidad. Diferenciar un Estado, una organización religiosa/comercial y una compañía mercenaria. Las relaciones históricas entre actores no se confunden con la confianza hacia el jugador.

El atlas puede mostrar otras afiliaciones territoriales como metadatos aun cuando no tengan simulación autónoma entre estos quince. No borrar actores geográficos para encajar el mapa en quince entradas. Mantener las organizaciones ficticias existentes en partidas antiguas y vincularlas como actores locales; no renombrar retroactivamente su historia. Revisar la distinción de Clan Wolf y Wolf-in-Exile donde corresponda al mapa de 3060.

## 4. BattleMechs, variantes y vehículos

Objetivo inicial propuesto: 24 chasis de Mech, unas 48 variantes verificadas, y ocho familias de vehículos terrestres con variantes documentadas cuando corresponda. No representa todos los diseños publicados hasta 3060; es una ampliación jugable y extensible.

Candidatos para curación:
- Ligeros: Locust, Wasp, Stinger, Commando, Spider, Panther, Jenner, Firestarter.
- Medios: Shadow Hawk, Vindicator, Centurion, Hunchback, Griffin, Wolverine, Phoenix Hawk, Trebuchet.
- Pesados: Thunderbolt, Catapult, Dragon, Quickdraw, Rifleman, JagerMech, Warhammer, Marauder.
- Vehículos: Scorpion, Vedette, Striker, Bulldog, Manticore, Demolisher, SRM Carrier, LRM Carrier.

La lista es de candidatos, no una afirmación de que todas sus variantes son válidas. Auditar año y disponibilidad de cada variante por separado. Los cuatro modelos actuales conservan sus IDs de migración. Las variantes posteriores a 3060 se excluyen y las introducidas después de 3027 no se ofrecen en ese escenario. Tener Clanes como actores no vuelve comunes sus equipos en el mercado mercenario; un paquete de unidades Clan requerirá su catálogo y economía específicos.

Ficha canónica: ID de chasis y variante, nombre, tonelaje, clase, movilidad, tecnología, armamento/resumen, año y disponibilidad, fuente. Ficha de juego separada: movilidad abstracta, protección, potencia por distancia, reconocimiento, apoyo, consumo, mantenimiento, dotación y familia de sprite.

La resolución debe usar esos perfiles: reconocimiento y extracción favorecen movilidad; defensa valora protección y apoyo; interdición valora capacidad de corte y movilidad. Evitar que la habilidad del piloto haga idénticas todas las máquinas o que cuatro pesados sean óptimos en todo. Conservar resolución abstracta y no introducir todavía simulación de cada componente de armamento.

Vehículos: dotación agregada explícita de conductor/tiradores/jefe según el modelo, coste salarial, experiencia, fatiga y bajas de dotación. No asignar un MechWarrior como si el tanque fuera otro Mech. Empezar con vehículos de orugas para acotar movilidad; otros modos pueden incorporarse después. Compartir integridad, taller e inventario donde proceda, con reglas propias de mantenimiento, transporte y disponibilidad.

Mantener inicialmente cuatro elementos por despliegue, con capacidad de transporte y costes diferenciados; no ampliar tamaño de fuerza, almacenamiento y economía al mismo tiempo sin pruebas. Precios de referencia y precios ajustados al prototipo son campos distintos y visibles como tales.

## 5. Siete sprites solicitados

- Dos ligeros: silueta esbelta y silueta compacta.
- Dos medios: humanoide multipropósito y torso de apoyo ancho.
- Dos pesados: bípedo robusto y silueta con armamento en brazos.
- Un vehículo terrestre: chasis de orugas con torreta.

Cada sprite usa una celda 16×24 y hasta tres colores. Asociar cada chasis a una familia estable; no sortear otra silueta en cada carga. El modelo y variante siguen identificados en la ficha: siete familias visuales no significan siete dibujos únicos para decenas de chasis. Variación de color/insignia sin añadir un cuarto color. Verificar lectura en hangar, mercado y partes. No copiar ilustraciones de Sarna. Los assault Mechs quedan para un paquete posterior con sus propios sprites, pues el pedido actual especifica ligero/medio/pesado.

## 6. Cinco tipos nuevos de misión

1. Reconocimiento de zona: obtener inteligencia suficiente y regresar; el éxito no exige destruir al enemigo. Favorece movilidad/sensores; puede producir información parcial.
2. Rescate y extracción: alcanzar y evacuar personas/carga antes de una ventana; pérdidas parciales y compensación por objetivos recuperados.
3. Defensa de instalación: sostener integridad del objetivo durante un plazo; valorar protección/apoyo y daño a infraestructura, no solo supervivencia propia.
4. Interdicción de convoy: localizar e interceptar una fracción del transporte enemigo antes de que escape; elegir entre captura y destrucción, con efectos distintos.
5. Recuperación de material: asegurar, recuperar y transportar un objetivo; elegir dedicar tiempo al salvamento o evacuar bajo presión. No regalar un Mech operativo automáticamente.

Son cinco evaluadores de objetivo, no cinco títulos para la misma tirada. Cada uno necesita estado de progreso, oportunidades de decisión, condiciones de éxito parcial/completo, retirada y consecuencias económicas/mundiales. La nueva defensa distingue integridad del objetivo de los contratos anteriores de protección, que conservan su comportamiento al migrar.

## 7. Generador procedural de contratos

Separar tipo de misión, instancia de contrato y sucesos durante su ejecución. Combinar de forma condicionada: necesidad causal del mundo, empleador válido, sistema accesible, objetivo, plazo, perfil de amenaza, entorno, fuerzas apropiadas, cláusulas, recompensa y una complicación. La composición enemiga y las complicaciones ocultas permanecen fuera del contrato público.

Origen preferente: necesidades, fracasos rivales, logística afectada y relaciones. Las ofertas ambientales de respaldo mantienen oportunidades cuando el mundo no genera suficientes eventos. Elegir aleatoriamente dentro de combinaciones válidas, con semilla persistente y reglas contra repetición. No crear otra misión al cargar ni cambiar pagos de un contrato aceptado.

Ejemplo: un fracaso rival deja sin cobertura un depósito; el propietario pide recuperar repuestos de un transporte varado; el sistema y entorno limitan extracción; la compañía decide entre protección, capacidad de carga y velocidad. El resultado modifica el abastecimiento local y la relación con el contratante.

Validación de coherencia: fechas y variantes, facciones presentes, objetivo compatible con lugar/vehículos, plazo alcanzable, costes explicados, probabilidades y recompensas razonables, ausencia de ganancias repetibles sin coste. Cubrir con pruebas los cinco evaluadores, éxitos parciales, fracasos, rescates y cancelaciones.

## 8. Entregas y aceptación

| Entrega | Alcance | Condición de cierre |
|---|---|---|
| v0.11 | Auditoría UI, navegación, escenarios e IDs estables | Dos fechas seleccionables; partidas viejas intactas; recorridos de gestión completos |
| v0.12 | Datos cartográficos, atlas completo y 15 actores | Cobertura auditada; afiliaciones por escenario; búsqueda/zoom; conocimiento público separado |
| v0.13 | Catálogo, dotaciones, perfiles y siete sprites | Variantes fechadas; Mechs/vehículos funcionalmente distintos; compra, despliegue, reparación y guardado |
| v0.14 | Cinco misiones y generador causal | Objetivos distintos; generación coherente y reproducible; integración con órdenes y consecuencias |
| v0.15 | Viajes, integración regional y balance | Campañas en ambos escenarios; misiones accesibles; economía consistente; migraciones y revisión visual |

La auditoría de fuentes empieza en v0.11 para identificar huecos antes de construir el atlas. No asignar un plazo de trabajo al mapa completo hasta conocer cobertura y calidad de sus datos.

Pruebas finales: campañas de seis meses en ambos escenarios, carga/guardado antes y durante traslados/operaciones, archivos anteriores, dotaciones, fecha de cada oferta y variante, cambios de ubicación, diversidad de contratos sin combinaciones imposibles, máximo tres colores por sprite y revisión de recorridos reales de UI.

## Referencias iniciales consultadas

- https://www.sarna.net/wiki/Great_Houses — distinción entre casas, estados y cambios políticos.
- https://www.sarna.net/wiki/InnerSphere — alcance geográfico y colección de mapas; pendiente auditoría del conjunto de coordenadas.
- https://www.sarna.net/wiki/Lyran_Alliance — cambio político de 3057.
- https://www.sarna.net/wiki/The_Word_of_Blake — organización posterior a 3027.
- https://www.sarna.net/wiki/Free_Rasalhague_Republic — cronología para disponibilidad por escenario.
- https://www.sarna.net/wiki/Locust — variantes con fechas y disponibilidad diferentes.
- https://www.sarna.net/wiki/Warhammer — referencia inicial para chasis pesado y variantes.
- https://www.sarna.net/wiki/Vedette — referencia inicial para vehículo terrestre.
- https://www.sarna.net/wiki/Kell_Hounds y https://www.sarna.net/wiki/Wolfs_dragoons — compañías mercenarias canónicas.
- https://www.sarna.net/wiki/Technical_Readout_3058_Upgrade — advertencia de alcance: la edición Upgrade incluye material posterior al año del título; filtrar variantes individualmente.

La consulta inicial no sustituye la verificación de cada registro durante la importación. El nombre de un Technical Readout no basta para garantizar que todo su contenido cumple el corte de 3060.

## Cierre de implementación

Completadas v0.11–v0.15 en orden. Detalle de cada cierre y pruebas: `RELEASES-Expansion.md`. Se preservó la simulación existente mediante módulos de catálogo, atlas, lore, objetivos y viaje; los contratos antiguos no se convirtieron retroactivamente en misiones nuevas.

Decisiones tras auditoría: atlas completo respecto a sus 3.175 registros con fechas políticas de referencia explícitas; Striker de ruedas incluido con su modo correcto; dotaciones agregadas como regla de juego; siete familias de sprites compartidas. La afiliación política se congela por escenario. No se presentan fronteras interpoladas ni inventadas como canónicas. Los filtros implementados son búsqueda/alias y afiliación en atlas, y texto/clase/escenario en catálogo; los filtros adicionales de capitales/contratos quedan fuera de esta entrega y no afectan la cobertura del atlas.
