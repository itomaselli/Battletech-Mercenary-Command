# Mercenary Command — Hoja de ruta RPG, fases V–IX

Estado: primera implementación técnica de v0.16–v0.25 completada; ver RELEASES-RPG.md y README para alcance jugable y comprobaciones. La evaluación subjetiva con el jugador sigue pendiente.
Base: v0.15, esquema de guardado 22, más la corrección de presentación de fichas de unidades.
Las versiones siguientes son objetivos de alcance, no fechas comprometidas. El usuario autorizó implementar secuencialmente todas las entregas sin esperar pruebas personales entre ellas. Se verificó cada núcleo técnico antes de avanzar; la evaluación jugada del diseño queda abierta.

## 1. Visión y alcance

El jugador interpreta al capitán de una compañía mercenaria de BattleTech. La compañía es su responsabilidad y sus medios de acción. El mundo ofrece personas, conflictos y oportunidades. La gestión establece los costes y las consecuencias materiales de la aventura; las decisiones personales dan sentido a esos costes.

Inspiración acordada: campaña de rol vinculada a gestión, con generación de historias al estilo buscado por el jugador en RimWorld. BattleTech Destiny aporta la intención de experiencia de mesa. Este plan no afirma reproducir sus reglas: inicialmente se diseñará un sistema ligero propio. Una adaptación literal requeriría acordar y verificar sus reglas por separado.

Se conserva el juego independiente en Godot/GDScript. No se añade una dependencia de MekHQ ni se sustituye la simulación existente. Los principios de continuidad, mando y conocimiento limitado siguen vigentes.

Bucle deseado:

Situación del mundo → interpretación e investigación → decisión del capitán → compromiso de recursos → órdenes y ejecución → consecuencias materiales/personales → descanso, conversaciones y nuevas iniciativas.

El capitán actúa mediante reuniones, investigaciones, comunicaciones y presencia puntual en campo. No se introduce en estas fases un RPG de movimiento libre o combate individual por turnos.

## 2. Reglas de diseño compartidas

1. Una elección relevante debe cambiar compromisos, relaciones, información, recursos o posibilidades futuras. No basta con cambiar el texto.
2. Separar intención (lo que el jugador quiere) y enfoque (cómo lo intenta). Las habilidades condicionan la ejecución, no deciden la personalidad del capitán.
3. Ofrecer contexto, costes conocidos y motivos comprensibles. Incertidumbre no equivale a ocultar las reglas o castigar sin señales.
4. Tirar solo ante incertidumbre con consecuencias. Evitar repetir conversaciones para obtener otra tirada. Definir fracaso, resultado parcial y éxito antes de resolver.
5. La simulación determina los hechos; la narración los presenta. Un personaje puede mentir, pero el sistema debe distinguir su declaración de un hecho confirmado.
6. Las consecuencias sociales tienen causas y sujetos concretos. No usar una barra universal de bondad. El desacuerdo puede coexistir con respeto y confianza.
7. Dar iniciativa desde el primer prototipo: investigar, hablar, pedir ayuda o abandonar un asunto. Evitar que todo el rol dependa de ventanas que aparecen solas.
8. Alternar tensión con recuperación y momentos cotidianos. Las crisis no deben borrar las ventajas que el jugador consiguió para mantener una dificultad artificial.
9. Automatizar las decisiones rutinarias cuando exista una política clara; consultar al jugador por excepciones relevantes.
10. Mostrar fuentes y antigüedad de la inteligencia; no exponer motivos privados, enemigos exactos ni consecuencias secretas desde vistas públicas.

## 3. Fase V — El capitán y su círculo (v0.16–v0.17)

Experiencia buscada: «Estoy interpretando a una persona y empiezo a conocer a quienes dependen de mí».

### v0.16 — Primera aventura RPG completa

- Ficha del capitán: origen, especialidad, motivación y un vínculo inicial. Pocas opciones, todas utilizadas al menos una vez en la aventura inicial.
- Competencias iniciales propuestas: mando, trato e investigación. Las especialidades técnicas o militares abren enfoques contextuales; no se añade todavía un árbol amplio de habilidades.
- Vínculo estable del capitán con su nombre y retrato existentes. Renombrar no cambia su identidad ni su historia. No se lo convierte automáticamente en otro piloto asalariado.
- Tres interlocutores a partir del personal existente: Elena Voss, Ada Ferrer y Jules Aran en campañas nuevas. En campañas continuadas se asignan roles a personal apto disponible; no se resucita a despedidos ni se inventa participación pasada.
- Motor mínimo de escenas: participantes, información pública, intención/enfoque, requisitos, costes, comprobación cuando corresponda y efectos persistentes.
- Acciones estructuradas. No se ofrece un cuadro de órdenes libres con promesa de interpretación universal.
- Una aventura escrita y conectada a un contrato existente, con al menos tres desenlaces y una escena posterior de conversación.
- Diario de asuntos: hechos conocidos, declaraciones atribuidas, promesas y siguientes acciones posibles.
- Guardar/cargar antes y después de una elección; resolución aplicada una sola vez.

Aventura de referencia: «La carga que no figuraba» (ficción original de desarrollo, no acontecimiento histórico canónico).

El contrato pide recuperar material. Durante la operación se comunica que hay personas cuya evacuación compite con el transporte disponible. El capitán puede investigar discrepancias antes de salir, negociar recursos, priorizar personas o material, buscar ayuda con coste y demora, o retirarse. La información previa y los recursos comprometidos cambian las opciones factibles. No tiene que existir una solución que rescate todo sin coste.

Secuencia objetivo: reunión inicial → preparación con una acción voluntaria → despliegue existente → descubrimiento y decisión → liquidación/disputa → conversación y posible asunto abierto.

Orden interno de implementación:

1. Modelo de capitán y migración opcional de trasfondo, sin interrumpir operaciones existentes.
2. Escenas y efectos conectados a comandos existentes de campaña; prueba de persistencia.
3. Interfaz de personaje/escena/diario y primera conversación.
4. Aventura completa, consecuencias y prueba de todos los desenlaces.
5. Prueba jugada con el usuario, ajuste de claridad y ritmo, cierre de entrega.

Criterios de cierre:

- Se puede explicar qué intentó hacer el capitán y por qué, antes de conocer el resultado.
- Dos enfoques producen consecuencias distintas y viables; ningún enfoque es siempre superior.
- Al menos una capacidad del personaje y una relación cambian opciones o condiciones.
- Un resultado desfavorable permite seguir jugando y abre una respuesta posible.
- No se duplica pago, premio, información ni efectos al volver a abrir o cargar una escena.
- Las bajas o ausencias de participantes tienen alternativa coherente; no bloquean la campaña.

### v0.17 — Relaciones y progresión personal

- Confianza hacia el capitán, desacuerdos y recuerdos de hechos concretos; reutilizar el historial del personal.
- Objetivos y valores de los tres interlocutores, con conversaciones voluntarias en descanso.
- Promesas cumplidas/incumplidas y deudas personales con seguimiento explícito.
- Progresión del capitán por hitos y decisiones relevantes. Recompensar también aprendizajes tras resultados adversos; impedir experiencia por repetir diálogos triviales.
- Mejoras que abran enfoques y contactos además de modificadores numéricos.
- Recuperación personal y escenas tranquilas entre operaciones. El tiempo y coste se informan antes de confirmar.

Cierre: un vínculo cambia a través de varios acontecimientos; el jugador identifica su causa; no hay una respuesta universal que agrade a todos. Las historias sobreviven a cambios de puesto y salida de empleados.

## 4. Fase VI — Aventuras e iniciativa (v0.18–v0.19)

Experiencia buscada: «Puedo decidir qué asuntos perseguir y qué problemas dejar atrás».

### v0.18 — Aventuras conectadas a la simulación

- Convertir la primera aventura en un patrón reutilizable, conservando sus particularidades escritas.
- Tres familias adicionales: investigación de sabotaje, mediación/negociación y petición de protección.
- Seleccionar participantes, lugares y recursos solo cuando cumplan requisitos de la campaña.
- Pistas con fuente y fecha; distinguir observación, testimonio e interpretación.
- Caminos alternativos para la información necesaria. Una única tirada fallida no debe bloquear toda la aventura.
- Resolver, aplazar, abandonar o transformar un asunto; mostrar los plazos conocidos.

### v0.19 — Agenda del capitán

- Desde el diario, investigar una pista, buscar una audiencia, visitar a un contacto o proponer un encargo.
- Objetivos personales elegidos por el jugador y vinculados a personas/lugares existentes.
- Acciones con coste de tiempo y recursos; acciones paralelas solo cuando personal y medios lo permitan.
- Ayuda de subordinados y contactos para perseguir asuntos sin presencia personal constante.
- Consecuencias de dejar asuntos pendientes, con señales previas y sin exigir completarlo todo.

Cierre de fase: completar una cadena iniciada por voluntad del jugador; resolver otra por un camino alternativo; abandonar un asunto sin bloquear el resto del juego. Lugares y personas conservan sus hechos entre escenas y viajes.

## 5. Fase VII — Gestión con compromisos personales (v0.20–v0.21)

Experiencia buscada: «La compañía que construí determina qué estoy dispuesto y capacitado para hacer».

### v0.20 — Negociación y compromisos

- Negociar anticipo, pago, transporte, salvamento y cobertura de reparaciones dentro de márgenes del empleador.
- Necesidades del empleador, relación, reputación específica y conocimiento del capitán influyen en la negociación.
- Ofertas incompatibles por fecha o exclusividad; comparación de caja y disponibilidad antes de aceptar.
- Proponer servicios a contactos y pedir contraprestaciones por favores concretos.
- Cláusulas vigentes congeladas al aceptar, sin alterar contratos de partidas anteriores.
- Salvamento reconocido como derechos sobre material concreto, no como generación automática de un Mech operativo.

### v0.21 — Taller, material y capacidad

- Pocas categorías de avería y repuestos, con efectos relevantes y explicados.
- Reparación completa, arreglo provisional y canibalización; la capacidad técnica y el tiempo importan.
- Material recuperado requiere transporte, evaluación y trabajo antes de entrar en servicio.
- Reservar unidades, alquilar medios o subcontratar apoyo como alternativas al despliegue máximo.
- Políticas básicas: reserva de caja/suministros y autorización de gasto rutinario.

Cierre de fase: una estrategia prudente y otra orientada al crecimiento son viables en circunstancias apropiadas; reparar, reemplazar y posponer tienen casos de uso. Los objetos recuperados mantienen identidad y procedencia. No introducir inventario cuya única función sea exigir clics.

## 6. Fase VIII — Personas y conflictos que continúan sin vos (v0.22–v0.23)

Experiencia buscada: «Intervengo en un mundo que recuerda mis compromisos y también actúa por su cuenta».

### v0.22 — Conflictos regionales persistentes

- Conflictos locales de varias semanas, con actores, necesidades, recursos comprometidos y cambios observables.
- Las misiones militares, investigaciones y negociaciones pueden modificar el mismo conflicto.
- Rutas amenazadas, proveedores vulnerables y disputas de control ofrecen motivos concretos para viajar o quedarse.
- Simulación detallada cerca del jugador y resumida a distancia; no expandir detalle de miles de sistemas simultáneamente.
- Conservar las fechas cartográficas de referencia y separar acontecimientos de campaña de historia canónica.

### v0.23 — Autonomía de oficiales y vínculos externos

- Delegar encargos con presupuesto, objetivo, plazo, autoridad y umbral de consulta.
- Subordinados actúan según capacidades y rasgos establecidos; los desvíos deben tener causas reconocibles.
- Favores, rivales y contactos persisten entre contratos. Reputaciones específicas afectan acceso, condiciones y cooperación.
- Relaciones interpersonales y reputación ante organizaciones son sistemas relacionados, no una única barra.
- Informes atribuidos; no mostrar decisiones internas o intenciones secretas como conocimiento del comandante.

Cierre de fase: comparar un conflicto con y sin intervención; delegar un encargo y recibir un informe coherente; comprobar que decisiones anteriores cambian quién ayuda y en qué condiciones. La autonomía debe ahorrar trabajo rutinario sin quitar decisiones centrales al jugador.

## 7. Fase IX — Ritmo, memoria y campañas con identidad (v0.24–v0.25)

Experiencia buscada: «Puedo contar una historia de mi capitán y su compañía que surgió de cómo jugué».

### v0.24 — Dirección narrativa y memoria

- Selección de escenas entre hechos y situaciones elegibles, con controles de repetición y concurrencia.
- Alternancia de presión, consecuencias, descanso y oportunidades; no castigar prosperidad con pérdidas arbitrarias.
- Recordatorios que relacionen una situación actual con una decisión pasada sin revelar causas desconocidas.
- Resúmenes por aventura y período de campaña, con personas, compromisos y asuntos abiertos enlazados.
- Escenas cotidianas y de celebración que reconozcan logros, recuperación y vínculos.

### v0.25 — Arcos personales y balance de campaña

- Objetivos de largo plazo configurables: independencia, prestigio profesional, protección de una comunidad o resolución de una deuda personal.
- Cierres de arco, retiro voluntario y opción de continuar una campaña abierta.
- Ajustes de presión económica, peligro y frecuencia narrativa separados para afinar la experiencia.
- Revisar progresión, estrategias dominantes, repetición de contenido y carga administrativa con partidas prolongadas.
- Incapacidad o sucesión del capitán quedan como decisión de diseño específica antes de implementar; no activar muerte permanente del personaje por defecto.

Cierre de fase: tras una campaña prolongada, el jugador puede reconocer cambios personales, relaciones y consecuencias materiales conectadas con sus elecciones. Debe haber períodos de estabilidad aprovechables y más de una forma satisfactoria de concluir un arco.

## 8. Integración y compatibilidad

- Extender mediante módulos de personaje, escenas, aventuras y relaciones; mantener economía, inventario, calendario y operaciones como autoridad de sus hechos.
- El controlador de campaña coordina comandos y efectos. Evitar seguir acumulando toda la lógica narrativa en un único archivo.
- Identificadores estables de capitán, personas, escenas, aventuras, promesas y objetos; vínculos a IDs existentes en lugar de duplicar expedientes o inventario.
- Escenas pausadas no avanzan el calendario salvo acciones que anuncien su duración. Definir qué eventos quedan en cola cuando otra escena está abierta.
- Diferenciar hechos conocidos, declaraciones e información privada en el modelo y en las vistas públicas.
- Resultado de una decisión calculado y aplicado una vez, con registro de causalidad; no volver a sortear al cargar.
- Semilla narrativa independiente; consultar una escena no debe consumir tiradas militares.
- Al cargar una partida antigua, incorporar estado RPG vacío/coherente y ofrecer completar trasfondo en un momento seguro. No inventar recuerdos anteriores ni rehacer operaciones en curso.
- Retratos y sprites mantienen sus restricciones y asociaciones existentes.
- Desarrollo offline y contenido estructurado. IA generativa, si se estudia más adelante, queda fuera de estas entregas y no será autoridad de recursos o resultados.

## 9. Validación y orden de trabajo

Para cada release:

1. Elegir la experiencia y el conflicto de decisiones que se quiere probar.
2. Escribir una situación concreta con alternativas, costes y consecuencias.
3. Implementar el mínimo recorrido completo, desde la acción hasta su efecto visible.
4. Probar determinismo, aplicación única, cancelación, dinero/inventario, ausencias de personajes, calendario, guardado y migración.
5. Recorrer la UI con texto extenso y distintos tamaños; verificar que los informes no filtran información privada.
6. Jugar la situación y registrar qué entendió el jugador, qué quiso hacer, qué opciones faltaron y si reconoció las consecuencias.
7. Ajustar antes de declarar cerrada la entrega y ampliar contenido.

Preguntas de evaluación, no afirmaciones ya demostradas:

- ¿El jugador puede expresar una intención propia?
- ¿Puede prever costes y riesgos conocidos sin conocer secretos?
- ¿Hay más de un enfoque razonable según su personaje y situación?
- ¿Las decisiones cambian oportunidades futuras además de recompensas inmediatas?
- ¿Recuerda a un personaje por lo que ocurrió entre ambos?
- ¿Un fracaso crea una situación jugable sin regalar éxito ni bloquear el avance?
- ¿Está tomando decisiones o repitiendo mantenimiento manual?

Mantener pruebas contrafactuales: misma situación inicial con decisiones diferentes. Buscar elecciones dominantes, recompensas duplicables, repetición de tiradas, cadenas inaccesibles y consecuencias sin explicación observable. Las pruebas automatizadas demuestran propiedades técnicas; la sensación de rol se evalúa jugando.

## 10. Primer hito y límites de expansión

El próximo trabajo implementable es v0.16. Primero debe existir una aventura corta completa, usando la compañía actual, antes de multiplicar orígenes, habilidades, planetas o plantillas.

No se condiciona ese hito a negociar todos los contratos, simular componentes individuales, construir una IA generativa, permitir combate personal, crear nuevos mapas tácticos ni reescribir las fases anteriores.

El resultado esperado de v0.16 es poder decir: «Tomé esa decisión porque así es mi capitán; estas personas reaccionaron de esta manera, y ahora mi compañía tiene que vivir con lo que pasó».
