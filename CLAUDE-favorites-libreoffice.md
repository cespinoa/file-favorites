# CLAUDE.md — favorites-libreoffice

## Objetivo

Extensión LibreOffice (.oxt) que añade la opción "Guardar en Favoritos" al
menú Archivo de Writer y Calc. Delega toda la lógica al núcleo `favorites`.
La opción solo está activa cuando el documento tiene una ruta asignada
(no documentos nuevos sin guardar).

## Dependencias

- `favorites` instalado en `/usr/local/bin/favorites` (favorites-core)
- LibreOffice 24.x o superior (Ubuntu 26.04 incluye LO 25.x)

## Entorno

- Ubuntu 26.04 / Python 3.14
- Instalación de la extensión: sistema (`/usr/lib/libreoffice/share/extensions/`)
  mediante `unopkg add --shared`

## Estructura del proyecto

```
favorites-libreoffice/
├── CLAUDE.md
├── META-INF/
│   └── manifest.xml
├── Addons.xcu               # Entrada en menú Archivo
├── python/
│   └── favorites_lo.py      # Lógica del comando UNO
├── icons/
│   ├── favorites_16.png     # 16x16 px, icono de estrella
│   └── favorites_26.png     # 26x26 px
├── description.xml
├── build.sh                 # Genera favorites-libreoffice.oxt
├── install.sh               # Instala la extensión a nivel sistema
└── README.md
```

## Archivos de la extensión

### META-INF/manifest.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<manifest:manifest
    xmlns:manifest="urn:oasis:names:tc:opendocument:xmlns:manifest:1.0">
  <manifest:file-entry
      manifest:media-type="application/vnd.sun.star.configuration-data"
      manifest:full-path="Addons.xcu"/>
  <manifest:file-entry
      manifest:media-type="application/vnd.sun.star.uno-component;type=Python"
      manifest:full-path="python/favorites_lo.py"/>
  <manifest:file-entry
      manifest:media-type="image/png"
      manifest:full-path="icons/favorites_16.png"/>
  <manifest:file-entry
      manifest:media-type="image/png"
      manifest:full-path="icons/favorites_26.png"/>
</manifest:manifest>
```

### description.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<description
    xmlns="http://openoffice.org/extensions/description/2006"
    xmlns:d="http://openoffice.org/extensions/description/2006">
  <identifier value="org.favorites.libreoffice"/>
  <version value="1.0"/>
  <display-name>
    <name lang="es">Guardar en Favoritos</name>
    <name lang="en">Save to Favorites</name>
  </display-name>
  <publisher>
    <name xlink:href="" lang="es">Carlos Espino</name>
  </publisher>
  <extension-description>
    <src lang="es" xlink:href=""/>
  </extension-description>
</description>
```

### Addons.xcu

Define la entrada en el menú Archivo de Writer y Calc, después de "Guardar todo"
y antes del separador de "Recargar".

```xml
<?xml version="1.0" encoding="UTF-8"?>
<oor:component-data
    xmlns:oor="http://openoffice.org/2001/registry"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    oor:name="Addons"
    oor:package="org.openoffice.Office">
  <node oor:name="AddonUI">

    <!-- Entrada en menú -->
    <node oor:name="OfficeMenuBarMerging">
      <node oor:name="org.favorites.libreoffice" oor:op="replace">

        <!-- Writer -->
        <node oor:name="org.favorites.libreoffice.writer" oor:op="replace">
          <prop oor:name="MergePoint" oor:type="xs:string">
            <value>.uno:ToolsMenu\.uno:Macros</value>
          </prop>
          <prop oor:name="MergeCommand" oor:type="xs:string">
            <value>AddBefore</value>
          </prop>
          <prop oor:name="MergeFallback" oor:type="xs:string">
            <value>AddPath</value>
          </prop>
          <prop oor:name="MergeContext" oor:type="xs:string">
            <value>com.sun.star.text.TextDocument</value>
          </prop>
          <node oor:name="MenuItems">
            <node oor:name="favorites.AddToFavorites" oor:op="replace">
              <prop oor:name="URL" oor:type="xs:string">
                <value>service:org.favorites.libreoffice.FavoritesService?add</value>
              </prop>
              <prop oor:name="Title" oor:type="xs:string">
                <value xml:lang="es">Guardar en Favoritos</value>
                <value xml:lang="en">Save to Favorites</value>
              </prop>
              <prop oor:name="ImageIdentifier" oor:type="xs:string">
                <value>favorites_16</value>
              </prop>
              <prop oor:name="Context" oor:type="xs:string">
                <value>com.sun.star.text.TextDocument</value>
              </prop>
            </node>
          </node>
        </node>

        <!-- Calc -->
        <node oor:name="org.favorites.libreoffice.calc" oor:op="replace">
          <prop oor:name="MergePoint" oor:type="xs:string">
            <value>.uno:ToolsMenu\.uno:Macros</value>
          </prop>
          <prop oor:name="MergeCommand" oor:type="xs:string">
            <value>AddBefore</value>
          </prop>
          <prop oor:name="MergeFallback" oor:type="xs:string">
            <value>AddPath</value>
          </prop>
          <prop oor:name="MergeContext" oor:type="xs:string">
            <value>com.sun.star.sheet.SpreadsheetDocument</value>
          </prop>
          <node oor:name="MenuItems">
            <node oor:name="favorites.AddToFavorites.calc" oor:op="replace">
              <prop oor:name="URL" oor:type="xs:string">
                <value>service:org.favorites.libreoffice.FavoritesService?add</value>
              </prop>
              <prop oor:name="Title" oor:type="xs:string">
                <value xml:lang="es">Guardar en Favoritos</value>
                <value xml:lang="en">Save to Favorites</value>
              </prop>
              <prop oor:name="ImageIdentifier" oor:type="xs:string">
                <value>favorites_16</value>
              </prop>
              <prop oor:name="Context" oor:type="xs:string">
                <value>com.sun.star.sheet.SpreadsheetDocument</value>
              </prop>
            </node>
          </node>
        </node>

      </node>
    </node>
  </node>
</oor:component-data>
```

**Nota:** El MergePoint usa el menú Herramientas como referencia. Si Claude Code
necesita ajustar la posición exacta en el menú Archivo, consultar la referencia
de UNO commands en https://wiki.documentfoundation.org/Development/DispatchCommands

### python/favorites_lo.py

```python
# favorites_lo.py — componente Python UNO para LibreOffice
# Implementa el comando "Guardar en Favoritos"

import os
import subprocess
import uno
import unohelper
from com.sun.star.task import XJobExecutor

FAVORITES_BIN = "/usr/local/bin/favorites"
IMPLEMENTATION_NAME = "org.favorites.libreoffice.FavoritesService"
SERVICE_NAME = "org.favorites.libreoffice.FavoritesService"


def get_active_doc_path(ctx):
    """
    Devuelve la ruta del sistema de archivos del documento activo,
    o None si no tiene ruta asignada (documento nuevo sin guardar).
    """
    try:
        desktop = ctx.ServiceManager.createInstanceWithContext(
            "com.sun.star.frame.Desktop", ctx
        )
        doc = desktop.getCurrentComponent()
        if doc is None:
            return None
        url = doc.getURL()
        if not url:
            return None  # Sin guardar
        return uno.fileUrlToSystemPath(url)
    except Exception:
        return None


def show_message(ctx, title, message, is_error=False):
    """Muestra un cuadro de mensaje usando el API de LibreOffice."""
    try:
        toolkit = ctx.ServiceManager.createInstanceWithContext(
            "com.sun.star.awt.Toolkit", ctx
        )
        msgbox = toolkit.createMessageBox(
            None,
            uno.Enum("com.sun.star.awt.MessageBoxType",
                     "ERRORBOX" if is_error else "INFOBOX"),
            1,
            title,
            message
        )
        msgbox.execute()
    except Exception:
        pass  # Si falla el diálogo, continuar silenciosamente


class FavoritesService(unohelper.Base, XJobExecutor):
    """Servicio UNO que implementa el comando Guardar en Favoritos."""

    def __init__(self, ctx):
        self.ctx = ctx

    def trigger(self, args):
        """Punto de entrada del comando."""

        # Verificar que el núcleo está instalado
        if not os.path.isfile(FAVORITES_BIN):
            show_message(
                self.ctx,
                "Favoritos — Error",
                "El núcleo 'favorites' no está instalado.\n"
                "Ejecuta el instalador de favorites-core.",
                is_error=True
            )
            return

        # Obtener ruta del documento activo
        filepath = get_active_doc_path(self.ctx)

        if filepath is None:
            show_message(
                self.ctx,
                "Favoritos",
                "El documento no tiene nombre asignado.\n"
                "Guárdalo primero antes de añadirlo a Favoritos."
            )
            return

        # Llamar al núcleo
        result = subprocess.run(
            [FAVORITES_BIN, "add", filepath],
            capture_output=True,
            text=True
        )

        if result.returncode == 0:
            symlink_name = result.stdout.strip()
            if symlink_name:
                show_message(
                    self.ctx,
                    "Favoritos",
                    f"Añadido a Favoritos:\n{symlink_name}"
                )
            else:
                show_message(
                    self.ctx,
                    "Favoritos",
                    f"Ya está en Favoritos:\n{os.path.basename(filepath)}"
                )
        else:
            error = result.stderr.strip() or "Error desconocido"
            show_message(
                self.ctx,
                "Favoritos — Error",
                f"No se pudo añadir a Favoritos:\n{error}",
                is_error=True
            )


def createInstance(ctx):
    return FavoritesService(ctx)


g_ImplementationHelper = unohelper.ImplementationHelper()
g_ImplementationHelper.addImplementation(
    createInstance,
    IMPLEMENTATION_NAME,
    (SERVICE_NAME,)
)
```

## Estado de la opción de menú (habilitado/deshabilitado)

LibreOffice no ofrece un mecanismo sencillo para deshabilitar entradas de menú
de extensiones en tiempo real. La aproximación correcta es:

- La opción aparece **siempre** en el menú
- Si el documento no tiene ruta, muestra un mensaje explicativo en lugar
  de realizar la acción

Esto es más robusto que intentar gestionar el estado enabled/disabled,
que requeriría implementar `XDispatch` con `addStatusListener`, añadiendo
complejidad considerable.

## Iconos

Crear dos iconos PNG simples con una estrella dorada:
- `icons/favorites_16.png` — 16×16 px
- `icons/favorites_26.png` — 26×26 px

Si no se dispone de herramientas de diseño, Claude Code puede generarlos
programáticamente con Pillow:

```python
from PIL import Image, ImageDraw

def create_star_icon(size):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    # dibujar estrella dorada de 5 puntas
    # ...
    return img
```

O simplemente copiar el icono `starred` del tema Yaru si existe:
```bash
find /usr/share/icons/Yaru -name "starred*" | head -5
```

## build.sh

```bash
#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
OUTPUT="favorites-libreoffice.oxt"
rm -f "$OUTPUT"
zip -r "$OUTPUT" META-INF/ Addons.xcu python/ icons/ description.xml
echo "✓ Generado: $OUTPUT"
```

## install.sh

```bash
#!/usr/bin/env bash
set -e

if [ "$EUID" -ne 0 ]; then
    echo "Este instalador requiere sudo"
    exit 1
fi

cd "$(dirname "$0")"

# Construir si no existe
if [ ! -f favorites-libreoffice.oxt ]; then
    bash build.sh
fi

# Instalar a nivel sistema (disponible para todos los usuarios)
unopkg add --shared --force favorites-libreoffice.oxt

echo "✓ Extensión instalada"
echo "  Reinicia LibreOffice para que el menú aparezca."
```

## Notas

- La extensión delega toda la lógica al núcleo — no gestiona la carpeta
  ni la configuración de usuario
- Si el núcleo lanza el diálogo GTK4 de configuración (primera vez), aparecerá
  antes del mensaje de LibreOffice — es el comportamiento esperado
- `unopkg add --shared` instala para todos los usuarios del sistema
- Testear con `unopkg list --shared` para verificar el registro
- En caso de problemas, los logs de LO están en `~/.config/libreoffice/*/user/registrymodifications.xcu`

## Entregables esperados

1. Todos los archivos del proyecto listos para empaquetar
2. `build.sh` que genera el `.oxt`
3. `install.sh` que instala a nivel sistema
4. `README.md` con instrucciones de uso y desinstalación
