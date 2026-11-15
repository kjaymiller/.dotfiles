#!/usr/bin/env python3
"""
OpenRouter spend widget for niri — a gtk-layer-shell surface placed in the
backdrop (behind all workspaces) by this layer-rule in niri's config:

    layer-rule {
        match namespace="^openrouter-spend$"
        place-within-backdrop true
    }

Renders ~/.cache/openrouter-spend.png from ~/.cache/openrouter-spend.json
(written by openrouter-spend-gen.mjs, refreshed every 5 min by
openrouter-spend.timer) and re-renders every 60s.
"""

import json
import os
import time
from pathlib import Path

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
from gi.repository import Gtk, GLib, Gdk, GdkPixbuf
from gi.repository import GtkLayerShell

from PIL import Image, ImageDraw, ImageFont

JSON_PATH = Path.home() / ".cache" / "openrouter-spend.json"
PNG_PATH = Path.home() / ".cache" / "openrouter-spend.png"
NAMESPACE = "openrouter-spend"
RELOAD_SECS = 60

W, H = 460, 320
SCALE = 1.75                     # must match niri output scale (niri msg outputs)
PANEL = (13, 17, 23, 205)        # #0d1117, mostly solid — a hint of wallpaper tint only
TEXT = (230, 237, 243)
MUTED = (125, 133, 144)
TRACK = (22, 27, 34)
BAR_COLORS = [(139, 92, 246), (6, 182, 212), (245, 158, 11), (16, 185, 129),
              (236, 72, 153), (249, 115, 22), (59, 130, 246), (20, 184, 166)]
RED = (248, 81, 73)


def font(size, bold=False):
    size = int(size * SCALE)  # render at device resolution — fractional-scale output
    for path in (
        "/usr/share/fonts/google-noto-vf/NotoSans-Bold[wdth,wght].ttf" if bold
        else "/usr/share/fonts/google-noto-vf/NotoSans[wdth,wght].ttf",
        "/usr/share/fonts/liberation-sans/LiberationSans-Bold.ttf" if bold
        else "/usr/share/fonts/liberation-sans/LiberationSans-Regular.ttf",
    ):
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except OSError:
                pass
    return ImageFont.load_default()


def money(n):
    return f"${n:.2f}" if n >= 100 else f"${n:.4f}"


def rounded(draw, box, radius, fill):
    draw.rounded_rectangle(box, radius=radius, fill=fill)


class ScaledDraw:
    """Proxy that maps logical (1x) draw coordinates onto a SCALE-sized canvas.
    All existing render code keeps its logical units; everything is scaled
    on the way down to ImageDraw."""

    def __init__(self, draw, s):
        self._d, self._s = draw, s

    def _xy(self, xy):
        if isinstance(xy[0], (int, float)):
            return [c * self._s for c in xy]
        return [[c * self._s for c in pt] for pt in xy]

    def text(self, xy, *a, **kw):
        self._d.text(self._xy(xy), *a, **kw)

    def textlength(self, txt, font=None):
        # font is rendered at SCALE, so convert back to logical units
        return self._d.textlength(txt, font=font) / self._s

    def line(self, xy, *a, width=1, **kw):
        self._d.line(self._xy(xy), width=max(1, int(width * self._s)), *a, **kw)

    def rounded_rectangle(self, xy, radius=0, **kw):
        self._d.rounded_rectangle(self._xy(xy), radius=int(radius * self._s), **kw)


def render_png(data):
    img = Image.new("RGBA", (int(W * SCALE), int(H * SCALE)), (0, 0, 0, 0))
    d = ScaledDraw(ImageDraw.Draw(img), SCALE)
    rounded(d, (0, 0, W - 1, H - 1), 16, PANEL)

    x, y = 22, 18
    d.text((x, y), "OpenRouter Spend", font=font(22, bold=True), fill=TEXT)
    y += 32
    d.text((x, y), f"{data.get('monthLabel', '')}  ·  UTC",
           font=font(14), fill=MUTED)
    y += 30

    bar_w = W - 44 - 78
    if data.get("hasPerModel"):
        rows = data.get("byModel", [])[:6]
        if not rows:
            d.text((x, y + 8), "No usage this month yet 🎉", font=font(15), fill=MUTED)
            y += 40
        else:
            mx = max(v for _, v in rows) or 0.0001
            for i, (model, cost) in enumerate(rows):
                name = model if len(model) <= 34 else model[:32] + "…"
                d.text((x, y + 4), name, font=font(14), fill=TEXT)
                cost_txt = money(cost)
                tw = d.textlength(cost_txt, font=font(14))
                d.text((W - 22 - tw, y + 4), cost_txt, font=font(12), fill=(184, 196, 208))
                track_y = y + 24
                rounded(d, (x, track_y, x + bar_w, track_y + 10), 5, TRACK)
                bw = max(int((cost / mx) * bar_w), 8)
                rounded(d, (x, track_y, x + bw, track_y + 10), 5, BAR_COLORS[i % len(BAR_COLORS)])
                y += 54

            # total
            y += 2
            d.line((x, y, W - 22, y), fill=(33, 38, 45), width=1)
            y += 10
            d.text((x, y), "TOTAL", font=font(16, bold=True), fill=TEXT)
            total_txt = money(data.get("monthlyTotal", 0))
            tw = d.textlength(total_txt, font=font(17, bold=True))
            d.text((W - 22 - tw, y), total_txt, font=font(14, bold=True), fill=(255, 255, 255))
            y += 30
    else:
        rounded(d, (x, y, W - 22, y + 66), 10, TRACK)
        d.text((x + 12, y + 10), "Per-model breakdown needs", font=font(12, bold=True), fill=TEXT)
        d.text((x + 12, y + 28), "a Management Key:", font=font(12, bold=True), fill=TEXT)
        d.text((x + 12, y + 46), "openrouter.ai/settings/keys", font=font(12), fill=(88, 166, 255))
        y += 80

    # balance meter
    if y < H - 80:
        used = data.get("lifetimeUsage", 0)
        credits = data.get("lifetimeCredits", 0)
        remaining = max(credits - used, 0)
        d.text((x, y), "Account balance", font=font(12), fill=MUTED)
        y += 18
        rounded(d, (x, y, x + W - 44, y + 8), 4, TRACK)
        if credits > 0:
            bw = max(int(min(used / credits, 1.0) * (W - 44)), 4)
            rounded(d, (x, y, x + bw, y + 8), 4, (139, 92, 246))
        y += 16
        d.text((x, y), f"Used {money(used)}", font=font(13), fill=(184, 196, 208))
        rem_txt = f"Remaining {money(remaining)} of {money(credits)}"
        tw = d.textlength(rem_txt, font=font(11))
        d.text((W - 22 - tw, y), rem_txt, font=font(11), fill=(184, 196, 208))

    # footer: updated time
    stamp = time.strftime("updated %H:%M")
    tw = d.textlength(stamp, font=font(10))
    d.text(((W - tw) / 2, H - 24), stamp, font=font(12), fill=(72, 79, 88))

    img.save(PNG_PATH)


class Widget(Gtk.Window):
    def __init__(self):
        super().__init__(type=Gtk.WindowType.TOPLEVEL)
        self.set_default_size(W, H)
        self.set_decorated(False)

        self.image = Gtk.Image.new()
        self.add(self.image)
        self.reload(None)

        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_namespace(self, NAMESPACE)
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.BOTTOM)  # above wallpaper, below windows
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.TOP, True)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.RIGHT, True)
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.TOP, 60)
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.RIGHT, 24)

        GLib.timeout_add_seconds(RELOAD_SECS, self.reload, None)
        self.show_all()

    def reload(self, _user_data):
        try:
            data = json.loads(JSON_PATH.read_text())
            render_png(data)
            # device-resolution pixbuf -> surface with device scale = crisp text
            pb = GdkPixbuf.Pixbuf.new_from_file(str(PNG_PATH))
            surf = Gdk.cairo_surface_create_from_pixbuf(pb, SCALE, None)
            self.image.set_from_surface(surf)
        except Exception as e:
            print(f"widget: {e}", flush=True)
        return True  # keep the timer running


def main():
    win = Widget()
    win.connect("destroy", Gtk.main_quit)
    Gtk.main()


if __name__ == "__main__":
    main()
