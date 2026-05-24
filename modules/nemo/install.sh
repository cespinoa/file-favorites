#!/usr/bin/env bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "Este instalador requiere sudo"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXT_DIR="/usr/share/nemo-python/extensions"

# Verificar dependencia
if ! python3 -c "from gi.repository import Nemo" 2>/dev/null; then
    echo "→ Instalando nemo-python..."
    apt-get install -y nemo-python
fi

mkdir -p "$EXT_DIR"
install -m 644 "$SCRIPT_DIR/favorites_nemo.py" "$EXT_DIR/favorites_nemo.py"

echo "✓ Extensión Nemo instalada en $EXT_DIR/favorites_nemo.py"
echo "  Reinicia Nemo para activarla:"
echo "    nemo -q && nemo &"
