#!/usr/bin/env python3
"""deskcal daemon: renders the system-calendar month view to a cache file.
One long-lived process amortizes the slow EDS connect; the widget just reads the file."""
import fcntl
import os
import sys
import time

sys.path.insert(0, "/home/kjaymiller/.local/bin")
import deskcal_data  # noqa: E402

CACHE = os.path.expanduser("~/.cache/deskcal.markup")
LOCK = os.path.expanduser("~/.cache/deskcal.lock")


def main():
    lock = open(LOCK, "w")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        print("another deskcal daemon is running", file=sys.stderr)
        return 0

    last = None
    while True:
        try:
            markup = deskcal_data.render_with_summaries()
            text = "\n".join(markup) + "\n"
            if text != last:
                tmp = CACHE + ".tmp"
                with open(tmp, "w") as f:
                    f.write(text)
                os.replace(tmp, CACHE)
                last = text
        except Exception as e:
            with open(CACHE, "w") as f:
                f.write(f'<span foreground="#f53c3c">calendar error: {e}</span>')
        time.sleep(60)


if __name__ == "__main__":
    main()
