# Entregas RPG — fases V–IX

Cada cierre documenta implementación y validación técnica. La valoración subjetiva del jugador (identificación con el capitán, interés y ritmo) queda pendiente de su prueba; no se presenta como demostrada por tests.

## v0.16 — Implementada y verificada

Capitán con tres orígenes, tres competencias, cuatro motivaciones y vínculo estable; tres roles de interlocución obtenidos del personal existente. Escenas con calendario pausado, comprobaciones propias de 2d6, preparación con tiempo/coste y diario atribuido. La carga que no figuraba acepta un contrato de recuperación real, permite preparar transporte/investigar/coordinar, presenta un descubrimiento en operación y modifica objetivo/pago según la orden. Retirada y conversación posterior incluidas. Migración desde esquema 22 sin reconstruir historias pasadas.

Verificación: cuatro ramas (personas, material, ambos y retirada), continuidad exacta tras guardar/cargar en escena, bloqueo de calendario, coste de preparación, rechazo de repetición y persistencia del cierre. Regresión básica: 46 comprobaciones. Recorrido UI con ventana y captura inspeccionada.

## v0.17 — Implementada y verificada

Añadir vínculos causales, promesas, conversaciones voluntarias con descanso, experiencia por hitos y mejoras de enfoque. Conservar IDs y recuerdos de empleados ausentes; impedir experiencia por diálogo repetido.

Verificación: conversaciones con coste temporal, promesas, hitos únicos, aprendizaje no repetible, memoria tras bajas y guardado exacto. Las cuatro ramas de v0.16 siguen pasando.

## Plan de v0.18

Motor reutilizable de asuntos con tres familias, fuentes fechadas, enfoques alternativos, plazos y cierre o abandono.

## v0.18 — Implementada y verificada

Tres familias reutilizan expedientes con lugar, interlocutor existente, plazo y fuentes fechadas. Entrevistas inciertas, documentos seguros con coste, garantía del mediador, resolución material, aplazamiento, transformación y abandono. Prueba: tres familias resueltas con registros, efectos únicos y persistencia exacta.

## Plan de v0.19

Agenda voluntaria: pistas, audiencias, visitas y propuestas; metas sobre persona/lugar existente, apoyo de un oficial con reserva temporal y plazos visibles.

## v0.19 — Implementada y verificada

Agenda personal y encargos de dos días a oficiales, con reserva real de disponibilidad. Visitas crean favores; audiencias modifican relación organizativa; investigar aporta una fuente; proponer abre mediación. Metas vinculan una persona y sistema existentes con un plazo. Prueba: dos acciones paralelas con actores distintos, guardado en curso, cierre de meta, propuesta y rechazo de repetición.

## Plan de v0.20

Paquetes negociables sobre ofertas existentes, cláusulas congeladas, comparación de anticipo/neto/disponibilidad, favores y derechos de salvamento. Liquidación conectada al resultado militar.

## v0.20 — Implementada y verificada

Cinco paquetes de negociación distribuyen pago, anticipo y riesgo; mayor pago exige capacidad/relación o un favor. Condiciones congeladas y aceptación exclusiva sobre ofertas existentes, con previsión de caja/plazo. Cobertura solo sobre daño posterior al despliegue; salvamento entrega derechos identificados. Prueba de cinco paquetes, aceptación repetida, contrato en curso guardado, reembolso y salvamento únicos.

## Plan de v0.21

Averías funcionales con repuestos de movilidad/electrónica, taller reservado, arreglo temporal, canibalización, procesamiento de salvamento y políticas explícitas de reserva/gasto.

## v0.21 — Implementada y verificada

Dos categorías de avería funcional tras daño, arreglo de siete días, reparación completa con repuestos y técnico reservado, canibalización con pérdida explícita de integridad. Lotes con procedencia pasan por transporte/evaluación y procesamiento. Reserva de unidades, apoyo local contratado y compra rutinaria de suministros con caja mínima. Prueba: disponibilidad, costes, taller guardado, desmontaje no repetible y ciclo completo del lote.

## Plan de v0.22

Conflictos persistentes en sistemas visitados, presión y abastecimiento conectados al generador existente; fuentes públicas, intervenciones civiles y militares y avance resumido a distancia.

## v0.22 — Implementada y verificada

Disputas de tránsito con actores conocidos, recursos, presión, informes fechados y estado persistente por sistema visitado. Misiones, asuntos e iniciativas regionales afectan el mismo registro y el abastecimiento que alimenta futuras ofertas. Avance semanal local y quincenal remoto. Prueba contrafactual con/sin suministros, límites a repetición, cierre y guardado exacto.

## Plan de v0.23

Delegación con presupuesto en depósito, plazo, objetivo, autoridad y umbral de consulta; reservas de personal/unidad, informes atribuidos y reputación específica externa separada de confianza personal.

## v0.23 — Implementada y verificada

Encargos con depósito y devolución, objetivo, fecha límite y umbral de consulta. Capacidad profesional y prioridad personal influyen en coste; reserva de oficial/unidad y consulta antes de exceder autorización. Fiabilidad y discreción externas separadas de relaciones personales; fiabilidad mejora acceso a negociación. Prueba: fondos reservados, pausa en consulta, guardado, aprobación, devolución única y reputación.

## Plan de v0.24

Director de oportunidades y descanso con concurrencia/cooldowns, memoria de hechos conocidos y resumen quincenal. Organizar la pantalla del capitán por secciones para evitar una lista excesiva.

## v0.24 — Implementada y verificada

Invitaciones opcionales a descanso o reflexión sobre expedientes cerrados; máximo una, caducidad sin castigo e intervalo independiente de riqueza. Memoria periódica derivada de hechos conocidos y expedientes consultables. UI del capitán separada por áreas. Prueba: invitación no bloqueante, descanso con coste, no repetición, resumen y persistencia.

## Plan de v0.25

Cuatro arcos elegibles con criterios visibles, cierre/retiro voluntario y continuación; ajustes independientes de mantenimiento, daño y frecuencia narrativa. Regresión completa, compatibilidad de guardados y campañas prolongadas.

## v0.25 — Implementada; cierre de verificación integral

Arcos de independencia, prestigio, protección y deuda elegida, con requisitos consultables, pagos registrados, cierre único y retiro reanudable. Ajustes independientes del coste de mantenimiento futuro, daño fijado por despliegue e intervalo de invitaciones. No incorpora muerte permanente ni sucesión automática.

Seis campañas RPG de 180 días (tres semillas × 3027/3060) completaron 15–16 operaciones sin aportes artificiales, con 8–9 memorias periódicas y guardados exactos. La reserva efectiva de oficiales/unidades se verifica además de su fecha de descanso. Se añadieron validaciones de trabajos, cláusulas y recuerdos para rechazar datos malformados sin alterar la partida. Diez páginas del capitán inspeccionadas en ventana; texto y controles no colapsan en columnas.

Alcance de esta entrega: conflictos solo en sistemas visitados; tres familias de asuntos con texto estructurado; salvamento como lotes de repuestos, sin reconstrucción de chasis completos. Los valores expresados del círculo influyen en encargos, sin inventar rasgos privados. La reputación de fiabilidad afecta negociación; la discreción se registra como historial de representación. El ajuste económico afecta mantenimiento, no todos los precios. Estas son reglas propias de la primera implementación, no una reproducción de Destiny o MekHQ.

La economía de los seis ensayos deja reservas crecientes con una estrategia de reconocimiento/interdicción y mantenimiento prudente. Esto demuestra viabilidad técnica, no equilibrio de todas las estrategias ni dificultad final. El interés de escenas, sensación de rol y ritmo requieren la prueba del jugador.

Cierre técnico final: **31 suites de simulación y 17 de interfaz aprobadas**, más nueve fixtures históricos producidos por las fuentes reales de v0.16–v0.24 y cargados en v0.25. Los informes están en `test-results.json`, `ui-test-results.json` y `rpg-migration-fixtures.json`. Pruebas nativas de páginas inspeccionadas en `rpg-officers.png` y `rpg-legacy.png`.

Aplicaciones locales autocontenidas v0.23 y v0.25 en `exports/`, con arranque comprobado. El acceso `~/Desktop/Mercenary Command.app` apunta a v0.25; v0.23 se conserva. No se cerraron partidas del usuario ni se modificó `campaign.json`. Se debe guardar/cerrar una sesión anterior antes de abrir la nueva para no mezclar versiones sobre el mismo archivo.
