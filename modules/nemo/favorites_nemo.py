import os
import subprocess
from gi.repository import Nemo, GObject

FAVORITES_BIN = "/usr/local/bin/favorites"


class FavoritesMenuProvider(GObject.GObject, Nemo.MenuProvider):

    def get_file_items(self, window, files):
        if not files:
            return []
        item = Nemo.MenuItem(
            name="FavoritesExtension::AddToFavorites",
            label="Añadir a Favoritos",
            tip="Añadir a la carpeta de Favoritos",
            icon="starred",
        )
        item.connect("activate", self._add_to_favorites, files)
        return [item]

    def _add_to_favorites(self, menu, files):
        if not os.path.isfile(FAVORITES_BIN):
            self._notify(
                "Favoritos — Error",
                "El núcleo 'favorites' no está instalado.",
                icon="dialog-error",
            )
            return

        for gfile in files:
            filepath = gfile.get_location().get_path()
            if not filepath:
                continue

            result = subprocess.run(
                [FAVORITES_BIN, "add", filepath],
                capture_output=True,
                text=True,
            )

            if result.returncode == 0:
                symlink_name = result.stdout.strip()
                if symlink_name:
                    self._notify("Añadido a Favoritos", symlink_name)
                else:
                    self._notify(
                        "Ya está en Favoritos",
                        os.path.basename(filepath),
                        icon="dialog-information",
                    )
            else:
                error = result.stderr.strip() or "Error desconocido"
                self._notify(
                    "Error al añadir favorito",
                    f"{os.path.basename(filepath)}: {error}",
                    icon="dialog-error",
                )

    def _notify(self, title, body, icon="starred"):
        subprocess.run(["notify-send", "-i", icon, title, body], check=False)
