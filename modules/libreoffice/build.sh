#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
OUTPUT="favorites-libreoffice.oxt"

# Generar iconos si no existen
if [ ! -f icons/favorites_16.png ] || [ ! -f icons/favorites_26.png ]; then
    echo "→ Generando iconos..."
    python3 - <<'EOF'
import os, struct, zlib

def make_png(size):
    # PNG header
    sig = b'\x89PNG\r\n\x1a\n'

    def chunk(name, data):
        c = name + data
        return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)

    ihdr = chunk(b'IHDR', struct.pack('>IIBBBBB', size, size, 8, 2, 0, 0, 0))

    # Estrella dorada de 5 puntas sobre fondo transparente (RGBA)
    import math
    pixels = [(0, 0, 0, 0)] * (size * size)
    cx, cy = size / 2, size / 2
    r_out = size * 0.45
    r_in  = size * 0.18

    def star_points(n=5):
        pts = []
        for i in range(n * 2):
            angle = math.pi * i / n - math.pi / 2
            r = r_out if i % 2 == 0 else r_in
            pts.append((cx + r * math.cos(angle), cy + r * math.sin(angle)))
        return pts

    pts = star_points()

    def point_in_polygon(x, y, poly):
        inside = False
        n = len(poly)
        j = n - 1
        for i in range(n):
            xi, yi = poly[i]
            xj, yj = poly[j]
            if ((yi > y) != (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi) + xi):
                inside = not inside
            j = i
        return inside

    for py in range(size):
        for px in range(size):
            if point_in_polygon(px + 0.5, py + 0.5, pts):
                pixels[py * size + px] = (255, 200, 0, 255)  # dorado

    raw = b''
    for row in range(size):
        raw += b'\x00'
        for col in range(size):
            r, g, b, a = pixels[row * size + col]
            raw += bytes([r, g, b, a])

    idat = chunk(b'IDAT', zlib.compress(raw))
    iend = chunk(b'IEND', b'')
    return sig + ihdr + idat + iend

os.makedirs('icons', exist_ok=True)
for sz in (16, 26):
    with open(f'icons/favorites_{sz}.png', 'wb') as f:
        f.write(make_png(sz))
print('Iconos generados.')
EOF
fi

rm -f "$OUTPUT"
zip -r "$OUTPUT" META-INF/ Addons.xcu python/ icons/ description.xml
echo "✓ Generado: $OUTPUT"
