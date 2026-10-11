# Inventario de funciones y rutas — v0.31

La simulación recibe los mismos comandos. Los renderizadores de administración, operaciones y RPG se reutilizan en modo integrado; se conservan como adaptadores internos sin mostrar sus ventanas. El controlador histórico solo se instancia desde `tests/fixtures/v025_main.tscn`.

| Función anterior | Destino actual | Cobertura |
|---|---|---|
| Tiempo, asuntos bloqueantes, partes | Mando / Bandeja; barra superior | inbox_ui, journey_ui |
| Nómina, pedidos, metas, trabajos | Mando / Agenda | routes_ui; regresión simulación |
| Crónica, diario, invitaciones y resúmenes | Mando / Crónica; Bandeja | routes_ui; rpg_v23 |
| Personal, descanso, ascensos, vínculos, bajas | Compañía / Personal | inbox_ui; v04/v05; rpg_v17 |
| Pilotos, estado, venta, almacenar, reactivar | Compañía / Hangar | routes_ui; v03; unit_cards_ui histórico |
| Cola, integridad, averías, canibalizar, salvamento | Compañía / Taller | routes_ui; rpg_v20 |
| Contratos originales, misiones y oportunidades | Operaciones / Contratos | journey_ui; expansión; v06 |
| Negociación y cláusulas | Inspector de contrato | routes_ui; rpg_v19 |
| Doctrina, selección, jefe, enfoque y prioridades | Operaciones / Preparación | journey_ui; phase3 |
| Consultas, órdenes en tránsito, retirada y archivos | Operaciones / En curso | routes_ui; phase3 |
| Encargos a oficiales a medida y consultas | Operaciones / Encargos; Bandeja | routes_ui; rpg_v22 |
| Viajes, búsqueda de sistemas y afiliaciones | Mundo / Atlas | routes_ui; expansión |
| Mapa ambiental 80×25 y retratos | Mundo / Entorno | routes_ui; phase4 |
| Directorio local, lore, informes y enlaces RPG | Mundo / Contactos | layout_ui, journey_ui; v06; rpg_v18 |
| Conflictos, mediación y ayuda civil | Mundo / Región | routes_ui; rpg_v21 |
| Comprar unidades, catálogo y comparar | Mercado / Unidades y Catálogo | routes_ui; expansión |
| Suministros, logística y compras rutinarias | Mercado / Repuestos; Taller | routes_ui; v02; rpg_v20 |
| Contratar empleados | Mercado / Personal | routes_ui; v02 |
| Previsión, deudas y libro | Finanzas | shell_ui; v02/v03 |
| Trasfondo, experiencia, promesas y conversaciones | Capitán / Personaje; expediente de persona | routes_ui; rpg_v16/v17 |
| Aventura inicial y expedientes RPG | Capitán / Asuntos; Bandeja urgente | routes_ui; rpg_v16/v18 |
| Arcos, retiro, legado y ajustes de dificultad | Capitán / Legado | routes_ui; rpg_v24 |
| Identidad, efectos y texto | Campaña / Identidad y Opciones | routes_ui; layout_ui |
| Crear, revisar, sortear, cancelar, guardar/cargar | Campaña / Partidas | career_wizard_ui; career_library; career_start |

No se crean eventos al navegar. Selecciones y filtros se conservan por ruta; el mapa mantiene su vista. Las listas de contratos/mercado muestran un inspector en lugar de repetir todas las acciones. Los textos históricos de informe no son enlaces automáticos; el acceso contextual está disponible desde avisos de unidad, círculo del capitán y asignaciones.

A 1100×740 y 1360×960 se verifican barras, ancho de contenido y textos con tamaño grande. Los paneles se apilan a menor ancho; se usa desplazamiento vertical cuando el contenido excede la ventana. Las capturas se inspeccionan visualmente, además de las aserciones geométricas.
