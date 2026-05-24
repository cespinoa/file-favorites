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

unopkg remove --shared org.favorites.libreoffice 2>/dev/null || true
if ! unopkg add --shared favorites-libreoffice.oxt 2>/dev/null; then
    echo "✗ Error al instalar la extensión" >&2
    exit 1
fi

echo "✓ Extensión instalada"
echo "  Reinicia LibreOffice para que el menú aparezca."
