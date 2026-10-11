# Sprites por modelo — v0.32

56 máscaras originales de 16×24, no 7 siluetas genéricas: 24 chasis con dos variantes cada uno y 8 vehículos. Cada imagen contiene exactamente fondo + color principal + detalle, todos de la paleta de 18 colores. La geometría de las 56 máscaras es distinta incluso ignorando su paleta.

## Referencias y decisiones

Se consultaron las fichas e ilustraciones enlazadas en [unit-art-references.json](unit-art-references.json). Se priorizaron imágenes de las configuraciones clásicas de TRO:3025/3039 cuando estaban disponibles. Las armas de cada variante se cotejan con el catálogo actual. Las imágenes originales se usaron solo para inspección temporal, no forman parte del paquete.

- Locust: cuerpo bajo, armas laterales y patas articuladas; LCT-3D incorpora cajas LRM.
- Hunchback: joroba derecha; 4G representa una boca de autocañón y 4P una parrilla de láseres.
- Catapult: cabina central, cajas elevadas y patas invertidas; C3 distingue el Arrow IV con aperturas grandes, sin representar varios sistemas independientes.
- Rifleman: antena horizontal y brazos dobles; JagerMech conserva torso cajón y cañones más altos.
- Shadow Hawk, Griffin y Thunderbolt: armamento de hombro asimétrico y cabezas de distinta posición.
- Marauder y Jenner: carenados de torso sin cabeza humanoide separada; piernas y armas características.
- Vehículos: cascos, movilidad y torretas propios. Scorpion y Vedette tienen proporciones distintas; Striker lleva ruedas; Demolisher dos cañones; SRM Carrier una parrilla densa y LRM Carrier tres cajas.

A esta escala son interpretaciones esquemáticas. La disposición frontal usa derecha del vehículo = izquierda del observador. Camisas de cañón, aperturas energéticas y paneles se exageran para distinguir refits; no son planos técnicos ni afirman cambios estructurales canónicos para cada mejora ER/pulse/UAC. Los colores no indican facción. No se añaden armas ni efectos a la simulación.

## Edición y reproducción

`tools/build_unit_art.py` conserva los dibujos nativos en texto (`.` fondo, `#` blindaje, `+` detalle) y parches explícitos por variante. No usa reducción automática de ilustraciones, dependencias de imagen ni generación aleatoria. La ruta de ejecución `Art.unit_sprite(model_id)` carga el registro y rasteriza/cachea con la paleta existente. Los índices antiguos 0–6 solo sirven a llamadas históricas.

```sh
python3 tools/build_unit_art.py
godot --headless --path . --script tools/export_unit_art.gd
godot --path . --script tools/unit_art_gallery.gd
godot --headless --path . --script tests/unit_art.gd
godot --headless --path . --script tests/unit_art_ui.gd
```

PNG en `assets/units/` son exportaciones reproducibles; editar el PNG no modifica la máscara fuente. Para agregar un modelo, registrar su máscara y exportarla. El test de cobertura falla si falta algún ID del catálogo, se repite una máscara o un PNG diverge de su fuente.

## Validación

`unit_art.gd`: cobertura completa, unicidad de píxeles y máscaras, 3 colores de la paleta, dimensiones, igualdad de PNG, ausencia de cambios de simulación y carga del guardado real v0.25.

`unit_art_ui.gd`: recorre las 56 fichas reales del catálogo y las fichas de hangar/taller; compara la textura mostrada con su ID, verifica 48×72 y estado intacto. `unit_cards_ui`, `layout_ui` y `journey_ui` cubren proporciones, dos resoluciones y el recorrido jugable. La galería y una captura dentro del juego se inspeccionan visualmente.

### Resultado de entrega — 10 de octubre de 2026

Aprobados: cobertura y compatibilidad de arte (`unit_art.gd`), regresión de catálogo/vehículos (`v13.gd`) y las 24 suites de interfaz. La prueba de las 56 fichas también aprobó ejecutándose desde el paquete macOS v0.32.0. Se cotejaron 125 archivos de recursos y código con el paquete. Galería y captura de catálogo revisadas visualmente. Acceso directo del escritorio actualizado; ejecutable anterior conservado.
