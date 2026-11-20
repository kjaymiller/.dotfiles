#!/usr/bin/env python3
"""
OpenRouter spend widget for niri — a gtk-layer-shell surface in the backdrop
(layer-rule in niri's config matches namespace ^openrouter-spend$).

Text-only, like deskcal: a transparent window with a single Gtk.Label fed
Pango markup, re-read every 60s from ~/.cache/openrouter-spend.json
(written by openrouter-spend-gen.mjs, refreshed every 5 min by
openrouter-spend.timer).
"""

import json
import time
from pathlib import Path

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
from gi.repository import Gtk, GLib, Gdk, GtkLayerShell

gi.require_version("Rsvg", "2.0")
from gi.repository import Rsvg

JSON_PATH = Path.home() / ".cache" / "openrouter-spend.json"
LOGO_PATH = Path.home() / "Pictures" / "openrouter.svg"
LOGO_PX = 16  # logical px; drawn natively at device scale
NAMESPACE = "openrouter-spend"
RELOAD_SECS = 60

# palette matches deskcal / catppuccin-ish
ACCENT = "#a979ec"
TEXT = "#cdd6f4"
MUTED = "#6c7086"
MONEY = "#f0c674"
LINK = "#58a6ff"


def money(n):
    return f"${n:.2f}" if n >= 100 else f"${n:.4f}"



def build_markup(data):
    lines = []
    month = data.get("monthLabel", "")

    # header
    lines.append(f'<span weight="bold" foreground="{TEXT}">OpenRouter Spend</span>')
    if month:
        lines.append(f'<span foreground="{MUTED}">{month} · UTC</span>')
    lines.append("")

    # per-model rows, name padded so costs align (monospace font)
    if data.get("hasPerModel"):
        rows = data.get("byModel", [])[:5]
        if not rows:
            lines.append(f'<span foreground="{MUTED}">No usage this month yet 🎉</span>')
        else:
            mx = max(len(m) for m, _ in rows)
            for model, cost in rows:
                name = model if len(model) <= 20 else model[:18] + "…"
                pad = "&nbsp;" * (mx - len(name))
                lines.append(
                    f'<span foreground="{TEXT}">{esc(name)}</span>{pad}'
                    f'<span foreground="{MONEY}">{money(cost)}</span>'
                )
    else:
        lines.append(f'<span foreground="{MUTED}">Per-model breakdown needs</span>')
        lines.append(f'<span foreground="{MUTED}">a Management Key:</span>')
        lines.append(f'<span foreground="{LINK}">openrouter.ai/settings/keys</span>')

    lines.append("")

    # total + balance
    lines.append(
        f'<span weight="bold" foreground="{TEXT}">TOTAL</span>'
        f'<span foreground="{MONEY}" weight="bold">{money(data.get("monthlyTotal", 0))}</span>'
    )
    used = data.get("lifetimeUsage", 0)
    credits = data.get("lifetimeCredits", 0)
    remaining = max(credits - used, 0)
    lines.append(
        f'<span foreground="{MUTED}">Used {money(used)} · Remain {money(remaining)}</span>'
    )

    stamp = time.strftime("updated %H:%M")
    lines.append(f'<span foreground="{MUTED}" size="x-small">{stamp}</span>')
    return "\n".join(lines)


def esc(s):
    return (
        s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    )


class Widget(Gtk.Window):
    def __init__(self):
        super().__init__(type=Gtk.WindowType.TOPLEVEL)

        # transparent window, no background at all — pure text
        visual = self.get_screen().get_rgba_visual()
        if visual is not None:
            self.set_visual(visual)
            self.set_app_paintable(True)

        css = Gtk.CssProvider()
        css.load_from_data(b"""
            window { background-color: rgba(0,0,0,0); }
            label { font-family: "JetBrainsMono Nerd Font"; font-size: 10px; }
        """)
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        self.label = Gtk.Label(xalign=0, yalign=0)
        self.label.set_use_markup(True)
        self.label.set_valign(Gtk.Align.START)
        # left margin reserves room for the window-drawn logo
        self.label.set_margin_start(LOGO_PX + 6)
        self.label.set_margin_top(2)
        self.add(self.label)
        self._logo_svg = self._recolored_logo()
        self.last = None
        self.connect("draw", self.draw_logo)

        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_namespace(self, NAMESPACE)
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.BOTTOM)  # above wallpaper, below windows
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.TOP, True)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.RIGHT, True)
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.TOP, 250)  # below the calendar
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.RIGHT, 16)

        self.update(None)
        GLib.timeout_add_seconds(RELOAD_SECS, self.update, None)
        self.show_all()

    def _recolored_logo(self):
        """Inject fill=#a979ec into the SVG once, cache it to ~/.cache."""
        tmp = Path.home() / ".cache" / "openrouter-spend-logo.svg"
        svg = LOGO_PATH.read_text()
        if 'fill="#a979ec"' not in svg:
            svg = svg.replace("<path ", '<path fill="#a979ec" ', 1)
        tmp.write_text(svg)
        return tmp

    def draw_logo(self, _window, cr):
        """Render the recolored SVG straight into the window's cairo context —
        the same direct approach that worked for the original black logo."""
        try:
            handle = Rsvg.Handle.new_from_file(str(self._logo_svg))
            rect = Rsvg.Rectangle()
            rect.x = rect.y = 0.0
            rect.width = rect.height = LOGO_PX
            handle.render_document(cr, rect)
        except Exception as e:
            print(f"logo: {e}", flush=True)
        return False  # let the default handler draw the label too

    def update(self, _user_data):
        try:
            markup = build_markup(json.loads(JSON_PATH.read_text()))
            if markup != self.last:
                self.label.set_markup(markup)
                self.last = markup
        except FileNotFoundError:
            self.label.set_markup(f'<span foreground="{MUTED}">waiting for data…</span>')
        except Exception as e:
            self.label.set_markup(f'<span foreground="#f53c3c">spend widget error: {esc(str(e))}</span>')
        return True  # keep the timer running


def main():
    win = Widget()
    win.connect("destroy", Gtk.main_quit)
    Gtk.main()


if __name__ == "__main__":
    main()
