# Plan v0.2 — ampliación incremental

Conservar Campaign (RefCounted), escena, comandos existentes, resolución abstracta y crónica. Sin reemplazar la arquitectura. Extender el formato de guardado mediante migraciones y mantener operaciones antiguas.

1. 0.2.1: identificadores estables de empleados, contratación/despido, reservas, asignación única y jefe desplegado. Validar costes, bajas y bloqueos.
2. 0.2.2: capacidad técnica, cola priorizada, estimaciones y pedidos normales/urgentes con descuento limitado. Validar entregas y consumo.
3. 0.2.3: aceptación separada, anticipos, plazos, mínimos, retirada y relaciones. Validar que no haya dobles pagos ni contratos simultáneos.
4. 0.2.4: libro financiero, proyección a 30 días, asuntos urgentes que interrumpen el avance, interfaz integrada y campañas de seis meses.

Criterio final: todos los comandos accesibles desde la UI; guardados antiguos y nuevos válidos; pruebas de reglas y flujo completo. No tocar sources/. No cerrar una partida abierta ni sobrescribir su guardado durante pruebas.

## Resultado de ejecución

- [x] 0.2.1: personal y asignaciones implementados; 7 pruebas específicas y regresiones aprobadas antes de continuar.
- [x] 0.2.2: logística, capacidad y reservas implementadas; 16 pruebas acumuladas aprobadas antes de continuar.
- [x] 0.2.3: aceptación, anticipos y condiciones implementados; 29 pruebas acumuladas aprobadas antes de continuar.
- [x] 0.2.4: libro financiero, previsiones, decisiones y relación causal integrados.

Validación final: 127 comprobaciones de v0.2 + 46 regresiones + 16 comprobaciones del flujo UI, todas aprobadas en Godot 4.4.1/macOS. Además, pruebas de apertura y personalización aprobadas. Se revisaron capturas de mando, personal, finanzas y asuntos urgentes. Se ejecutaron veinte campañas de hasta 180 días verificando progreso, repetición de contratos, conservación de recursos, conciliación del libro y diversidad de resultados.

Decisiones de alcance: el jefe elegido firma los informes, sin bonificación adicional de combate; retirada abstracta inmediata sin combate extra; la fiabilidad de inteligencia es informativa. El suministro sigue agregado. La migración abre el libro financiero con el saldo existente, sin reconstruir historia no disponible.
