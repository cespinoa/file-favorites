# CLAUDE.md — favorites-core

## Objetivo

Núcleo del sistema de favoritos. Proporciona la lógica central de gestión de
symlinks y configuración por usuario. Se instala en `/usr/local/bin/favorites`
y es invocado por todos los módulos (Nautilus, LibreOffice, etc.) mediante CLI.

## Entorno

- Ubuntu 26.04 / GNOME 50 / Python 3.14
- Instalación: `/usr/local/bin/favorites` (sistema, requiere sudo para instalar)
- Configuración: `~/.config/favorites/config.ini` (por usuario)
- Wayland

## Estructura del proyecto

```
favorites-core/
├── CLAUDE.md
├── favorites              # Script principal (va a /usr/local/bin/)
├── install.sh             # Instalador del núcleo
└── README.md
```

## CLI — Interfaz pública

El núcleo es invocable desde cualquier módulo:

```bash
favorites add /ruta/archivo.odt       # Añadir favorito
favorites check /ruta/archivo.odt     # ¿Ya es favorito? (exit 0 = sí, exit 1 = no)
favorites list                         # Listar favoritos (URIs una por línea)
favorites config                       # Mostrar configuración actual
favorites setup                        # Forzar asistente de configuración
```

Salida estándar: mensajes legibles para humanos.
Salida de error (stderr): errores técnicos.
Códigos de salida: 0 éxito, 1 no encontrado/no es favorito, 2 error.

## Configuración por usuario

### Archivo: `~/.config/favorites/config.ini`

```ini
[favorites]
folder = /home/carlos/Favoritos
```

### Primera ejecución

Si `~/.config/favorites/config.ini` no existe al invocar cualquier subcomando,
lanzar automáticamente el asistente de configuración antes de continuar.

El asistente (`_run_setup()`) hace:

1. Lanzar diálogo GTK4 para elegir o crear la carpeta de favoritos
2. Escribir `~/.config/favorites/config.ini`
3. Crear la carpeta si no existe
4. Configurar icono y bookmark en Nautilus

### Diálogo GTK4

```python
import gi
gi.require_version('Gtk', '4.0')
from gi.repository import Gtk, GLib, Gio

def run_folder_dialog():
    """
    Abre un FileChooserDialog GTK4 para seleccionar o crear
    la carpeta de favoritos. Devuelve la ruta elegida o None
    si el usuario cancela.
    """
    app = Gtk.Application(application_id="org.favorites.setup")

    chosen_path = [None]

    def on_activate(app):
        dialog = Gtk.FileChooserDialog(
            title="Carpeta de Favoritos",
            action=Gtk.FileChooserAction.SELECT_FOLDER,
        )
        dialog.set_application(app)
        dialog.add_button("Cancelar", Gtk.ResponseType.CANCEL)
        dialog.add_button("Seleccionar", Gtk.ResponseType.ACCEPT)
        dialog.set_current_folder(
            Gio.File.new_for_path(GLib.get_home_dir())
        )

        # Sugerir ~/Favoritos como nombre por defecto
        dialog.set_current_name("Favoritos")

        def on_response(dialog, response):
            if response == Gtk.ResponseType.ACCEPT:
                chosen_path[0] = dialog.get_file().get_path()
            dialog.destroy()
            app.quit()

        dialog.connect("response", on_response)
        dialog.present()

    app.connect("activate", on_activate)
    app.run([])
    return chosen_path[0]
```

**Nota:** GTK4 FileChooserDialog incluye botón "Nueva carpeta" nativo —
el usuario puede crear la carpeta directamente desde el diálogo.

## Lógica principal

### Estructura de datos

Los favoritos son symlinks en la carpeta configurada. No hay base de datos.
La carpeta ES la base de datos.

### Resolver nombre del symlink

```python
def resolve_symlink_name(filepath, favorites_dir):
    """
    Devuelve la ruta completa del symlink a crear.
    Si hay colisión de nombre, añade sufijo (directorio_padre).
    Si sigue colisionando, añade contador numérico.
    """
    name = os.path.basename(filepath)
    target = os.path.join(favorites_dir, name)

    if not os.path.lexists(target):
        return target

    # Colisión: sufijo con directorio padre
    parent = os.path.basename(os.path.dirname(filepath))
    stem, ext = os.path.splitext(name)
    new_name = f"{stem} ({parent}){ext}"
    target = os.path.join(favorites_dir, new_name)

    if not os.path.lexists(target):
        return target

    # Colisión persistente: añadir contador
    counter = 2
    while True:
        new_name = f"{stem} ({parent} {counter}){ext}"
        target = os.path.join(favorites_dir, new_name)
        if not os.path.lexists(target):
            return target
        counter += 1
```

### Comprobar si ya es favorito

```python
def is_favorite(filepath, favorites_dir):
    """
    Devuelve True si existe algún symlink en favorites_dir
    que apunte exactamente a filepath (comparación por realpath).
    """
    filepath = os.path.realpath(filepath)
    if not os.path.isdir(favorites_dir):
        return False
    for entry in os.scandir(favorites_dir):
        if entry.is_symlink():
            if os.path.realpath(entry.path) == filepath:
                return True
    return False
```

### Añadir favorito

```python
def cmd_add(filepath, config):
    favorites_dir = config["folder"]
    filepath = os.path.abspath(filepath)

    if not os.path.exists(filepath):
        print(f"Error: no existe '{filepath}'", file=sys.stderr)
        sys.exit(2)

    if is_favorite(filepath, favorites_dir):
        print(f"Ya está en favoritos: {os.path.basename(filepath)}")
        sys.exit(0)

    target = resolve_symlink_name(filepath, favorites_dir)
    os.symlink(filepath, target)
    print(os.path.basename(target))  # stdout: nombre del symlink creado
```

### Listar favoritos

```python
def cmd_list(config):
    favorites_dir = config["folder"]
    if not os.path.isdir(favorites_dir):
        sys.exit(0)
    for entry in sorted(os.scandir(favorites_dir), key=lambda e: e.name):
        if entry.is_symlink():
            real = os.path.realpath(entry.path)
            print(real)
```

## Configuración de la carpeta en GNOME

Ejecutar tras crear la carpeta:

```python
def setup_gnome_integration(folder_path):
    """Icono personalizado y bookmark en Nautilus."""

    # 1. Icono de estrella
    subprocess.run([
        "gio", "set", folder_path,
        "metadata::custom-icon-name", "starred"
    ], check=False)

    # 2. Bookmark en primera posición
    bookmarks_file = os.path.expanduser("~/.config/gtk-3.0/bookmarks")
    entry = f"file://{folder_path} ⭐ Favoritos\n"

    lines = []
    if os.path.exists(bookmarks_file):
        with open(bookmarks_file) as f:
            lines = f.readlines()

    # Eliminar entrada previa si existía
    lines = [l for l in lines if folder_path not in l]

    # Insertar al inicio
    lines.insert(0, entry)

    os.makedirs(os.path.dirname(bookmarks_file), exist_ok=True)
    with open(bookmarks_file, "w") as f:
        f.writelines(lines)
```

## Instalador — install.sh

```bash
#!/usr/bin/env bash
set -e

if [ "$EUID" -ne 0 ]; then
    echo "Este instalador requiere sudo"
    exit 1
fi

install -m 755 favorites /usr/local/bin/favorites

echo "✓ favorites instalado en /usr/local/bin/favorites"
echo "  La configuración por usuario se creará en la primera ejecución."
```

El instalador NO toca la configuración de usuario — eso es responsabilidad
de la primera ejecución de `favorites`.

## Notas

- El núcleo no envía notificaciones — eso es responsabilidad de cada módulo,
  que conoce su contexto (Nautilus usa notify-send, LibreOffice usa su propio
  sistema de mensajes)
- `favorites add` imprime en stdout el nombre del symlink creado, para que
  el módulo pueda usarlo en su notificación
- El núcleo es idempotente: llamarlo dos veces con el mismo archivo es seguro
- Symlinks rotos son visibles en rojo en Nautilus — el usuario los gestiona
  manualmente, que es el flujo deseado

## Entregables esperados

1. Script `favorites` completo y funcional
2. `install.sh`
3. `README.md` con referencia de comandos CLI y descripción de la arquitectura
