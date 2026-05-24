#!/usr/bin/env bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "Este instalador requiere sudo"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ ! -f favorites-libreoffice.oxt ]; then
    echo "→ Construyendo extensión..."
    bash build.sh
fi

unopkg add --shared --force favorites-libreoffice.oxt

echo "✓ Extensión instalada"
echo "  Reinicia LibreOffice para que el menú aparezca."
