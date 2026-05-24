#!/usr/bin/env bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "Este instalador requiere sudo"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES="nautilus,nemo,libreoffice"

for arg in "$@"; do
    case $arg in
        --modules=*) MODULES="${arg#*=}" ;;
    esac
done

echo "→ Instalando núcleo..."
bash "$SCRIPT_DIR/core/install.sh"

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
