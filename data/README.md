# Procedencia de datos

`atlas.json`: Sarna Unified Cartography Kit (Official), obtenido del repositorio https://github.com/sarna-net/sarna-maps. Importador reproducible en `tools/import_atlas.py`; hash y cobertura en `docs/atlas-audit.json`. Coordenadas: 3.175 registros de sistemas. Afiliaciones: referencia 3025 para escenario 3027 y 3059d para 3060. No se afirman fronteras exactas de esos escenarios. Las afiliaciones se congelan durante cada campaña.

`factions.json`: selección original de 15 entidades con enlaces de referencia a Sarna. Disponibilidad pública según escenario. Los datos de atlas incluyen otras afiliaciones sin convertirlas en actores simulados.

`units.json`: campos factuales extraídos de archivos MTF/BLK de https://github.com/MegaMek/mm-data. Cada registro conserva URL y SHA256; se excluyeron descripciones narrativas, ilustraciones y código. MegaMek Data (C) 2025–2026 The MegaMek Team, licencia **CC BY-NC-SA 4.0**: https://creativecommons.org/licenses/by-nc-sa/4.0/ . Este catálogo derivado conserva esa licencia. BattleTech pertenece a sus respectivos titulares; proyecto personal no oficial, sin afiliación. El juego no ejecuta ni necesita MekHQ/MegaMek.

Los campos `year`, `mass`, `walk`, `jump`, `weapons`, `role`, `tech` y `motion` proceden de esos registros. `profile`, `value`, `maintenance`, `crew` y `sprite` son parámetros originales simplificados del prototipo, no reglas ni precios oficiales. Las dotaciones son grupos agregados de cuatro integrantes. Striker es de ruedas; los otros siete vehículos seleccionados son de orugas. Se conserva ese modo de movilidad en la ficha.

48 variantes de 24 chasis Mech y ocho vehículos, todos introducidos hasta 3060; no es un catálogo exhaustivo de BattleTech. Los 56 sprites se dibujan mediante máscaras originales, distintas por modelo, en `visual/unit_sprites.json`. Referencias de siluetas y armamento: Sarna; enlaces concretos en `docs/unit-art-references.json`. No se distribuyen las ilustraciones de referencia. El antiguo campo numérico `sprite` se conserva para compatibilidad, pero la UI obtiene el arte por `id`.
