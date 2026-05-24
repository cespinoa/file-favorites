#!/usr/bin/env bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "Este desinstalador requiere sudo"
    exit 1
fi

rm -f /usr/local/bin/favorites
echo "✓ Núcleo eliminado"
