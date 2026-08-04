"""Screen brightness reads.

On a Linux box with no `/sys/class/backlight` (i.e. a desktop driving external
monitors) the only path is DDC/CI over I2C via `ddcutil`, which is inherently
slow. `screen_brightness_control` makes it much worse: it caches the display
list for only 2 seconds, so nearly every read re-runs `ddcutil detect -v`
(~0.8s) before the `getvcp` that actually reads the value (~0.45s at ddcutil's
default sleep multiplier).

So for the ddcutil method we skip sbc and drive ddcutil ourselves: detect the
I2C bus once per process, use dynamic sleep instead of the conservative fixed
multiplier, and serve repeat reads from a short TTL cache. That takes a read
from ~1.3s to ~0.25s cold and ~0 warm. Other methods (sysfs, xrandr, wmi, vcp)
are already fast and stay on sbc.
"""

import re
import subprocess
import sys
import threading
import time

import screen_brightness_control as sbc

# Methods to probe, in order, the first time brightness is read. Ordered
# fastest-first; sbc's own auto-detection is not used because it retries every
# method on every call.
_METHODS = (
    ("wmi", "vcp") if sys.platform == "win32" else ("sysfs", "xrandr", "ddcutil")
)

_DDC_TIMEOUT = 15

# Reads inside this window reuse the last value. Brightness only changes when
# the user acts on it, so a short window keeps loops and repeated steps instant
# without serving anything meaningfully stale.
_TTL = 2.0

_lock = threading.Lock()
_method = None  # method name, None = not probed yet, False = no method works
_cached = None  # (value, monotonic timestamp)
_ddc_bus = None  # I2C bus number, None = not detected yet, False = no display


def _ddcutil(*args) -> str:
    # Dynamic sleep lets ddcutil tighten its DDC/CI delays to what this monitor
    # actually needs, instead of the fixed conservative multiplier.
    return subprocess.run(
        ["ddcutil", *args, "--enable-dynamic-sleep"],
        capture_output=True,
        text=True,
        timeout=_DDC_TIMEOUT,
        check=True,
    ).stdout


def _ddc_brightness():
    """Read brightness over DDC/CI, reusing the I2C bus found by the first call."""
    global _ddc_bus
    if _ddc_bus is None:
        match = re.search(r"^\s*I2C bus:\s*/dev/i2c-(\d+)", _ddcutil("detect"), re.M)
        _ddc_bus = int(match.group(1)) if match else False
    if _ddc_bus is False:
        return None
    # Terse output for VCP feature x10 (luminosity) is "VCP 10 C <cur> <max>".
    parts = _ddcutil("getvcp", "10", "-t", "-b", str(_ddc_bus)).split()
    value, max_value = int(parts[-2]), int(parts[-1])
    # A max other than 100 means the raw value is not already a percentage.
    return value if max_value == 100 else round(value / max_value * 100)


def _read(method):
    if method == "ddcutil":
        return _ddc_brightness()
    return sbc.get_brightness(method=method)[0]


def _brightness():
    global _method, _cached
    # Held across the read so concurrent steps wait for one result rather than
    # each spawning their own ddcutil.
    with _lock:
        if _cached is not None and time.monotonic() - _cached[1] < _TTL:
            return _cached[0]

        if _method is None:
            _method = False
            for m in _METHODS:
                try:
                    value = _read(m)
                except Exception:
                    continue
                _method = m
                _cached = (value, time.monotonic())
                return value

        if _method is False:
            return None

        try:
            value = _read(_method)
        except Exception:
            value = None
        _cached = (value, time.monotonic())
        return value


def prewarm():
    """Detect the brightness method in the background so the first read is warm.

    Probing costs a `ddcutil detect` on DDC/CI-only machines; doing it at
    startup keeps that off the first shortcut run.
    """
    threading.Thread(target=_brightness, daemon=True).start()
