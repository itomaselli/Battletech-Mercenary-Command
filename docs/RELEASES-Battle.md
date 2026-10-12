# Operaciones observables — plan de entregas

Implementación secuencial sobre v0.37, sin modificar fuentes sincronizadas.

1. v0.38: simulador determinista independiente, tablero 80×25, terreno procedural y misión de escolta.
2. v0.39: órdenes por grupos Alfa/Bravo, actitud, reserva, demora de comunicación, pausa y velocidades.
3. v0.40: detección/visibilidad, contactos recordados, informes y pausas por acontecimientos.
4. v0.41: integrar resultados y daños una sola vez, guardar/cargar combate y compatibilidad de operaciones antiguas.
5. v0.42: objetivos de reconocimiento, defensa, interdicción, extracción y recuperación, mapas transitables.
6. v0.43: autonomía condicionada por habilidad/fatiga, retirada por preservación, debriefing causal y regresiones.

Criterios: mismo estado+órdenes produce mismo resultado con y sin pantalla; guardar/reanudar no altera el desenlace; la vista pública no filtra enemigos ocultos; nunca doble liquidación ni daños aleatorios añadidos. Pruebas de terreno, órdenes, detección, objetivos, persistencia, integración y UI, más suites existentes.

Alcance: combate de mando simplificado propio. Integridad agregada, calor, munición, averías de movilidad y sensores; no reglas completas de localizaciones BattleTech. Un tick representa diez segundos. El encuentro ocurre dentro del plazo del contrato: observarlo no adelanta por sí solo días administrativos. Tras completarlo, avanzar calendario procesa retorno y liquidación. Delegar usa exactamente el mismo motor. Operaciones guardadas sin campo `battle` conservan su resolución anterior.

## Entregas implementadas

- v0.38: motor JSON determinista y caminos conectados en mapas de llanura, colinas y urbano. BFS evita agua para vehículos y casillas ocupadas.
- v0.39: siete órdenes, actitudes con efectos en precisión/calor y retirada, recepción en dos ticks, grupos fijos por orden de selección; UI pausa/paso/1×/4×/12× y delegación.
- v0.40: línea de visión bloqueada por colinas/edificios, cobertura, alcance de detección, contactos envejecidos, pausa opcional por contacto/baja/extracción. La vista pública excluye composición y estadísticas enemigas ocultas.
- v0.41: resultado del motor sustituye el resultado abstracto y el daño aleatorio; conserva pagos, reputación, lesiones y sistemas de campaña. Persistencia validada, retiro bajo fuego y cierre idempotente.
- v0.42: escolta mueve un convoy acompañado; reconocimiento releva franjas; defensa conserva una instalación durante el encuentro; interdicción detiene transportes antes de su salida; extracción/recuperación requieren presencia en el objetivo sin oposición próxima.
- v0.43: valores de cuidado/equipo/deber modifican el umbral de retirada cautelosa. Habilidad, fatiga y daños influyen en el combate. Memorias individuales, informes causales y debriefing persisten sin inventar motivos ocultos.

## Límites explícitos

Alfa/Bravo son dos grupos fijos, no un editor de organización. La munición es agregada y agotarla reduce potencia (respaldo energético abstracto); no se representan todas las armas individuales. Averías se expresan como pérdida de movilidad/sensores según integridad. No hay elevación tridimensional, localizaciones de daño ni reglas oficiales. La información del terreno es conocida; la niebla afecta contactos. El convoy objetivo tiene ruta/localización conocida. Las misiones RPG especiales conservan sus escenas y usan escolta como encuentro inicial. No hay reproducción de vídeo ni rescates individuales interactivos; sí estado determinista y recuperación de tripulantes conforme a las reglas existentes.

## Pruebas

`battle_engine.gd`: seis objetivos, determinismo, vista pública, órdenes diferidas y validación.
`battle_orders.gd`: reservas cambian progreso, contactos perdidos no siguen enemigos, continuidad JSON, retirada, doce encuentros/terrenos y corrupción.
`battle_campaign.gd`: guardar/cargar en combate, observar/delegar equivalentes, daños exactos, liquidación única, retirada y guardado posterior.
`battle_ui.gd`: dos tamaños de ventana, ausencia de desbordamiento horizontal, transmitir, pausar/reanudar, fin y capturas gráficas.
`export_smoke.gd`: verifica también el encuentro empaquetado y la reanudación determinista con comprobaciones activas en release.

Verificación final: 47 suites de simulación y 26 de UI aprobadas antes del cierre; comprobación adicional de pago parcial para contratos originales (60% si no hay importe específico). Las reglas de peligro del capitán escalan la potencia hostil y el apoyo contratado mejora protección. Paquetes macOS y PCK Windows comprobados mediante smoke test; consultar GitHub Actions para ejecución nativa Windows.
