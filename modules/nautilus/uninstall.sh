#!/usr/bin/env bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "Este desinstalador requiere sudo"
    exit 1
fi

rm -f /usr/share/nautilus-python/extensions/favorites_nautilus.py
echo "✓ Módulo Nautilus eliminado"
echo "  Reinicia Nautilus para que el cambio surta efecto:"
echo "    nautilus -q && nautilus &"
