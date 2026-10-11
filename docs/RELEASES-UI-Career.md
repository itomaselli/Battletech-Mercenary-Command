# Entregas UI y nueva carrera

Base: plan v0.26–v0.31 y wireframe aprobado. La generación inicial afecta solo nuevas carreras. Fuentes sincronizadas y partidas del usuario no se modifican durante pruebas.

## v0.26 — Implementada y verificada

Estructura persistente, menú lateral, historial, componentes compartidos, páginas de hangar y finanzas. Prueba shell_ui aprobada: navegación y ausencia de ventanas visibles. El controlador histórico vive como fixture explícito de tests; sus pruebas verifican componentes conservados, no la navegación nueva.

## v0.27 — Plan

Bandeja derivada del estado real, inspector de avisos, expedientes de personal y unidades, selección estable y talleres reunidos.

## v0.27 — Implementada y verificada

Bandeja obtiene decisiones, avisos y partes directamente del estado; resuelve sin duplicar eventos. Inspector de unidad, asignación compatible, expediente de persona, vínculos, descanso y taller. Búsqueda, orden y selección por ID. Prueba inbox_ui aprobada: presentación no altera estado, se conservan selección y navegación.

## v0.28 — Plan

Integrar contratos/negociación/preparación, operaciones, encargos, atlas, mercado, catálogo y ficha RPG. Una ruta por tarea; conservar todos los comandos mediante componentes compartidos.

## v0.28 — Implementada y verificada

Rutas integradas de contratos, preparación, operaciones, encargos, atlas, contactos, mercado y capitán. routes_ui verifica todas las rutas sin mutación de campaña ni ventanas de navegación.

## v0.29 — Implementada y verificada

Generador independiente con dos flujos y resultados persistidos. 2000 semillas cubren todo el catálogo elegible en ambos años; cuatro vehículos y guardado/carga pasan. Migración conserva carreras anteriores sin generar otro personal.

## v0.30 — Implementada y verificada

Asistente de cuatro pasos con borrador, identidad, trasfondo, sorteo por dominio y vínculo. Guardados separados e importación del guardado antiguo sin modificarlo. career_wizard_ui verifica atrás, confirmación doble y preservación de campañas.

## v0.31 — Implementada y verificada

Entorno local integrado, retratos coherentes, texto ampliable, regresión y empaquetado.

### Cierre de validación

- 34 suites de simulación y 23 de interfaz aprobadas. Informes completos: test-results.json y ui-test-results.json.
- 2.000 semillas, catálogo completo de ambos escenarios, cuatro vehículos, Mechs repetidos y fuerza mixta. Contrato y reparación funcionales.
- Guardado generado por el código real de v0.25 conserva todo su estado y operación en curso; solo se añaden versión y metadatos vacíos de origen. Importación no modifica su archivo original.
- Recorrido mediante botones: crear → aceptar contrato → preparar cuatro unidades → desplegar → recibir resultado. Confirmación de contacto cancelable sin efectos.
- Capturas nativas revisadas a 1100×740 y 1360×960 con texto grande. Se corrigieron anchos de botones de flujo y tarjetas de unidad; sprites mantienen proporción.
- Guardados separados, confirmación única, cancelación/atrás sin regeneración y carga inválida conservando la campaña.

La valoración de comodidad y equilibrio de las fuerzas sorteadas corresponde a las próximas pruebas del jugador. No se promete equilibrio entre composiciones; todas las variantes elegibles tienen la misma probabilidad.

### Paquete local

Aplicación autónoma v0.31.0 creada y comprobada con su motor incluido: recorrido jugable y arranque nativo aprobados. Archivos del paquete comparados con el código verificado. Acceso directo del escritorio actualizado; v0.25 y sus archivos originales se conservan. Detalle: package-v031.json.
