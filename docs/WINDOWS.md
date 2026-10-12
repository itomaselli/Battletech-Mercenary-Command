# Windows x64 — v0.43.0

Extraer el ZIP completo y abrir MercenaryCommand.exe. MercenaryCommand.pck debe permanecer al lado del EXE. No requiere Godot, Python ni conexión. El ejecutable es portátil, de 64 bits, con renderizador Compatibility y sin firma digital.

Guardados en `%APPDATA%\Godot\app_userdata\BattleTech • Mercenary Command\careers\`. El formato es el mismo de macOS. Para trasladar una carrera, copiar su JSON con el juego cerrado y conservar el original. Guardar desde el juego antes de cerrar.

## Reproducir la exportación

Instalar Godot 4.4.1 estable y sus plantillas oficiales de la misma versión. Ejecutar:

```sh
python3 tools/build_windows.py --godot /ruta/al/ejecutable/godot
```

También admite `--template /ruta/windows_release_x86_64.exe` y `--output /directorio`. Usa una copia temporal que contiene solo sim, ui, visual, assets y data; no empaqueta partidas, pruebas, capturas, fuentes sincronizadas ni exportaciones anteriores. Incluye expresamente los JSON del atlas, catálogo, facciones y sprites. Conserva los resultados anteriores: no sobrescribe un paquete existente.

El ZIP incluye EXE, PCK separado, instrucciones, atribuciones, licencia GPL del proyecto elegida en el repositorio, licencia MIT de Godot y hashes SHA256. Las condiciones específicas de los datos derivados se describen en ATRIBUCIONES.md.

## Verificación

La exportación comprueba la versión del motor, el formato PE AMD64 y la presencia del paquete. `tests/export_smoke.gd` usa comprobaciones explícitas activas en builds release: catálogo, atlas, arte, progreso narrativo, guardar/cargar y cuatro pantallas. La prueba también puede cargar el PCK exportado en Godot macOS; esto verifica recursos y lógica, pero no demuestra ejecución del EXE Windows.

`.github/workflows/windows.yml` exporta y ejecuta la prueba sobre Windows en GitHub Actions; verifica SHA512 de las descargas oficiales antes de usarlas y publica el ZIP como artefacto solo si la prueba pasa. Puede ejecutarse manualmente desde Actions y se dispara al cambiar código en main.

Fuentes técnicas: [exportar para Windows](https://docs.godotengine.org/en/4.4/tutorials/export/exporting_for_windows.html) y [exportación de proyectos](https://docs.godotengine.org/en/4.4/tutorials/export/exporting_projects.html).

Resultado v0.37.0: [compilación y prueba nativa en Windows aprobadas](https://github.com/itomaselli/Battletech-Mercenary-Command/actions/runs/38185024270) para el commit e0d6317. La prueba fue headless; la interacción gráfica manual en Windows queda pendiente de pruebas de juego. [Descarga publicada](https://github.com/itomaselli/Battletech-Mercenary-Command/releases/tag/v0.37.0).

La v0.43 añade el encuentro autónomo y su prueba de exportación. Los paquetes actuales se generan desde Actions; la release v0.37 permanece como versión anterior.

[Descarga v0.43 y validación Windows aprobada](https://github.com/itomaselli/Battletech-Mercenary-Command/actions/runs/38206504255): en Artifacts, elegir `mercenary-command-windows-x64`. El artefacto contiene el ZIP portátil del juego; extraer también ese ZIP antes de abrir el EXE.
