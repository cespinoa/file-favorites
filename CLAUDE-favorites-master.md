# CLAUDE.md — favorites (proyecto completo)

## Visión general

Sistema modular de archivos favoritos para GNOME/Linux. Permite marcar
cualquier archivo como favorito desde cualquier aplicación, accediendo
a ellos desde una carpeta dedicada en Nautilus.

## Arquitectura

```
favorites/
├── CLAUDE.md                        ← este archivo
├── install.sh                       ← instalador maestro
├── README.md
│
├── core/                            ← núcleo (CLAUDE-favorites-core.md)
│   ├── favorites                    → /usr/local/bin/favorites
│   └── install.sh
│
├── modules/
│   ├── nautilus/                    ← módulo Nautilus (CLAUDE-favorites-nautilus.md)
│   │   ├── Añadir\ a\ Favoritos    → /usr/share/nautilus/scripts/
│   │   └── install.sh
│   │
│   └── libreoffice/                 ← módulo LibreOffice (CLAUDE-favorites-libreoffice.md)
│       ├── favorites-libreoffice.oxt
│       └── install.sh
```

## Principio de diseño

**El núcleo es la única fuente de verdad.** Los módulos son adaptadores
finos que traducen el contexto de su aplicación (archivo seleccionado en
Nautilus, documento activo en LibreOffice) a una llamada CLI al núcleo:

```bash
favorites add /ruta/archivo
```

Ningún módulo reimplementa lógica de symlinks, configuración, ni gestión
de la carpeta. Si mañana se añade un módulo para Thunar, VSCode, o cualquier
otra aplicación, solo necesita:
1. Obtener la ruta del archivo en contexto
2. Llamar a `favorites add <ruta>`
3. Mostrar el resultado al usuario en el estilo de su aplicación

## Flujo de instalación

```bash
sudo ./install.sh [--modules nautilus,libreoffice]
```

El instalador maestro:
1. Instala el núcleo (`core/install.sh`)
2. Instala los módulos seleccionados (por defecto: todos)
3. Informa al usuario que la carpeta se configurará en la primera ejecución

La configuración por usuario (`~/.config/favorites/config.ini`) se crea
automáticamente la primera vez que el usuario invoca cualquier módulo,
mediante un diálogo GTK4 para elegir o crear la carpeta de favoritos.

## install.sh maestro

```bash
#!/usr/bin/env bash
set -e

if [ "$EUID" -ne 0 ]; then
    echo "Este instalador requiere sudo"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES="nautilus libreoffice"

# Parsear --modules si se proporciona
for arg in "$@"; do
    case $arg in
        --modules=*) MODULES="${arg#*=}" ;;
    esac
done

# 1. Núcleo (siempre)
echo "→ Instalando núcleo..."
bash "$SCRIPT_DIR/core/install.sh"

# 2. Módulos seleccionados
IFS=',' read -ra MOD_LIST <<< "$MODULES"
for mod in "${MOD_LIST[@]}"; do
    mod="$(echo "$mod" | tr -d ' ')"
    if [ -d "$SCRIPT_DIR/modules/$mod" ]; then
        echo "→ Instalando módulo: $mod..."
        bash "$SCRIPT_DIR/modules/$mod/install.sh"
    else
        echo "⚠ Módulo desconocido: $mod (ignorado)"
    fi
done

echo ""
echo "✓ Instalación completada."
echo ""
echo "  La carpeta de Favoritos se configurará la primera vez que"
echo "  uses cualquiera de los módulos instalados."
```

## Desinstalación

```bash
# Núcleo
sudo rm /usr/local/bin/favorites

# Módulo Nautilus
sudo rm "/usr/share/nautilus/scripts/Añadir a Favoritos"

# Módulo LibreOffice
sudo unopkg remove --shared org.favorites.libreoffice

# Configuración de usuario (opcional, por usuario)
rm -rf ~/.config/favorites/
```

## Añadir un nuevo módulo

Para integrar una nueva aplicación:

1. Crear `modules/<nombre>/` con su `install.sh`
2. El módulo obtiene la ruta del archivo en el contexto de su aplicación
3. Llamar a `/usr/local/bin/favorites add <ruta>`
4. Interpretar la salida:
   - stdout con nombre → añadido correctamente
   - stdout vacío + exit 0 → ya era favorito
   - exit 2 → error (ver stderr)
5. Mostrar feedback al usuario en el estilo de la aplicación

## CLAUDE.md de cada componente

Cada componente tiene su propio CLAUDE.md con instrucciones detalladas:

- `core/CLAUDE.md` → núcleo, CLI, configuración, diálogo GTK4
- `modules/nautilus/CLAUDE.md` → script Nautilus, notify-send
- `modules/libreoffice/CLAUDE.md` → extensión .oxt, menú Archivo

Claude Code debe leer el CLAUDE.md del componente que esté desarrollando
antes de escribir código.
