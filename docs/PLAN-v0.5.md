# Fase II / v0.5 — Actores y relaciones

Entrega acotada: cuatro organizaciones contratantes, tres compañías rivales y relaciones persistentes. Sin actividad autónoma, adjudicación rival ni eventos mundiales todavía (v0.6+).

1. Añadir módulo de mundo independiente, con IDs estables, perfiles públicos e información interna separada. Actores locales ficticios; el enlace Davion no representa acontecimientos oficiales.
2. Conectar empleadores de contratos y confianza existente, sin duplicar su fuente de verdad ni aplicar penalizaciones por asociación. Tres ofertas por renovación: el tercer puesto alterna entre enlace y consorcio.
3. Añadir directorio Mundo: intereses declarados, especialidad, procedencia, vínculos conocidos y contacto. Establecer un canal cuesta 1.000 una sola vez; no aumenta confianza ni genera ventajas ocultas.
4. Migrar partidas al día actual sin hechos retroactivos; mantener términos/operaciones activas. Validar información pública, contactos, relaciones, contratos y regresiones.

No reestructurar la compañía, personal ni combate. No tocar sources/ ni guardados reales. Los datos internos se guardan localmente; fog of war es una separación de presentación, no cifrado antitrampas.

## Entrega completada — v0.5.0

Implementados los cuatro pasos: módulo `sim/world.gd`, integración aditiva con contratos y confianza, directorio Mundo y migración al formato 13. No se sustituyó la arquitectura de simulación ni la resolución de operaciones.

Validación: 25 comprobaciones nuevas de simulación y 6 de interfaz, más 434 comprobaciones de regresión; todas aprobadas. Personalización de nombres aprobada adicionalmente. Se ejecutó el recorrido con ventana y se inspeccionaron las fichas de contratante y rival. Las pruebas comprueban que el informe público no incluya estado interno, que sus datos estén desacoplados del estado editable y que migración y contactos no consuman aleatoriedad de combate.

Siguiente entrega prevista: v0.6, actividades autónomas de compañías y organizaciones, con decisiones derivadas de recursos y prioridades, resultados persistentes y comunicación mediante informes con procedencia. No incluida en v0.5.
