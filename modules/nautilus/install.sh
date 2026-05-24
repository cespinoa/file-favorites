#!/usr/bin/env bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "Este instalador requiere sudo"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXT_DIR="/usr/share/nautilus-python/extensions"

# Verificar dependencia
if ! python3 -c "from gi.repository import Nautilus" 2>/dev/null; then
    echo "→ Instalando python3-nautilus..."
    apt-get install -y python3-nautilus
fi

# Instalar extensión
mkdir -p "$EXT_DIR"
install -m 644 "$SCRIPT_DIR/favorites_nautilus.py" "$EXT_DIR/favorites_nautilus.py"

# Eliminar el script antiguo si existía
rm -f "/usr/share/nautilus/scripts/Añadir a Favoritos"
rm -f "$HOME/.local/share/nautilus/scripts/Añadir a Favoritos"

echo "✓ Extensión Nautilus instalada en $EXT_DIR/favorites_nautilus.py"
echo "  Reinicia Nautilus para activarla:"
echo "    nautilus -q && nautilus &"
