import os
import subprocess
import uno
import unohelper
from com.sun.star.task import XJobExecutor

FAVORITES_BIN = "/usr/local/bin/favorites"
IMPLEMENTATION_NAME = "org.favorites.libreoffice.FavoritesService"
SERVICE_NAME = "org.favorites.libreoffice.FavoritesService"


def get_active_doc_path(ctx):
    try:
        desktop = ctx.ServiceManager.createInstanceWithContext(
            "com.sun.star.frame.Desktop", ctx
        )
        doc = desktop.getCurrentComponent()
        if doc is None:
            return None
        url = doc.getURL()
        if not url:
            return None
        return uno.fileUrlToSystemPath(url)
    except Exception:
        return None


def show_message(ctx, title, message, is_error=False):
    try:
        toolkit = ctx.ServiceManager.createInstanceWithContext(
            "com.sun.star.awt.Toolkit", ctx
        )
        msgbox = toolkit.createMessageBox(
            None,
            uno.Enum(
                "com.sun.star.awt.MessageBoxType",
                "ERRORBOX" if is_error else "INFOBOX",
            ),
            1,
            title,
            message,
        )
        msgbox.execute()
    except Exception:
        pass


class FavoritesService(unohelper.Base, XJobExecutor):

    def __init__(self, ctx):
        self.ctx = ctx

    def trigger(self, args):
        if not os.path.isfile(FAVORITES_BIN):
            show_message(
                self.ctx,
                "Favoritos — Error",
                "El núcleo 'favorites' no está instalado.\n"
                "Ejecuta el instalador de favorites-core.",
                is_error=True,
            )
            return

        filepath = get_active_doc_path(self.ctx)

        if filepath is None:
            show_message(
                self.ctx,
                "Favoritos",
                "El documento no tiene nombre asignado.\n"
                "Guárdalo primero antes de añadirlo a Favoritos.",
            )
            return

        result = subprocess.run(
            [FAVORITES_BIN, "add", filepath],
            capture_output=True,
            text=True,
        )

        if result.returncode == 0:
            symlink_name = result.stdout.strip()
            if symlink_name:
                show_message(self.ctx, "Favoritos", f"Añadido a Favoritos:\n{symlink_name}")
            else:
                show_message(
                    self.ctx,
                    "Favoritos",
                    f"Ya está en Favoritos:\n{os.path.basename(filepath)}",
                )
        else:
            error = result.stderr.strip() or "Error desconocido"
            show_message(
                self.ctx,
                "Favoritos — Error",
                f"No se pudo añadir a Favoritos:\n{error}",
                is_error=True,
            )


def createInstance(ctx):
    return FavoritesService(ctx)


g_ImplementationHelper = unohelper.ImplementationHelper()
g_ImplementationHelper.addImplementation(
    createInstance,
    IMPLEMENTATION_NAME,
    (SERVICE_NAME,),
)
