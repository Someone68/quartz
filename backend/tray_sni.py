"""Linux tray via the StatusNotifierItem D-Bus protocol."""

import asyncio
import struct

from dbus_fast import BusType, PropertyAccess, Variant
from dbus_fast.aio import MessageBus
from dbus_fast.service import ServiceInterface, dbus_property, method, signal

WATCHER_BUS = "org.kde.StatusNotifierWatcher"
WATCHER_PATH = "/StatusNotifierWatcher"
ITEM_PATH = "/StatusNotifierItem"
MENU_PATH = "/MenuBar"

# Menu item ids. 0 is reserved by the spec for the root.
ID_HEADER = 1
ID_SEP_1 = 2
ID_OPEN = 3
ID_PAUSE = 4
ID_SEP_2 = 5
ID_QUIT = 6


# Panel icons are small; these two cover normal and HiDPI panels. Every pixmap
# is inlined into each property reply, so more/larger sizes only make the
# messages heavier for no visible gain.
ICON_SIZES = (24, 48)


def _argb_pixmap(img, size):
    """PIL image -> the (width, height, bytes) triple the spec asks for.

    Pixel data is ARGB32 in network byte order, which is not a format PIL
    exports directly, so we repack it from RGBA.
    """
    img = img.convert("RGBA").resize((size, size))
    out = bytearray(size * size * 4)
    for i, (r, g, b, a) in enumerate(img.getdata()):
        struct.pack_into(">4B", out, i * 4, a, r, g, b)
    return [size, size, bytes(out)]


class StatusNotifierItem(ServiceInterface):
    """The panel icon: what it looks like and what a click does."""

    def __init__(self, title, pixmaps, on_activate):
        super().__init__("org.kde.StatusNotifierItem")
        self._title = title
        self._pixmaps = pixmaps
        self._on_activate = on_activate

    @dbus_property(access=PropertyAccess.READ, name="Category")
    def category(self) -> "s":
        return "ApplicationStatus"

    @dbus_property(access=PropertyAccess.READ, name="Id")
    def id(self) -> "s":
        return "quartz"

    @dbus_property(access=PropertyAccess.READ, name="Title")
    def title(self) -> "s":
        return self._title

    @dbus_property(access=PropertyAccess.READ, name="Status")
    def status(self) -> "s":
        return "Active"

    # Deliberately empty: a name that the icon theme cannot resolve renders as a
    # blank slot, and from-source runs have no theme icon installed. The pixmap
    # below always works.
    @dbus_property(access=PropertyAccess.READ, name="IconName")
    def icon_name(self) -> "s":
        return ""

    @dbus_property(access=PropertyAccess.READ, name="IconPixmap")
    def icon_pixmap(self) -> "a(iiay)":
        return self._pixmaps

    @dbus_property(access=PropertyAccess.READ, name="AttentionIconName")
    def attention_icon_name(self) -> "s":
        return ""

    @dbus_property(access=PropertyAccess.READ, name="OverlayIconName")
    def overlay_icon_name(self) -> "s":
        return ""

    @dbus_property(access=PropertyAccess.READ, name="ToolTip")
    def tool_tip(self) -> "(sa(iiay)ss)":
        return ["", self._pixmaps, self._title, ""]

    # False, so a left click is delivered to us as Activate and only a right
    # click opens the menu.
    @dbus_property(access=PropertyAccess.READ, name="ItemIsMenu")
    def item_is_menu(self) -> "b":
        return False

    @dbus_property(access=PropertyAccess.READ, name="Menu")
    def menu(self) -> "o":
        return MENU_PATH

    @method(name="Activate")
    def activate(self, x: "i", y: "i"):
        self._on_activate()

    @method(name="SecondaryActivate")
    def secondary_activate(self, x: "i", y: "i"):
        self._on_activate()

    @method(name="Scroll")
    def scroll(self, delta: "i", orientation: "s"):
        pass

    @method(name="ContextMenu")
    def context_menu(self, x: "i", y: "i"):
        pass

    @signal(name="NewIcon")
    def new_icon(self):
        pass

    @signal(name="NewStatus")
    def new_status(self, status: "s") -> "s":
        return status

    @signal(name="NewToolTip")
    def new_tool_tip(self):
        pass

    @signal(name="NewTitle")
    def new_title(self):
        pass


class DBusMenu(ServiceInterface):
    """The right-click menu, served over com.canonical.dbusmenu."""

    def __init__(self, header, on_open, on_toggle_pause, on_quit):
        super().__init__("com.canonical.dbusmenu")
        self._header = header
        self._on_open = on_open
        self._on_toggle_pause = on_toggle_pause
        self._on_quit = on_quit
        self._paused = False
        self._revision = 1

    # --- layout -------------------------------------------------------------

    def _props(self, item_id):
        if item_id == ID_HEADER:
            return {
                "label": Variant("s", self._header),
                "enabled": Variant("b", False),
                "visible": Variant("b", True),
            }
        if item_id in (ID_SEP_1, ID_SEP_2):
            return {"type": Variant("s", "separator"), "visible": Variant("b", True)}
        if item_id == ID_OPEN:
            return {
                "label": Variant("s", "Open Quartz"),
                "enabled": Variant("b", True),
                "visible": Variant("b", True),
            }
        if item_id == ID_PAUSE:
            return {
                "label": Variant("s", "Pause triggers"),
                "enabled": Variant("b", True),
                "visible": Variant("b", True),
                "toggle-type": Variant("s", "checkmark"),
                "toggle-state": Variant("i", 1 if self._paused else 0),
            }
        if item_id == ID_QUIT:
            return {
                "label": Variant("s", "Quit"),
                "enabled": Variant("b", True),
                "visible": Variant("b", True),
            }
        return {}

    def _item(self, item_id):
        return [item_id, self._props(item_id), []]

    def _layout(self):
        children = [
            Variant("(ia{sv}av)", self._item(i))
            for i in (ID_HEADER, ID_SEP_1, ID_OPEN, ID_PAUSE, ID_SEP_2, ID_QUIT)
        ]
        return [0, {"children-display": Variant("s", "submenu")}, children]

    @method(name="GetLayout")
    def get_layout(
        self, parent_id: "i", recursion_depth: "i", property_names: "as"
    ) -> "u(ia{sv}av)":
        if parent_id == 0:
            return [self._revision, self._layout()]
        return [self._revision, self._item(parent_id)]

    @method(name="GetGroupProperties")
    def get_group_properties(self, ids: "ai", property_names: "as") -> "a(ia{sv})":
        return [[i, self._props(i)] for i in ids]

    @method(name="GetProperty")
    def get_property(self, item_id: "i", name: "s") -> "v":
        return self._props(item_id).get(name, Variant("s", ""))

    # --- interaction --------------------------------------------------------

    @method(name="Event")
    def event(self, item_id: "i", event_id: "s", data: "v", timestamp: "u"):
        if event_id != "clicked":
            return
        if item_id == ID_OPEN:
            self._on_open()
        elif item_id == ID_PAUSE:
            self._paused = not self._paused
            self._on_toggle_pause(self._paused)
            # Tell the panel to re-read the checkmark.
            self.emit_properties_changed({}, [])
            self._revision += 1
            self.layout_updated(self._revision, 0)
        elif item_id == ID_QUIT:
            self._on_quit()

    @method(name="EventGroup")
    def event_group(self, events: "a(isvu)") -> "ai":
        for item_id, event_id, data, timestamp in events:
            self.event(item_id, event_id, data, timestamp)
        return []

    @method(name="AboutToShow")
    def about_to_show(self, item_id: "i") -> "b":
        return False

    @method(name="AboutToShowGroup")
    def about_to_show_group(self, ids: "ai") -> "aiai":
        return [[], []]

    # --- properties and signals --------------------------------------------

    @dbus_property(access=PropertyAccess.READ, name="Version")
    def version(self) -> "u":
        return 3

    @dbus_property(access=PropertyAccess.READ, name="TextDirection")
    def text_direction(self) -> "s":
        return "ltr"

    @dbus_property(access=PropertyAccess.READ, name="Status")
    def status(self) -> "s":
        return "normal"

    @dbus_property(access=PropertyAccess.READ, name="IconThemePath")
    def icon_theme_path(self) -> "as":
        return []

    @signal(name="LayoutUpdated")
    def layout_updated(self, revision: "u", parent: "i") -> "ui":
        return [revision, parent]

    @signal(name="ItemsPropertiesUpdated")
    def items_properties_updated(
        self, updated: "a(ia{sv})", removed: "a(ias)"
    ) -> "a(ia{sv})a(ias)":
        return [updated, removed]

    @signal(name="ItemActivationRequested")
    def item_activation_requested(self, item_id: "i", timestamp: "u") -> "iu":
        return [item_id, timestamp]


async def _serve(title, header, pixmaps, on_open, on_toggle_pause, on_quit, paused):
    """One connection: export, register, then run until the bus drops."""
    bus = await MessageBus(bus_type=BusType.SESSION).connect()

    item = StatusNotifierItem(title, pixmaps, on_open)
    menu = DBusMenu(header, on_open, on_toggle_pause, on_quit)
    # Carry the pause state across reconnects so the checkmark stays honest.
    menu._paused = paused["on"]
    bus.export(ITEM_PATH, item)
    bus.export(MENU_PATH, menu)

    # The watcher tracks us by bus name, so it needs our unique name; it also
    # drops the item automatically when we disconnect.
    introspection = await bus.introspect(WATCHER_BUS, WATCHER_PATH)
    proxy = bus.get_proxy_object(WATCHER_BUS, WATCHER_PATH, introspection)
    watcher = proxy.get_interface(WATCHER_BUS)
    await watcher.call_register_status_notifier_item(bus.unique_name)

    try:
        await bus.wait_for_disconnect()
    finally:
        paused["on"] = menu._paused


async def _serve_forever(title, header, pixmaps, on_open, on_toggle_pause, on_quit):
    paused = {"on": False}
    await _serve(title, header, pixmaps, on_open, on_toggle_pause, on_quit, paused)

    delay = 1
    while True:
        await asyncio.sleep(delay)
        try:
            await _serve(
                title, header, pixmaps, on_open, on_toggle_pause, on_quit, paused
            )
            delay = 1
        except Exception as e:
            # Panel gone for good, or the session is shutting down. Back off so
            # a permanently broken bus cannot spin this thread.
            delay = min(delay * 2, 60)
            print(f"Tray: reconnect failed, retrying in {delay}s ({e}).")


def run(title, header, pixmap_image, on_open, on_toggle_pause, on_quit) -> None:
    """Serve the tray. Blocks forever; call it on its own thread.

    Raises if no StatusNotifierWatcher is running (no session bus, or a desktop
    with no SNI host), which the caller treats as "no tray available".
    """
    pixmaps = [_argb_pixmap(pixmap_image, s) for s in ICON_SIZES]
    asyncio.run(
        _serve_forever(title, header, pixmaps, on_open, on_toggle_pause, on_quit)
    )
