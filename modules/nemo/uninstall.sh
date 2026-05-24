#!/usr/bin/env bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "Este desinstalador requiere sudo"
    exit 1
fi

rm -f /usr/share/nemo-python/extensions/favorites_nemo.py
echo "✓ Módulo Nemo eliminado"
echo "  Reinicia Nemo para que el cambio surta efecto:"
echo "    nemo -q && nemo &"
