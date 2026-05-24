#!/usr/bin/env bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "Este instalador requiere sudo"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install -m 755 "$SCRIPT_DIR/favorites" /usr/local/bin/favorites

echo "✓ favorites instalado en /usr/local/bin/favorites"
echo "  La configuración por usuario se creará en la primera ejecución."
