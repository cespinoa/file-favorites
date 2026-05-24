# file-favorites

Mark any file as a favorite with a right-click. Favorites are stored as symlinks
in a dedicated folder (`~/Favoritos/` by default) that appears in the file manager
sidebar with a star icon.

Works with **Nautilus**, **Nemo**, and **LibreOffice**.

---

## How it works

A small CLI core (`favorites`) handles all the logic: symlink creation, collision
resolution, and first-run configuration. File manager and application integrations
are thin modules that call `favorites add <path>` and display the result.

No daemon. No database. The folder *is* the database.

```
favorites/
├── core/
│   ├── favorites               → /usr/local/bin/favorites
│   └── install.sh
└── modules/
    ├── nautilus/               → right-click menu in Nautilus
    ├── nemo/                   → right-click menu in Nemo
    └── libreoffice/            → File menu in Writer and Calc
```

## Requirements

- Linux with GNOME or Cinnamon desktop
- Python 3.10+
- `libnotify-bin` (pre-installed on Ubuntu)
- `python3-nautilus` (auto-installed by the Nautilus module)
- `nemo-python` (auto-installed by the Nemo module)
- LibreOffice 7+ (for the LibreOffice module)

## Installation

```bash
git clone https://github.com/cespinoa/file-favorites.git
cd file-favorites
sudo ./install.sh
```

Install specific modules only:

```bash
sudo ./install.sh --modules=nautilus
sudo ./install.sh --modules=nemo
sudo ./install.sh --modules=nautilus,libreoffice
```

On first use, a GTK4 dialog will ask you to choose or create your favorites folder.

## Usage

### Nautilus / Nemo

Right-click any file or selection → **Añadir a Favoritos**

### LibreOffice Writer / Calc

**Tools → Guardar en Favoritos** (document must be saved first)

### CLI

```bash
favorites add /path/to/file      # Add to favorites
favorites check /path/to/file    # Is it a favorite? (exit 0 = yes)
favorites list                   # List all favorites (real paths)
favorites config                 # Show current configuration
favorites setup                  # Re-run the setup wizard
```

## Name collision handling

If two files share the same name, the second symlink gets the parent directory
as a suffix:

```
report.pdf
report (ProjectX).pdf
report (ProjectX 2).pdf
```

## Uninstall

```bash
# Core
sudo rm /usr/local/bin/favorites

# Nautilus module
sudo rm /usr/share/nautilus-python/extensions/favorites_nautilus.py

# Nemo module
sudo rm /usr/share/nemo-python/extensions/favorites_nemo.py

# LibreOffice module
sudo unopkg remove --shared org.favorites.libreoffice

# User configuration (optional)
rm -rf ~/.config/favorites/
```

Broken symlinks (file moved or deleted) appear in red in the file manager — 
delete them manually from your favorites folder.

## License

MIT
