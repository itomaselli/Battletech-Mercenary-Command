# Plan de refactor de interfaz y nueva carrera — v0.26 a v0.31

Estado: entregas v0.26–v0.31 implementadas y verificadas. Consultar RELEASES-UI-Career.md para resultados y límites. Base: v0.25. El usuario considera completo el conjunto de funciones y solicita simplificar el uso, mantener estética low-res y variar las compañías iniciales. Decisión confirmada: cuatro unidades del pool completo, incluidos vehículos, respetando el escenario 3027/3060.

## Experiencia buscada

Administrar desde un puesto de mando persistente: ver qué requiere atención, decidir, comprobar el efecto y continuar. Las decisiones conservan profundidad; navegar deja de exigir recordar ventanas, pestañas y botones duplicados. Se mantienen simulación, resultados, reglas y guardados; se modifica presentación y se añade generación inicial.

Referencias de diseño:
- Career Mode de HBS: creación de una carrera mercenaria independiente, preparación de identidad y condiciones iniciales, equipo diverso y comienzo con información clara. Se toma como inspiración, sin prometer equivalencia pantalla por pantalla, campaña de historia, Argo o puntuación temporal. Anuncio original: https://store.steampowered.com/news/posts/?appgroupname=BATTLETECH&appids=637090&enddate=1558698730&feed=steam_community_announcements
- Football Manager: navegación persistente, bandeja como lugar de decisiones, listas comparables y acceso contextual a expedientes. No copiar su densidad ni toda su interfaz. Referencia oficial: https://www.footballmanager.com/fm26/features/fm26s-reimagined-user-interface

## Diagnóstico del proyecto

`ui/main.gd` abre administración, rol, operaciones, mapa y misiones en ventanas independientes, además de accesos rápidos a destinos repetidos. `ui/management.gd` agrupa ocho áreas y `ui/rpg.gd` diez, con varias listas de botones largos. Una tarea puede empezar en Operaciones, negociarse en Capitán y resolverse en otro diálogo.

La nueva partida actual elige escenario, construye inmediatamente Campaign y después abre identidad. El constructor fija cuatro modelos y seis empleados; el registro de fundación menciona a Voss. `_init_personnel` asigna personal por posición y debe adaptarse a tripulaciones compatibles. La generación del círculo RPG ya usa roles e IDs y debe conservar esa independencia de nombres.

## Arquitectura de navegación

Una ventana principal con barra superior, menú lateral, contenido central e inspector contextual integrado. El inspector se adapta al ancho disponible; en tamaños pequeños reemplaza temporalmente la lista y conserva Volver. Sin ventanas flotantes para navegación ordinaria.

Barra superior: fecha y lugar, fondos libres, suministros, obligaciones próximas y acción Continuar. Continuar avanza hasta la siguiente interrupción que ya reconoce la simulación, o hasta un límite visible. Nunca decide por el jugador ni salta escenas. Conservar avance explícito de un día y opciones avanzadas de intervalo.

Menú y destinos:

| Área | Contenido |
|---|---|
| Centro de mando | Bandeja, agenda común, resumen, crónica con filtros |
| Compañía | Personal, hangar, taller y logística |
| Operaciones | Oportunidades, negociación, preparación, operación activa y encargos delegados |
| Mundo | Inner Sphere, conflictos, facciones y contactos |
| Mercado | Unidades, repuestos y contratación; los accesos desde otras áreas llevan al mismo destino |
| Finanzas | Caja, previsión, compromisos y movimientos |
| Capitán | Ficha, vínculos, asuntos personales y legado |

Diario, informes y crónica comparten una vista de historial filtrable. La agenda personal y los vencimientos de compañía se muestran en el mismo calendario con filtros. Cada función tiene un destino canónico; los enlaces cruzados no duplican formularios ni lógica.

Lista → selección → inspector. Seleccionar muestra estado, causa, requisitos y dos o tres acciones relevantes; las excepcionales quedan en un menú secundario. Operaciones masivas solo para rutinas autorizadas, con coste agregado y resultado por elemento. Conservar selección, búsqueda, orden y desplazamiento al volver o tras actualizar.

## Bandeja y decisiones

Una bandeja presenta decisiones obligatorias, avisos y oportunidades opcionales como categorías explícitas. Cada entrada tiene remitente, fecha, asunto, contexto, plazo y vínculo al objeto real. Una decisión se resuelve dentro de su detalle; al terminar pasa a historial. No crea una segunda copia ejecutable del evento.

Los diálogos modales se reservan para confirmar pérdidas irreversibles, sustituir una campaña sin guardar o errores que impiden continuar. La escena narrativa puede pausar el tiempo sin abrir una ventana modal. Las invitaciones de descanso siguen siendo opcionales.

Ejemplos de recorridos:
- Contrato: lista comparable → detalle y condiciones → negociar → aceptar → preparar fuerza → desplegar. Todo en Operaciones, preservando selección e información.
- Avería: aviso en bandeja → máquina seleccionada en Compañía/Taller → alternativas con coste, plazo y disponibilidad → ordenar → confirmación dentro de la página.
- Relación: persona seleccionada → expediente con funciones, condición, recuerdos y vínculo → conversar o encargar. El mismo expediente sirve desde Capitán, Personal o una noticia.

## Identidad visual

Mantener sprites 16×24, pixel art, paleta restringida y terminal. No forzar los formularios a la cuadrícula de mapas 80×25: esa regla pertenece al mapa. Retratos y unidades conservan proporción y escalado entero. Texto legible con escala configurable, filas alineadas, cifras comparables y espacio entre grupos.

Los estados usan texto e icono además de color. Scanlines/viñeta opcionales, con contraste suficiente. Teclado: foco visible, Enter confirma acción enfocada, Escape vuelve/cierra detalle, sin activar acciones destructivas accidentalmente. En 1100×740 no debe cortarse ninguna acción esencial ni comprimirse un sprite en una columna.

## Flujo de nueva carrera

Menú inicial → Nueva carrera → Escenario y condiciones → Capitán → Compañía → Fuerza y personal → Revisión final → Primer informe.

1. Escenario 3027/3060, preferencias existentes de economía/peligro/ritmo y semilla automática con opción de reproducirla. Galatea continúa como inicio predeterminado; cambiar o sortear planeta se deja fuera de esta entrega para no mezclar balance de localización con el randomizador.
2. Capitán: nombre, retrato/procedencia visual, origen, especialidad y motivación. El jugador puede personalizar o sortear; no se incorpora otro piloto a nómina por crear al protagonista.
3. Compañía: nombre e identidad visual usando recursos existentes. No añadir editor de emblemas ni sistema nuevo de logotipos en este refactor.
4. Fuerza: cuatro unidades, personajes asociados, técnico y logística. Mostrar composición, roles cubiertos, salarios y mantenimiento. Aquí se elige el vínculo inicial entre las personas generadas.
5. Revisión: fondos, costes mensuales, autonomía financiera estimada con supuestos visibles, capacidades y límites de la fuerza, escenario y preferencias. Permitir volver sin volver a sortear. Confirmar crea la campaña una sola vez.
6. Primer informe: quiénes integran la compañía, qué medios tiene y accesos a contratos, personal y mapa. Toda mención usa nombres y equipos reales generados.

El asistente mantiene un borrador separado. Cancelarlo no reemplaza la campaña activa ni escribe su guardado. La semilla se fija al generar el borrador; revisar o confirmar no realiza tiradas adicionales. Guardado separado por campaña para impedir que Nueva carrera sobrescriba la anterior; importar el guardado único existente manteniendo una copia intacta.

## Reglas de aleatoriedad

- Exactamente cuatro unidades totales: entre cero y cuatro BattleMechs; el resto puede ser vehículos. No existe un quinto vehículo adicional.
- Pool = todos los registros del catálogo disponibles en el año del escenario, incluyendo variantes y vehículos. Sorteo uniforme por registro elegible; sin cuotas de clase, tonelaje, facción, valor o obligación de incluir un Mech.
- Se permiten modelos repetidos como máquinas distintas con IDs propios. No se descartan composiciones fuertes, débiles o poco variadas de forma oculta. La UI explica que las variantes cuentan como entradas separadas.
- Mantener inicialmente fondos y suministros de v0.25 para aislar cambios. Un aviso informa costes elevados sin corregir el sorteo. Si las pruebas muestran un bloqueo funcional, corregir compatibilidad u ofrecer opciones explícitas; no sesgar silenciosamente el pool.
- Todas las unidades empiezan operativas, con identidad estable y una asignación compatible: Piloto para cada Mech y Dotación para cada vehículo. Dotación conserva la abstracción actual de grupo; no incorporar un subsistema de tripulantes individuales.
- Los empleados ya no son el elenco fijo. Generar nombre, indicativo donde corresponda, retrato, competencia y perfil público desde datos originales. Salario derivado de función/competencia, sin combinaciones arbitrarias inválidas. Sin lesiones o rencores retroactivos inventados.
- Garantizar cuatro puestos operativos, un responsable técnico con capacidad de taller mínima funcional y un responsable logístico. Se sortean las personas que ocupan estos roles; no se sortea la posibilidad de carecer de un rol imprescindible.
- El jefe inicial se elige entre personal operativo apto, incluido un jefe de Dotación. Círculo RPG y vínculo referencian IDs, no nombres ni índices rígidos.
- Permitir regenerar fuerza, personal o ambos antes de confirmar. Cambiar escenario regenera lo incompatible con aviso y mantiene los campos personalizados de identidad. Volver de pantalla o cargar no regenera nada.
- Semilla maestra y flujos independientes para fuerza, personas, retratos y simulación. Misma configuración y semilla reproducen el comienzo en la misma versión del generador. Guardar el resultado y versión, no depender de regenerarlo tras actualizar el catálogo.

## Implementación por entregas

| Entrega | Cambio | Criterio de cierre |
|---|---|---|
| v0.26 | Inventario de acciones y rutas; componentes compartidos; estructura persistente con Centro de mando y Compañía | Un recorrido real funciona integrado; sin pérdida de acciones ni cambios de simulación |
| v0.27 | Bandeja, inspector, historial de navegación y migración de Personal/Hangar/Taller | Resolver aviso y reparar sin cadena de ventanas; conservar filtros y selección |
| v0.28 | Operaciones completas, encargos, Mercado, Finanzas, Mundo y Capitán integrados | Todas las funciones existentes accesibles; se retiran las ventanas de navegación y duplicaciones anteriores |
| v0.29 | Generador inicial independiente, catálogo elegible, personal compatible y pruebas masivas | Cuatro unidades siempre; todos los registros elegibles alcanzables; identidad reproducible; cuatro vehículos jugables |
| v0.30 | Asistente Nueva carrera, revisión, vínculo, primer informe y guardados por campaña | Atrás/cancelar no alteran la partida; confirmación única; nueva carrera no borra la anterior |
| v0.31 | Recorridos completos, pulido visual/accesibilidad, compatibilidad y empaquetado | Regresión aprobada, pruebas de usabilidad y ejecutable actualizado |

El generador se desarrolla tras estabilizar navegación para que el asistente use los nuevos componentes. Se puede probar separado de la UI. No refactorizar reglas económicas/militares a la vez que sus pantallas. Mantener adaptadores temporales durante la migración y retirarlos después de cubrir todos los destinos.

## Validación

- Inventario función → pantalla anterior → destino nuevo → prueba: ninguna función desaparece al reorganizar.
- Comparar estados de simulación ante la misma secuencia de órdenes y semilla antes/después del refactor UI.
- Guardados v0.25 conservan exactamente su personal, unidades, nombres, relaciones, semillas e historias. Nunca aplicar el randomizador al cargar.
- Muestrear al menos 1.000 semillas por escenario: cuatro unidades, año válido, IDs únicos, roles compatibles, taller funcional y ausencia de errores. Revisar distribución como diagnóstico, sin tests frágiles de porcentajes exactos.
- Casos dirigidos: cuatro vehículos, cuatro Mechs, mezcla, variantes duplicadas, unidades caras, capitán sin vínculo, nombres largos, cancelación, cambio de escenario y confirmación doble.
- Jugar el primer contrato y taller con cada composición extrema para detectar supuestos sobre pilotos/Mechs. No exigir idéntica rentabilidad entre sorteos.
- Pruebas de navegación y foco a 1100×740 y resolución habitual, escala de texto y CRT apagado/encendido. Capturas inspeccionadas de listas, expedientes y asistente.
- Objetivos de interacción: asunto urgente visible al entrar; responder desde su detalle; abrir unidad/persona desde cualquier referencia; ninguna tarea ordinaria necesita apilar ventanas. Medir clics frente a v0.25, con objetivo de reducción y sin ocultar decisiones.
- La evaluación del jugador sobre orientación, claridad y comodidad cierra el diseño; las pruebas automatizadas no sustituyen esa valoración.

No se cambian ahora límites de operaciones, contratos simultáneos, inventario detallado, reglas de combate ni tecnología del catálogo. No se copian assets ni pantallas de los juegos de referencia.
