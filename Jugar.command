#!/bin/zsh
cd -- "${0:A:h}"
for engine in /Applications/Godot.app/Contents/MacOS/Godot /tmp/mercenary-godot/Godot.app/Contents/MacOS/Godot; do
  if [[ -x "$engine" ]]; then
    exec "$engine" --path .
  fi
done
if command -v godot >/dev/null 2>&1; then
  exec godot --path .
fi
print 'Instala Godot 4.4.1 o posterior e importa project.godot. Consulta README.md.'
read '?Pulsa Enter para cerrar.'
