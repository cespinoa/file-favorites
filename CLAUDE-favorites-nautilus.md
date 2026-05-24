# CLAUDE.md — favorites-nautilus

## Objetivo

Script de Nautilus que permite añadir cualquier archivo a favoritos con clic
derecho → Scripts → "Añadir a Favoritos". Delega toda la lógica al núcleo
`favorites`. Su única responsabilidad es leer los archivos seleccionados,
llamar al núcleo, y mostrar la notificación de resultado.

## Dependencias

- `favorites` instalado en `/usr/local/bin/favorites` (favorites-core)
- `libnotify-bin` (notify-send, preinstalado en Ubuntu 26.04)

## Entorno

- Ubuntu 26.04 / GNOME 50 / Nautilus 50
- Python 3.14
- Instalación del script: `/usr/share/nautilus/scripts/` (sistema)
  Nautilus busca scripts también en `~/.local/share/nautilus/scripts/` (usuario)
  La instalación de sistema hace que esté disponible para todos los usuarios.

## Estructura del proyecto

```
favorites-nautilus/
├── CLAUDE.md
├── Añadir\ a\ Favoritos    # Script Python ejecutable
├── install.sh
└── README.md
```

## Comportamiento

1. Leer `NAUTILUS_SCRIPT_SELECTED_FILE_PATHS` (una ruta por línea)
2. Para cada archivo, llamar a `favorites add <ruta>`
3. Mostrar notificación con el resultado

Nautilus puede pasar múltiples archivos si el usuario selecciona varios
antes de hacer clic derecho. El script los procesa todos.

## Código completo

```python
#!/usr/bin/env python3
# Añadir a Favoritos — script de Nautilus
# Requiere: favorites (favorites-core) en /usr/local/bin/

import os
import subprocess
import sys

FAVORITES_BIN = "/usr/local/bin/favorites"


def notify(title, body, icon="starred"):
    subprocess.run(
        ["notify-send", "-i", icon, title, body],
        check=False
    )


def check_core():
    """Verificar que el núcleo está instalado."""
    if not os.path.isfile(FAVORITES_BIN):
        notify(
            "Favoritos — Error",
            "El núcleo 'favorites' no está instalado.\n"
            "Ejecuta el instalador de favorites-core.",
            icon="dialog-error"
        )
        sys.exit(2)


def main():
    check_core()

    paths_raw = os.environ.get("NAUTILUS_SCRIPT_SELECTED_FILE_PATHS", "")
    paths = [p for p in paths_raw.strip().split("\n") if p.strip()]

    if not paths:
        notify("Favoritos", "No se seleccionó ningún archivo", icon="dialog-warning")
        return

    for filepath in paths:
        result = subprocess.run(
            [FAVORITES_BIN, "add", filepath],
            capture_output=True,
            text=True
        )

        if result.returncode == 0:
            symlink_name = result.stdout.strip()
            if symlink_name:
                notify("Añadido a Favoritos", symlink_name)
            else:
                # Ya estaba en favoritos (núcleo salió con 0 pero sin nombre)
                notify(
                    "Ya está en Favoritos",
                    os.path.basename(filepath),
                    icon="dialog-information"
                )
        else:
            error = result.stderr.strip() or "Error desconocido"
            notify(
                "Error al añadir favorito",
                f"{os.path.basename(filepath)}: {error}",
                icon="dialog-error"
            )


if __name__ == "__main__":
    main()
```

## Instalador — install.sh

```bash
#!/usr/bin/env bash
set -e

if [ "$EUID" -ne 0 ]; then
    echo "Este instalador requiere sudo"
    exit 1
fi

SCRIPT_NAME="Añadir a Favoritos"
SYSTEM_SCRIPTS="/usr/share/nautilus/scripts"

mkdir -p "$SYSTEM_SCRIPTS"
install -m 755 "$SCRIPT_NAME" "$SYSTEM_SCRIPTS/$SCRIPT_NAME"

echo "✓ Script Nautilus instalado en $SYSTEM_SCRIPTS/$SCRIPT_NAME"
echo "  Disponible en Nautilus: clic derecho → Scripts → 'Añadir a Favoritos'"
echo ""
echo "  Nota: si Nautilus está abierto, ciérralo y vuélvelo a abrir"
echo "  para que detecte el nuevo script."
```

## Notas

- El script NO gestiona la configuración de usuario ni la carpeta ~/Favoritos —
  eso lo hace el núcleo en la primera ejecución
- Si el núcleo lanza el diálogo GTK4 de configuración (primera vez), aparecerá
  antes de la notificación — es el comportamiento esperado
- La instalación en `/usr/share/nautilus/scripts/` hace el script disponible
  para todos los usuarios del sistema
- Nautilus 50 muestra los scripts en el submenú "Scripts" del menú contextual

## Entregables esperados

1. Script `Añadir a Favoritos` completo
2. `install.sh`
3. `README.md`
