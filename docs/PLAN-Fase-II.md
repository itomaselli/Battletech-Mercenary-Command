# Fase II — Mundo vivo: cierre en v0.8.0

## Plan y secuencia completada

- v0.5: cuatro organizaciones contratantes, tres compañías rivales, identidad y contactos persistentes.
- v0.6: necesidades, decisiones autónomas, encargos, desgaste, recuperación y comunicados.
- v0.7: oportunidades del jugador derivadas de necesidades no resueltas; aceptación y resolución mediante el sistema contractual existente; consecuencias que vuelven al mundo.
- v0.8: consultas con demora, conocimiento fechado que envejece, declaraciones revisadas, vínculos públicos actualizados y migración de partidas.

El cierre se entrega en un ejecutable v0.8.0 con formato de guardado 16. No se publicó un formato intermedio 15. Integración aditiva: se conserva el núcleo, el calendario, las finanzas, el combate abstracto y las ocho pestañas existentes.

## v0.7 — Oportunidades causales

Cada siete días desde la activación del sistema se revisan necesidades. Un contratante con necesidad de al menos cuatro puede emitir una solicitud extraordinaria. Solo tiene una abierta o aceptada a la vez, y pasan al menos 28 días entre solicitudes. La oferta dura siete días y puede retirarse si la necesidad baja de tres antes de aceptarla. La fuente es una solicitud explícita del empleador, no una lectura de información privada.

Las oportunidades se consultan en el perfil del contratante dentro de Mundo. Tienen pago, anticipo, fuerza mínima, duración, origen, fecha y estado. El pago base es 65.000 más 3.000 por punto de confianza; se conservan las reglas habituales del anticipo y del fracaso. Se financian mediante la economía contractual abstracta ya existente: no descuentan el presupuesto que v0.6 utiliza para encargos entre NPC. No se simula una economía monetaria cerrada entre todos los actores.

Aceptar usa el mismo límite de un contrato, anticipo, cinco días para desplegar, órdenes y resolución militar. Los términos aceptados quedan fijados. El éxito reduce tres puntos de necesidad; fracaso, retirada o cancelación aumenta uno, limitado a seis. El historial y la crónica conservan la consecuencia y la identidad de su origen. Estas necesidades influyen en las decisiones autónomas posteriores.

Las tres ofertas periódicas originales siguen disponibles con sus reglas para conservar la jugabilidad anterior. No se trata aún de un mercado exclusivo donde rivales y jugador pujen por el mismo contrato. Se conservan hasta 40 oportunidades en el directorio y ocho visibles por actor; la crónica registra los acontecimientos.

## v0.8 — Información y relaciones

Un contacto establecido permite solicitar una declaración por 500 C-bills libres. Llega dos días después e informa sobre la situación declarada en la fecha del envío, no sobre el estado actual. Una consulta pendiente no puede duplicarse. Tras recibir una respuesta hay que esperar siete días antes de pedir otra.

El informe distingue fecha observada y recibida, fuente y falta de corroboración. A los siete días desde la observación aparece como antiguo. No revela fuerza exacta, composición enemiga, destino ni agendas privadas. Si la declaración cambia, la crónica lo señala sin afirmar que la fuente mintió: las circunstancias pueden haber cambiado. No hay todavía espionaje, desinformación generada ni un modelo probabilístico de fiabilidad.

Los resultados declarados de encargos rivales actualizan sus vínculos públicos con el contratante, con fecha y fuente. Los antecedentes numéricos internos continúan afectando sus decisiones sin revelarse al jugador. La confianza del jugador permanece separada de esos antecedentes.

## Persistencia y pruebas

La migración desde v0.6 preserva el mundo, sus encargos y comunicados, contratos del jugador, finanzas y crónica. El nuevo sistema empieza en el día de carga: no inventa oportunidades ni consultas anteriores. Los informes pendientes y contratos de origen mundial se conservan al guardar; se rechazan referencias inválidas sin alterar la partida actual.

Pruebas: `tests/phase2.gd` para oportunidades, éxito, fracaso, retirada, vencimiento, cambios de necesidad, contactos, demoras, antigüedad, revisiones, migración y seis meses de consistencia. `tests/phase2_ui.gd` para aceptación, cancelación, consulta y recepción desde los controles. Se ejecutan además las suites de v0.1–v0.6. Captura revisada: `phase2-preview.png`.

## Fuera de esta fase

La Fase III profundizará órdenes militares, autonomía de subordinados, fricción e informes operacionales. La Fase IV abordará la presentación visual definitiva. Viajes, conquista territorial y diplomacia completa de las Grandes Casas no están implementados en este cierre local de Mundo vivo.


### Validación del cierre v0.8.0

**1.455 comprobaciones aprobadas**: 1.225 de las entregas anteriores, 223 de los nuevos sistemas (incluyendo 180 controles diarios) y siete del flujo de interfaz. También pasó la personalización de nombres. Godot 4.4.1 ejecutó el recorrido con ventana y se revisó la captura de oportunidad aceptada e informe recibido. Se probaron migraciones, guardado con consultas y contratos pendientes, consecuencias por éxito/fracaso, confirmaciones y límites contra duplicación. Los guardados de prueba no reemplazan `campaign.json`.
