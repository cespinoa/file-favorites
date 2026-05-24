#!/usr/bin/env bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "Este desinstalador requiere sudo"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES="nautilus,nemo,libreoffice"
PURGE=false

for arg in "$@"; do
    case $arg in
        --modules=*) MODULES="${arg#*=}" ;;
        --purge)     PURGE=true ;;
    esac
done

# Módulos primero, luego el núcleo
IFS=',' read -ra MOD_LIST <<< "$MODULES"
for mod in "${MOD_LIST[@]}"; do
    mod="$(echo "$mod" | tr -d ' ')"
    if [ -d "$SCRIPT_DIR/modules/$mod" ]; then
        echo "→ Desinstalando módulo: $mod..."
        bash "$SCRIPT_DIR/modules/$mod/uninstall.sh"
    else
        echo "⚠ Módulo desconocido: $mod (ignorado)"
    fi
done

echo "→ Desinstalando núcleo..."
bash "$SCRIPT_DIR/core/uninstall.sh"

# Configuración de usuario (requiere --purge)
if [ "$PURGE" = true ]; then
    CONFIG="$HOME/.config/favorites"
    if [ -d "$CONFIG" ]; then
        rm -rf "$CONFIG"
        echo "✓ Configuración de usuario eliminada ($CONFIG)"
    fi
fi

echo ""
echo "✓ Desinstalación completada."
if [ "$PURGE" = false ]; then
    echo ""
    echo "  La configuración de usuario (~/.config/favorites/) se ha conservado."
    echo "  Para eliminarla también: sudo ./uninstall.sh --purge"
fi
