# CLAUDE.md — Favoritos con symlinks en Nautilus

## Objetivo

Script de Nautilus que permite marcar cualquier archivo como favorito con clic
derecho. Los favoritos se almacenan como symlinks en `~/Favoritos/`, carpeta
visible en el panel lateral de Nautilus con icono de estrella.

## Entorno

- Ubuntu 26.04 / GNOME 50 / Nautilus 50
- Python 3.14
- Wayland (sin X11)
- Usuario: carlos, home: /home/carlos

## Arquitectura

Un único script Python en:
```
~/.local/share/nautilus/scripts/Añadir a Favoritos
```

El script hace todo: instala la carpeta en la primera ejecución y crea el symlink.
No hay demonio, no hay base de datos, no hay dependencias externas.

## Comportamiento del script

### 1. Comprobación y creación de ~/Favoritos (cada ejecución)

Siempre al inicio, antes de cualquier otra acción:

```python
FAVORITES_DIR = os.path.expanduser("~/Favoritos")

if not os.path.exists(FAVORITES_DIR):
    os.makedirs(FAVORITES_DIR)
    setup_favorites_folder()
```

`setup_favorites_folder()` hace dos cosas:

**a) Icono personalizado:**
```python
subprocess.run([
    "gio", "set", FAVORITES_DIR,
    "metadata::custom-icon-name", "starred"
])
```

**b) Añadir al inicio de bookmarks:**
```python
bookmarks_file = os.path.expanduser("~/.config/gtk-3.0/bookmarks")
entry = f"file://{FAVORITES_DIR} ⭐ Favoritos\n"

# Leer contenido actual
lines = []
if os.path.exists(bookmarks_file):
    with open(bookmarks_file) as f:
        lines = f.readlines()

# Eliminar si ya existía (evitar duplicados)
lines = [l for l in lines if FAVORITES_DIR not in l]

# Insertar en primera posición
lines.insert(0, entry)

with open(bookmarks_file, "w") as f:
    f.writelines(lines)
```

### 2. Resolución de nombre del symlink

El nombre del symlink es el nombre del archivo. Si ya existe un symlink con
ese nombre en `~/Favoritos/`, añadir sufijo con el nombre del directorio padre:

```python
def resolve_symlink_name(filepath):
    name = os.path.basename(filepath)
    target = os.path.join(FAVORITES_DIR, name)

    if not os.path.exists(target) and not os.path.islink(target):
        return target

    # Colisión: añadir sufijo con directorio padre
    parent = os.path.basename(os.path.dirname(filepath))
    stem, ext = os.path.splitext(name)
    new_name = f"{stem} ({parent}){ext}"
    return os.path.join(FAVORITES_DIR, new_name)
```

Si con el sufijo también colisiona (caso muy raro), añadir contador: `(parent 2)`.

### 3. Crear el symlink

```python
def add_favorite(filepath):
    filepath = os.path.abspath(filepath)
    target = resolve_symlink_name(filepath)
    os.symlink(filepath, target)
    return os.path.basename(target)
```

### 4. Entrada desde Nautilus

Nautilus pasa los archivos seleccionados en `NAUTILUS_SCRIPT_SELECTED_FILE_PATHS`,
uno por línea:

```python
paths_raw = os.environ.get("NAUTILUS_SCRIPT_SELECTED_FILE_PATHS", "")
paths = [p for p in paths_raw.strip().split("\n") if p.strip()]
```

### 5. Notificación

Usar `notify-send` para confirmar la acción:

```python
def notify(title, body):
    subprocess.run(["notify-send", "-i", "starred", title, body],
                   check=False)
```

- Éxito: "Añadido a Favoritos" + nombre del symlink creado
- Ya existe: "Ya está en Favoritos" + nombre del archivo
- Error: "Error al añadir favorito" + descripción

### 6. Detección de ya existente

Antes de crear el symlink, comprobar si ya hay un symlink en `~/Favoritos/`
que apunte exactamente al mismo archivo:

```python
def is_already_favorite(filepath):
    filepath = os.path.abspath(filepath)
    for entry in os.scandir(FAVORITES_DIR):
        if entry.is_symlink() and os.path.realpath(entry.path) == filepath:
            return True
    return False
```

## Estructura completa del script

```python
#!/usr/bin/env python3
# ~/.local/share/nautilus/scripts/Añadir a Favoritos

import os
import subprocess

FAVORITES_DIR = os.path.expanduser("~/Favoritos")

def notify(title, body):
    ...

def setup_favorites_folder():
    # gio set icono + bookmarks
    ...

def is_already_favorite(filepath):
    ...

def resolve_symlink_name(filepath):
    ...

def add_favorite(filepath):
    ...

def main():
    # 1. Asegurar que ~/Favoritos existe
    if not os.path.exists(FAVORITES_DIR):
        os.makedirs(FAVORITES_DIR)
        setup_favorites_folder()

    # 2. Leer archivos seleccionados
    paths_raw = os.environ.get("NAUTILUS_SCRIPT_SELECTED_FILE_PATHS", "")
    paths = [p for p in paths_raw.strip().split("\n") if p.strip()]

    if not paths:
        notify("Favoritos", "No se seleccionó ningún archivo")
        return

    # 3. Procesar cada archivo
    for filepath in paths:
        if is_already_favorite(filepath):
            notify("Ya está en Favoritos", os.path.basename(filepath))
            continue
        name = add_favorite(filepath)
        notify("Añadido a Favoritos", name)

if __name__ == "__main__":
    main()
```

## Instalación

```bash
SCRIPT_DIR=~/.local/share/nautilus/scripts
mkdir -p "$SCRIPT_DIR"
cp "Añadir a Favoritos" "$SCRIPT_DIR/"
chmod +x "$SCRIPT_DIR/Añadir a Favoritos"
```

Nautilus recarga los scripts sin necesidad de reinicio.

## Notas

- Los symlinks rotos (archivo movido o eliminado) aparecen en rojo en Nautilus —
  el usuario los elimina manualmente desde ~/Favoritos, que es el flujo deseado
- El script NO elimina favoritos — eso se hace borrando el symlink desde Nautilus
- Funciona con cualquier tipo de archivo: .odt, .ods, .pdf, scripts, etc.
- No requiere que Nautilus esté abierto para funcionar (aunque el clic derecho
  implica que sí lo está)
- `notify-send` requiere el paquete `libnotify-bin` (preinstalado en Ubuntu)

## Entregables esperados

1. Script completo y funcional `Añadir a Favoritos`
2. `install.sh` que copia el script, lo hace ejecutable, crea `~/Favoritos`
   y configura icono y bookmark si la carpeta no existía
3. `README.md` con instrucciones de uso y desinstalación
