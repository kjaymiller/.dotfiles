#!/usr/bin/env python3
"""Print the current month (grid + agenda) as Pango markup for the deskcal widget."""
import calendar
import datetime
import sys

import gi

gi.require_version("ECal", "2.0")
from gi.repository import ECal, EDataServer, ICalGLib

TODAY = datetime.date.today()
NBSP = "\u00a0"
PURPLE = "#a979ec"
DIM = "#6c7086"
FG = "#cdd6f4"


def epoch(tt, tzid):
    if getattr(tt, "is_date", lambda: False)():
        return tt.as_timet()
    zone = ICalGLib.Timezone.get_builtin_timezone_from_tzid(tzid) if tzid else None
    if zone is None and tt.is_utc():
        zone = ICalGLib.Timezone.get_utc_timezone()
    return tt.as_timet_with_zone(zone) if zone else tt.as_timet()


def month_events(view):
    reg = EDataServer.SourceRegistry.new_sync(None)
    start = datetime.datetime(view.year, view.month, 1)
    end = datetime.datetime(view.year + (view.month == 12), view.month % 12 + 1, 1)
    sexp = (
        f'(occur-in-time-range? (make-time "{start:%Y%m%dT%H%M%S}")'
        f' (make-time "{end:%Y%m%dT%H%M%S}"))'
    )
    out = {}
    for src in reg.list_sources(EDataServer.SOURCE_EXTENSION_CALENDAR):
        if "Birthdays" in src.get_display_name():
            continue
        try:
            client = ECal.Client.connect_sync(src, ECal.ClientSourceType.EVENTS, 10, None)
            ok, objs = client.get_object_list_sync(sexp, None)
        except Exception:
            continue
        for comp in objs:
            st = comp.get_dtstart()
            start_e = epoch(st, st.get_tzid())
            d = datetime.datetime.fromtimestamp(start_e).date()
            out.setdefault(d, []).append(start_e)
    return out


def render_with_summaries():
    """Like render() but includes summaries (kept separate for clarity)."""
    import re

    reg = EDataServer.SourceRegistry.new_sync(None)
    start = datetime.datetime(TODAY.year, TODAY.month, 1)
    end = datetime.datetime(TODAY.year + (TODAY.month == 12), TODAY.month % 12 + 1, 1)
    sexp = (
        f'(occur-in-time-range? (make-time "{start:%Y%m%dT%H%M%S}")'
        f' (make-time "{end:%Y%m%dT%H%M%S}"))'
    )
    evs = {}
    for src in reg.list_sources(EDataServer.SOURCE_EXTENSION_CALENDAR):
        if "Birthdays" in src.get_display_name():
            continue
        try:
            client = ECal.Client.connect_sync(src, ECal.ClientSourceType.EVENTS, 10, None)
            ok, objs = client.get_object_list_sync(sexp, None)
        except Exception:
            continue
        for comp in objs:
            st = comp.get_dtstart()
            start_e = epoch(st, st.get_tzid())
            d = datetime.datetime.fromtimestamp(start_e).date()
            evs.setdefault(d, []).append((start_e, comp.get_summary() or "(untitled)"))
    for v in evs.values():
        v.sort()

    def day(d):
        if not d:
            return NBSP * 2
        date = datetime.date(TODAY.year, TODAY.month, d)
        s = f"{d:2d}"
        if date == TODAY:
            return f'<span weight="bold" foreground="{PURPLE}">{s}</span>'
        if date in evs:
            return f'<span underline="low">{s}</span>'
        return s

    lines = [f'<span foreground="{FG}" weight="bold">{TODAY:%B %Y}</span>']
    lines.append(f'<span foreground="{DIM}">' + NBSP.join(f"{n:>2}" for n in ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]) + "</span>")
    for week in calendar.Calendar(firstweekday=0).monthdayscalendar(TODAY.year, TODAY.month):
        lines.append(NBSP.join(day(d) for d in week))

    for date in sorted(evs):
        when = "Today" if date == TODAY else date.strftime("%a %d")
        for start_e, summary in evs[date]:
            t = datetime.datetime.fromtimestamp(start_e).strftime("%H:%M")
            lines.append(f"{when}{NBSP}·{NBSP}{t}{NBSP}{NBSP}{summary}")

    def vis(s):
        return len(re.sub(r"<[^>]*>", "", s))

    width = max(vis(l) for l in lines)
    return [(NBSP * (width - vis(l))) + l for l in lines]


if __name__ == "__main__":
    sys.stdout.write("\n".join(render_with_summaries()) + "\n")
