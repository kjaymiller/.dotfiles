#!/usr/bin/env python3
"""Waybar module: next event within the next 24h from the system calendar (EDS).
Emits single-line JSON {"text": ..., "tooltip": ...}."""
import datetime
import json
import sys
import time

import gi

gi.require_version("ECal", "2.0")
from gi.repository import ECal, EDataServer, ICalGLib


def epoch(tt, tzid):
    """ICalTime -> epoch seconds in local time."""
    if getattr(tt, "is_date", lambda: False)():
        return tt.as_timet()  # all-day event: midnight, UTC-ish
    zone = ICalGLib.Timezone.get_builtin_timezone_from_tzid(tzid) if tzid else None
    if zone is None and tt.is_utc():
        zone = ICalGLib.Timezone.get_utc_timezone()
    return tt.as_timet_with_zone(zone) if zone else tt.as_timet()


def fmt_hm(epoch_s):
    return time.strftime("%H:%M", time.localtime(epoch_s))


def main():
    reg = EDataServer.SourceRegistry.new_sync(None)
    now = datetime.datetime.now()
    end = now + datetime.timedelta(hours=24)
    sexp = (
        f'(occur-in-time-range? (make-time "{now:%Y%m%dT%H%M%S}")'
        f' (make-time "{end:%Y%m%dT%H%M%S}"))'
    )
    events = []
    for src in reg.list_sources(EDataServer.SOURCE_EXTENSION_CALENDAR):
        if "Birthdays" in src.get_display_name():
            continue
        try:
            client = ECal.Client.connect_sync(src, ECal.ClientSourceType.EVENTS, 10, None)
            ok, objs = client.get_object_list_sync(sexp, None)
        except Exception:
            continue
        for comp in objs:
            start = comp.get_dtstart()
            summary = comp.get_summary() or "(untitled)"
            events.append((epoch(start, start.get_tzid()), summary, comp))
    if not events:
        print(json.dumps({"text": "󰃭", "tooltip": "No events in the next 24h"}))
        return
    events.sort(key=lambda e: e[0])
    start, summary, comp = events[0]
    try:
        end_tt = comp.get_dtend()
        end_e = epoch(end_tt, end_tt.get_tzid())
        times = f"{fmt_hm(start)}–{fmt_hm(end_e)}"
    except Exception:
        times = fmt_hm(start)
    print(json.dumps({"text": f"󰃭 {summary}", "tooltip": f"{times} {summary}"}))


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(json.dumps({"text": "󰃭 ?", "tooltip": f"calendar error: {e}"}))
