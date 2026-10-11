# Generador de historias — entregas v0.33–v0.37

Ampliación incremental de la simulación existente, sin reemplazar contratos, RPG, operaciones ni interfaz. Se preservan guardados y no se reconstruyen recuerdos anteriores a la migración. Las nuevas reglas son ficción de campaña, no canon histórico ni reglas de Destiny.

1. **v0.33 Memoria causal:** registro con IDs, participantes y antecedentes explícitos; operaciones y decisiones enlazadas; inspector en Crónica y expedientes. Validar orden causal, privacidad, migración, carga y continuidad del azar.
2. **v0.34 Personas:** aspiraciones deterministas por persona, valores, límites declarados, peticiones voluntarias, respuestas y recuerdos con consecuencias. Reutilizar confianza, descanso y ascensos; máximo una petición pendiente. Validar costes, disponibilidad, plazos, repetición y bajas.
3. **v0.35 Pertenencia:** prácticas de cuidado, reparto y profesionalidad derivadas de actos; bonificaciones con expectativas; historia de máquinas y vínculo por servicio real; reacción a ventas. Sin moralidad universal. Validar que no se premie el spam y que vender conserve el historial.
4. **v0.36 Iniciativas:** objetivos elegidos de apoyo personal, comunidad y red de apoyo; vías materiales, personales y delegadas, con reserva real de tiempo y costes, resultado persistente y cancelación sin reembolso ficticio. Validar cada vía, reservas, viajes y desenlaces.
5. **v0.37 Mundo y ritmo:** enlace recurrente por lugar visitado, memoria local que habilita ayuda, oportunidades causales acotadas y descanso entre peticiones. Coordinar con invitaciones existentes; no producir pérdidas forzadas por riqueza. Validar 90 días, guardados intermedios, límites de carga y diversidad entre semillas.

Interfaz: integrar en Mando/Bandeja, Crónica, Personal/Hangar, Capitán y Mundo; sin nuevas ventanas. Información de jugador exclusivamente procedente de hechos propios y comunicaciones públicas. Implementación sin dependencia de IA ni conexión.

Cada entrega se prueba y guarda como snapshot antes de pasar a la siguiente. Al final: regresiones completas, recorrido de UI, ejecutable macOS y acceso directo actualizado. Las pruebas de simulación comprueban reglas y continuidad; apego y ritmo requieren evaluación del jugador, no se declaran demostrados automáticamente.

## Estado final

Las cinco entregas están implementadas e integradas en v0.37.0. Snapshots v0.33, v0.34, v0.35 y v0.36 conservan los puntos de avance; v0.37 incluye el cierre de regresiones y las correcciones de integración. Alcance concreto, límites y comprobaciones en RELEASES-Story.md.
