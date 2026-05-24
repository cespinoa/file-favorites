#!/usr/bin/env bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "Este desinstalador requiere sudo"
    exit 1
fi

if unopkg list --shared 2>/dev/null | grep -q "org.favorites.libreoffice"; then
    unopkg remove --shared org.favorites.libreoffice
    echo "✓ Módulo LibreOffice eliminado"
    echo "  Reinicia LibreOffice para que el cambio surta efecto."
else
    echo "  Módulo LibreOffice no estaba instalado, nada que hacer."
fi
