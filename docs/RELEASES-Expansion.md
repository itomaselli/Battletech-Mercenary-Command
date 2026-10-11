# Implementación secuencial de la expansión

## v0.11 — Cerrada

Escenarios 3027/3060, IDs estables de variantes con compatibilidad del índice anterior, navegación por tareas, acceso de campaña y bandeja unificada de decisiones. Gestión usa botones visibles en lugar de pestañas desplazables. Las campañas antiguas conservan 3027.

Verificación: tests/v11.gd, run.gd, v02_ui.gd y phase3_ui.gd aprobados. Snapshot local en releases/.

## v0.12 — Plan

Importar y conciliar todos los sistemas del conjunto Sarna; informar la antigüedad de los cortes políticos; atlas con búsqueda, zoom, selección y fuente. Añadir quince entidades históricas con disponibilidad por escenario y relaciones hacia el jugador, sin reemplazar retrospectivamente actores locales.

## v0.12 — Cerrada

Atlas de 3.175/3.175 sistemas del conjunto Sarna, sin filas descartadas; búsqueda por nombre/alias, IDs para nombres repetidos, zoom, arrastre, selección y filtro por afiliación. Los cortes 3025 y 3059d se indican en pantalla y fichas. Quince actores históricos, diez accesibles en 3027 y quince en 3060, con contactos persistentes. Esta entrega no afirma fronteras exactas de 3027/3060: véase atlas-audit.json.

Pruebas v12.gd, v12_ui.gd y ui_smoke.gd aprobadas. Siguiente: catálogo curado, perfiles funcionales, dotaciones y siete sprites; fechas extraídas de fichas de unidades, con enlaces de contexto a Sarna.

## v0.13 — Cerrada

Catálogo de 56 registros: 48 variantes Mech en 24 chasis y ocho vehículos; 34 disponibles en 3027 y 56 en 3060. Fuentes factuales con hash, créditos y campos de balance separados. Dotaciones agregadas de cuatro integrantes, contratación y asignación diferenciadas. Siete siluetas originales de 16×24 con tres colores, mostradas en mercado/hangar y catálogo filtrable con comparación. Los perfiles añaden un modificador acotado al iniciar nuevas operaciones; las operaciones guardadas previamente conservan su resolución.

Validación: fechas de todos los lotes a lo largo de 224 días, compra/entrega/asignación/guardado de un vehículo, 56 IDs únicos, límites de color y dimensiones, filtro de ocho vehículos y búsqueda de variante. Regresión de operaciones militares: 295 comprobaciones sin fallos. Inspección visual del catálogo.

## Plan de v0.14

Añadir cinco evaluadores independientes con progreso persistido y resultados completo/parcial/fallo. Generar ofertas locales con semilla separada, origen causal, empleadores del lore y objetivos compatibles. Integrar aceptación, órdenes, crónica, liquidación, cancelación y efectos regionales sin cambiar contratos antiguos.

## v0.14 — Cerrada

Cinco evaluadores de objetivo con estado separado: sectores relevados, acceso/evacuados, integridad de instalación, localización/intercepción y acceso/material recuperado. Éxito completo desde 75%, parcial desde 35%; pagos 100/60/15%, descontando anticipo. Dos prioridades por objetivo antes de desplegar; ampliar exposición acelera ciertos trabajos y suma daño; destruir convoy impide recuperar carga. Informes públicos de progreso, sin revelar fuerzas o fricción ocultas.

Generador local reproducible de cinco ofertas cada 14 días. Empleadores compatibles con afiliación, contactos disponibles por escenario, recompensa según relaciones, entornos y estado de seguridad/abastecimiento/inteligencia local. Resultados afectan necesidades posteriores, relación y crónica. Ofertas y contratos aceptados se guardan sin regenerar al cargar. Cancelación aplica devolución y consecuencias sin recompensas repetibles.

Validación: 147 comprobaciones, ambos escenarios, los cinco tipos, fuerzas débiles/fuertes, umbral parcial, continuidad exacta antes/después de cargar en misión, rechazo de aceptación repetida y cancelación. Regresión militar: 295 comprobaciones. UI: cinco ofertas, aceptación, tamaño de ventana y captura.

## Plan de v0.15

Rutas sobre sistemas documentados con saltos de hasta 30 años luz, cotización antes de partir, tiempo y coste de transporte simplificados explícitos. Bloquear despliegue/contratación/compras durante tránsito y conservar costes de calendario. Regiones y actores del lore producen actividad, noticias y demanda; mercados y misiones responden al destino. Revisar validación, campañas de seis meses, migración, interfaz y documentación final.

## v0.15 — Cerrada

Viajes cotizados y confirmados, rutas por saltos de hasta 30 años luz, duración/coste de juego explícitos y continuidad de salarios/mantenimiento. Persistencia en tránsito y llegada con actualización de ofertas. Se impiden contratos, compras, reclutamiento y pedidos durante el viaje; las entregas, reparaciones y contratos deben resolverse antes de partir. Sin servicios comerciales en registros sin población/abandonados/apócrifos. Las rutas desconectadas se informan sin inventar escalas.

Actividad semanal de las quince entidades según escenario, con comunicados públicos sin información militar exacta. Su actividad regional modifica seguridad y abastecimiento, que a su vez afectan misiones y precios. Los contactos registrados mejoran las ofertas futuras sin cambiar confianza ni revelar secretos. Inventario regional con un lote ligero, medio, pesado y terrestre por tanda. Perfiles, adquisiciones y transportes usan IDs estables; la red histórica ficticia conserva su ámbito de Galatea.

Se completó la búsqueda de crónica, la cotización en español y el desplazamiento de atlas/catálogo para mantener accesibles los controles. Revisados el flujo de confirmación sin cargo previo y una ventana de 1100×740. Corregida la normalización de años durante migración antes de consultar afiliaciones.

Validación final con Godot 4.4.1:

- **17 suites de simulación y 14 de interfaz aprobadas**, sin errores de script ni fallos; los ejecutores comprueban salida y diagnósticos del motor.
- Seis campañas de 180 días: semillas 9, 47 y 3027 en cada escenario. Entre 15 y 16 nuevas misiones completadas por campaña, sin aportes artificiales de fondos; persistencia en días 45, 90, 135 y 180.
- Migraciones reales desde snapshots v0.11, v0.12, v0.13 y v0.14 con una operación en curso, además de las pruebas históricas de esquemas anteriores.
- Cotización, rechazo de repetición, guardado en tránsito, llegada equivalente con/sin carga, servicios y renovación de ofertas. Vehículo con dotación: compra, asignación, mando, operación, daño, experiencia, reparación y guardado.
- Seis casos de guardado corrupto rechazados sin alterar la campaña activa. Ningún ensayo usa el archivo real `campaign.json`.
- Capturas nativas revisadas: atlas, catálogo, misiones y confirmación de viaje. Informes reproducibles en `test-results.json` y `ui-test-results.json`.

### Alcance final y límites explícitos

Las cinco entregas están implementadas localmente y archivadas en `releases/`. No se configuró un remoto ni se publicó en GitHub. El atlas reconcilia los 3.175 registros del conjunto adoptado; usa política de 3025/3059d como referencia visible, sin afirmar exactitud de fronteras de 3027/3060. No hay evolución histórica automática de fronteras, simulación táctica por casillas, catálogo exhaustivo de diseños ni tablas canónicas de distribución regional. Los perfiles, dotaciones agregadas, precios y tiempos locales son abstracciones jugables documentadas. Estas restricciones están expuestas en el README y en las fichas pertinentes.
