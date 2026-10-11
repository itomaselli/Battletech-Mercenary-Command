# v0.3 — Hangar y mercado

Ampliar Campaign y las páginas existentes, sin sustituir arquitectura, combate ni estado previo. Conservar una operación y un máximo de cuatro máquinas desplegadas.

1. **0.3.1 Hangar:** hasta ocho plazas, identificadores únicos por máquina, asignaciones y taller para toda la flota. Migración conservando las cuatro iniciales y operaciones activas.
2. **0.3.2 Mercado:** cuatro ofertas renovables cada 14 días, máquinas usadas con integridad y precio conocidos, compra con pago completo y entrega diferida, venta por cotización con confirmación. Una compra reserva plaza; la venta no puede afectar una máquina desplegada o en taller. Los índices internos de operaciones y taller se preservan al retirar máquinas.
3. **0.3.3 Propiedad:** mantenimiento y almacenamiento devengados por día, cobro mensual; reserva almacenada de bajo coste con reactivación pagada de dos días. Comparación de compra, reparación y coste recurrente. La venta no borra costes ya devengados.
4. **0.3.4 Integración:** finanzas, crónica, UI, guardados, casos límite y campañas de seis meses con rotación de máquinas.

Catálogo inicial: los cuatro modelos ya presentes. Precios y costes comprimidos para la economía del prototipo; no son precios oficiales de BattleTech. Sin atributos de combate nuevos ni armamento individual. No se cobra mantenimiento retroactivo al migrar.

Validación: pruebas en cada etapa, regresiones actualizadas solo donde cambian reglas explícitas; migración de esquemas anteriores; compra/entrega/venta sin duplicados; máximo de cuatro desplegados; capacidad contando tránsito; mantenimiento y libro conciliados; UI ejecutada y capturas revisadas. No tocar sources/ ni el guardado real de la partida abierta.

## Entrega v0.3.4

- [x] 0.3.1: hangar dinámico, ocho plazas, seriales persistentes y límite de cuatro desplegados. Siete comprobaciones iniciales aprobadas.
- [x] 0.3.2: mercado, compras en tránsito, confirmaciones y venta con conservación de asignaciones y operaciones. Veintitrés comprobaciones acumuladas aprobadas.
- [x] 0.3.3: almacenamiento, reactivación, devengo, facturación y previsión. Treinta y nueve comprobaciones acumuladas aprobadas.
- [x] 0.3.4: finanzas, UI, migraciones y campañas integradas. Ciento veinticinco comprobaciones específicas aprobadas; veinte campañas llegaron al día 180.

Validación final en Godot 4.4.1/macOS: 125 comprobaciones de v0.3, 127 de v0.2, 46 regresiones iniciales, 16 del recorrido anterior de interfaz y 9 del nuevo recorrido de mercado: **323 comprobaciones, sin fallos**. Prueba de nombres también aprobada. Capturas de mercado, hangar y propiedad revisadas. No se modificó el guardado real.

Formato de guardado 9; las migraciones conservan operaciones, personal, daños, compras y fondos. Las máquinas activas generan mantenimiento más almacenamiento; las almacenadas solo almacenamiento. Reactivar cuesta 1.000 y dos días. Los costes devengados no desaparecen al vender. La deuda vencida impide nuevas compras y despliegues, pero permite terminar una operación ya iniciada.
