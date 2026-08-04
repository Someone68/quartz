import sys

from models import ActionDef, ActionOutput
from get_brightness import _brightness

_PULSE = None

def _linux_volume():
    global _PULSE
    if _PULSE is None:
        import pulsectl
        _PULSE = pulsectl.Pulse("brightness-volume", threading_lock=True)
    sink = _PULSE.get_sink_by_name(_PULSE.server_info().default_sink_name)
    return round(sink.volume.value_flat * 100), sink.mute == 1

_VOL = None

def _win_volume():
    global _VOL
    if _VOL is None:
        from ctypes import cast, POINTER
        from comtypes import CLSCTX_ALL
        from pycaw.pycaw import AudioUtilities, IAudioEndpointVolume
        iface = AudioUtilities.GetSpeakers().Activate(
            IAudioEndpointVolume._iid_, CLSCTX_ALL, None)
        _VOL = cast(iface, POINTER(IAudioEndpointVolume))
    return round(_VOL.GetMasterVolumeLevelScalar() * 100), bool(_VOL.GetMute())

def _run(inputs: dict, context: dict) -> dict:
    brightness = _brightness()
    try:
        if sys.platform == "win32":
            volume, muted = _win_volume()
        elif sys.platform.startswith("linux"):
            volume, muted = _linux_volume()
        else:
            volume, muted = None, None
    except Exception:
        volume, muted = None, None
    return {"brightness": brightness, "volume": volume, "muted": muted}


ACTION = ActionDef(
    id="system.get_brightvol",
    category="System",
    name="Get Brightness and Volume",
    description="Get the brightness and volume of the system.",
    icon="settings_input_component",
    color="amber",
    platforms=["linux", "windows"],
    inputs=[],
    outputs=[
        ActionOutput(
            name="brightness",
            type="number",
            label="Brightness",
        ),
        ActionOutput(
            name="volume",
            type="number",
            label="Volume",
        ),
        ActionOutput(
            name="muted",
            type="boolean",
            label="Muted",
        ),
    ],
    run=_run,
)
