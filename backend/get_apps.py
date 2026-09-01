import subprocess
import sys, base64, configparser, os
from pathlib import Path

from pydantic.main import BaseModel

from subproc import clean_env

def _exe_icon_b64(exe: str):
    try:
        import win32ui, win32gui, win32con, io
        from PIL import Image
        large, _ = win32gui.ExtractIconEx(exe, 0)
        if not large:
            return None
        hicon = large[0]
        for h in large[1:]:
            win32gui.DestroyIcon(h)
        hdc = win32ui.CreateDCFromHandle(win32gui.GetDC(0))
        hbmp = win32ui.CreateBitmap()
        s = 64
        hbmp.CreateCompatibleBitmap(hdc, s, s)
        mdc = hdc.CreateCompatibleDC()
        mdc.SelectObject(hbmp)
        mdc.DrawIcon((0, 0), hicon)
        win32gui.DestroyIcon(hicon)
        bits = hbmp.GetBitmapBits(True)
        im = Image.frombuffer('RGBA', (s, s), bits, 'raw', 'BGRA', 0, 1)
        buf = io.BytesIO(); im.save(buf, 'PNG')
        return base64.b64encode(buf.getvalue()).decode()
    except Exception:
        return None

def _png_b64(path: str):
    try:
        if path.lower().endswith('.svg'):
            import cairosvg
            data = cairosvg.svg2png(url=path, output_width=128, output_height=128)
        else:
            from PIL import Image
            import io
            im = Image.open(path).convert('RGBA')
            im.thumbnail((128, 128))
            buf = io.BytesIO(); im.save(buf, 'PNG'); data = buf.getvalue()
        return base64.b64encode(data).decode()
    except Exception:
        return None

def _clean_exec(e: str) -> str:
    import re
    return re.sub(r'%[fFuUdDnNickvm]', '', e).strip()

def load_linux_apps():
    from xdg.IconTheme import getIconPath
    dirs, apps, seen = [], [], set()
    data_home = os.environ.get('XDG_DATA_HOME', os.path.expanduser('~/.local/share'))
    data_dirs = os.environ.get('XDG_DATA_DIRS', '/usr/local/share:/usr/share').split(':')

    for d in [data_home, *data_dirs]:
        p = Path(d) / 'applications'
        if p.is_dir():
            dirs.append(p)
    for dir in dirs:
        for f in dir.glob('*.desktop'):
            if f.name in seen:
                continue
            seen.add(f.name)
            cp = configparser.ConfigParser(interpolation=None, strict=False)
            try:
                cp.read(f, encoding='utf-8')
            except configparser.Error:
                continue
            if not cp.has_section('Desktop Entry'):
                continue
            s = cp['Desktop Entry']
            if s.get('Type') != 'Application':
                continue
            if s.getboolean('NoDisplay', fallback=False) or s.getboolean('Hidden', fallback=False):
                continue
            name, exec_ = s.get('Name'), s.get('Exec')
            if not name or not exec_:
                continue
            icon_b64 = None
            icon = s.get('Icon')
            if icon:
                path = icon if os.path.isabs(icon) else getIconPath(icon, 128)
                icon_b64 = _png_b64(path) if path else None
            apps.append({'name': name, 'launch': _clean_exec(exec_), 'icon_b64': icon_b64})
    apps.sort(key=lambda x: x['name'])
    return apps

def load_windows_apps():
    import win32com.client
    shell = win32com.client.Dispatch("WScript.Shell")
    apps, seen = [], set()
    roots = []
    if pd := os.environ.get('ProgramData'):
        roots.append(Path(pd) / 'Microsoft/Windows/Start Menu/Programs')
    if ad := os.environ.get('APPDATA'):
        roots.append(Path(ad) / 'Microsoft/Windows/Start Menu/Programs')
    for root in roots:
        if not root.is_dir():
            continue
        for f in root.rglob('*.lnk'):
            try:
                target = shell.CreateShortCut(str(f)).Targetpath
            except Exception:
                continue
            if not target.lower().endswith('.exe'):
                continue
            name = f.stem
            if name.lower() in seen:
                continue
            seen.add(name.lower())
            apps.append({'name': name, 'launch': target, 'icon_b64': _exe_icon_b64(target)})
    apps.sort(key=lambda a: a['name'].lower())
    return apps

_APP_INDEX = {}  # name.lower() -> launch

def _rebuild_index(apps):
    _APP_INDEX.clear()
    for a in apps:
        _APP_INDEX[a['name'].lower()] = a['launch']

def load_apps():
    """Scan installed apps and refresh the name -> launch index."""
    apps = load_windows_apps() if sys.platform == 'win32' else load_linux_apps()
    _rebuild_index(apps)
    return apps

load_apps()

class LaunchByName(BaseModel):
    name: str

def launch_by_name(name: str):
    """Launch an app by its display name.

    Takes a plain name so actions can call it directly; the HTTP route unwraps
    its request model. Raises LookupError if no such app is installed.
    """
    launch = _APP_INDEX.get(name.lower())
    if launch is None:
        # The index is built at import, so an app installed since startup is
        # missing. Rescan once before giving up.
        load_apps()
        launch = _APP_INDEX.get(name.lower())
    if launch is None:
        raise LookupError(f"no app named {name!r}")
    if sys.platform == 'win32':
        os.startfile(launch)
    else:
        subprocess.Popen(
            ['/bin/sh', '-c', launch], start_new_session=True, env=clean_env()
        )
    return {"ok": True}
