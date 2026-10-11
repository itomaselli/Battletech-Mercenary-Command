# Generador de historias — v0.33 a v0.37

Plan: [PLAN-Story-Generator.md](PLAN-Story-Generator.md). Entregas incrementales sobre los sistemas existentes; el paquete final incorpora las correcciones de integración de todas ellas.

## v0.33 — Memoria causal

Registro de hechos públicos con identificadores, participantes, unidades y antecedentes explícitos. Despliegues, partes, resultados, permisos, ascensos, asignaciones y taller enlazan expedientes; las decisiones de las siguientes entregas también. Crónica ofrece un inspector y permite seguir antecedentes antiguos. No se deduce causalidad por mera proximidad temporal. No copia estado privado de fuerzas ni rivales.

Guardado general 25, RPG mantiene revisión 25; memoria tiene revisión propia 5 al terminar v0.37. Migración desde v0.32 y anteriores: añade sistemas desde el día de carga, conserva crónica anterior sin inventar conexiones, servicio previo ni recuerdos. Aspiraciones inicializadas determinísticamente en ese momento. Cada entrega tiene un snapshot de código; no modifica archivos bajo sources/.

## v0.34 — Personas con iniciativa

Toda la plantilla recibe una aspiración de descanso, formación, seguridad familiar o reconocimiento, un valor y un límite declarado. La formación requiere dos sesiones de 2 días / 3.000 y da +1 experiencia por sesión. La ayuda familiar cuesta 4.000 una vez. El ascenso conserva sus requisitos y costes existentes. El descanso reserva tres días con salario normal. Aspiraciones cumplidas quedan registradas, no vuelven a sortearse automáticamente.

Peticiones opcionales en Mando: apoyar, aplazar siete días o rechazar (confianza −1). Caducan a los 21 días sin castigo automático. Una petición personal abierta como máximo. Personal desplegado u ocupado no puede consumir apoyo simultáneo. Recuerdos, confianza y respeto reutilizan el RPG existente y persisten tras una baja. La selección usa azar aislado; no consume las tiradas militares.

## v0.35 — Identidad y pertenencia

Cuidado, reparto, cumplimiento y exposición al riesgo se registran como prácticas, no como moralidad universal. Permisos cuentan una vez por persona y período de 28 días; cada operación se identifica de forma estable. Personal que valora cuidado reconoce preservar la fuerza y objeta resultados graves con doctrina agresiva.

Repartir beneficios cuesta 1.000 por empleado y aumenta confianza; una vez cada 28 días, sin deuda salarial pendiente. Dos repartos generan expectativa de revisión tras 56 días. Es un aviso, no dinero adeudado ni penalidad automática. Cada unidad conserva historial por ID, operadores y operaciones. Tras dos servicios con ella, venderla afecta en −1 la confianza del operador; la confirmación anticipa ese coste y el historial permanece en Crónica.

## v0.36 — Iniciativas propias

Capitán → Asuntos permite elegir una iniciativa sin esperar una oferta. Una abierta a la vez, sin plazo impuesto. Tres avances para completar:

- Desarrollar a una persona: sesiones de dos días, +1 experiencia por sesión. Cuestan 3.000 con el capitán u oficial elegido, reservando a ambos participantes; contratar un formador externo cuesta 5.000 y solo reserva al alumno. La mentoría delegada aumenta el vínculo entre ambos en +1; no cuenta como operación compartida. También satisface la aspiración de formación si corresponde.
- Sostener una comunidad: entregas de 10 suministros cada siete días, negociación personal/delegada (2.000, dos días), o contratos locales de defensa/extracción/reconocimiento. Al completar mejora presión, abastecimiento y disputa local.
- Construir red de apoyo: financiar enlaces (5.000, un día, avance seguro) o negociar/delegar (2.000, dos días, competencia + 2d6: 9 éxito, 7–8 parcial). Al completar aporta un favor utilizable en negociación y +1 relación con el contacto elegido.

La vía elegida ocupa tiempo y recursos reales. El capitán ocupado no puede desplegar; un oficial reservado no puede pilotar o aceptar otro encargo. Formación e iniciativas en curso impiden viajar. Heridas o bajas pueden hacer fallar el trabajo sin devolución, dejando otras vías abiertas. Abandonar cancela los trabajos sin reembolso; respeta el descanso ya concedido. Un mismo objetivo no se puede repetir hasta 28 días después del cierre.

## v0.37 — Entorno y ritmo

Cada sistema visitado con servicios puede presentar un enlace civil ficticio persistente. Recuerda operaciones locales y apoyo a la comunidad, con reconocimiento y ayudas disponibles. Completar el objetivo comunitario aporta una ayuda; posteriormente puede ofrecer diez suministros como reciprocidad. Las solicitudes de suministro dependen de presión/abastecimiento existentes y tienen efectos materiales reales. No se añade una simulación detallada de todos los sistemas: el mundo lejano conserva su modelo agregado.

El director coordina peticiones, comunicaciones e invitaciones: como máximo dos opcionales simultáneas y siete días entre nuevas propuestas; frecuencia existente de invitaciones sigue aplicándose. Operaciones, decisiones urgentes, tránsito, deuda salarial o trabajos del capitán aplazan nuevas propuestas. No se fuerza una crisis por prosperidad. Rechazar o dejar vencer una comunicación local no penaliza. Continúan los acontecimientos y decisiones urgentes anteriores, fuera de este cupo opcional.

## Cómo probar

1. Cargar una carrera o crear otra y establecer trasfondo.
2. Revisar Compañía → Personal para ver aspiraciones y valores.
3. Avanzar hasta una petición en Mando; responder y observar coste, disponibilidad y recuerdo.
4. Elegir una iniciativa en Capitán → Asuntos; comparar trabajo del capitán y delegación.
5. Revisar Mundo → Región y la reciprocidad tras completar apoyo comunitario.
6. Seguir los antecedentes en Mando → Crónica y comparar expedientes tras operaciones o ventas.

## Alcance de esta entrega

Reglas y textos estructurados, sin IA generativa ni conversaciones libres. Cuatro familias de aspiración y tres de iniciativa; todavía no hay búsqueda libre de personas desaparecidas, cautiverio, deserciones, sucesión ni simulación de motivaciones ocultas por personaje. Los límites declarados orientan la caracterización; no constituyen un nuevo sistema universal de desobediencia. Los vínculos y consecuencias son reales, pero el grado de apego y la calidad del ritmo deben evaluarse jugando.

## Verificación

Pruebas dedicadas: story_memory, story_people, story_culture, story_objectives, story_society, story_edges, story_campaigns y story_ui. Cubren migración, costes, reservas, caducidad, mentoría, alternativas al fracaso, ventas, corrupción de enlaces, 8 campañas de 90 días con 48 recargas y una comparación de decisiones distintas con la misma semilla. Pruebas de sociedad añaden otro recorrido de 90 días. Recorrido visual a 1100×740 y 1360×960, sin desplazamiento horizontal ni cambios de estado al navegar. Resultados completos en test-results.json y ui-test-results.json.

### Cierre — 11 de octubre de 2026

43 suites de simulación y 25 de interfaz aprobadas. El recorrido de historias también aprobó dentro del ejecutable autocontenido. Se cotejaron 131 archivos del paquete con sus fuentes, más project.godot. Capturas finales de Personal y Asuntos inspeccionadas con ventana nativa. Acceso del escritorio actualizado a v0.37.0; v0.32.0 permanece intacta. Ninguna prueba carga ni sobrescribe la carrera del jugador.
