#!/usr/bin/env python3
"""Judges the computer's timing and the sound delay from a console capture of the app on the
phone (specs/008-release-1-0/contracts/release-tooling.md, "Device logs"; spec SC-005).

Usage: scripts/device-timings.py <console.txt>

Reads the three measurement lines wherever they appear in a line and skips everything else. Per
difficulty, at least 95% of the computer's first steps come 0.5 to 1.0 s after its turn starts
and none later than 1.5 s; the slowest sound's start plus the output latency stays within 100 ms.
Prints a report and exits 1 on any miss, or when a difficulty or the sound lines are missing.
"""

import re
import sys

LEVELS = ("easy", "medium", "hard")
TURN = re.compile(r"Computer turn at (easy|medium|hard): first step after (\d+) ms")
SOUND = re.compile(r"Sound (move|capture|crowning|gameEnd) started (\d+(?:\.\d+)?) ms after its step")
LATENCY = re.compile(r"Output latency (\d+(?:\.\d+)?) ms")

WINDOW_MS = (500, 1000)
SHARE_PERCENT = 95.0
LATEST_MS = 1500
SOUND_BUDGET_MS = 100.0


def read(path):
    """The first-step times per difficulty, the sound start delays and the output latencies."""
    turns = {level: [] for level in LEVELS}
    sounds, latencies = [], []
    with open(path, encoding="utf-8", errors="replace") as capture:
        for line in capture:
            if match := TURN.search(line):
                turns[match.group(1)].append(int(match.group(2)))
            elif match := SOUND.search(line):
                sounds.append(float(match.group(2)))
            elif match := LATENCY.search(line):
                latencies.append(float(match.group(1)))
    return turns, sounds, latencies


def main(arguments):
    if len(arguments) != 1:
        print("Usage: scripts/device-timings.py <console.txt>", file=sys.stderr)
        return 2
    try:
        turns, sounds, latencies = read(arguments[0])
    except OSError as error:
        print(f"Cannot read {arguments[0]}: {error.strerror}.", file=sys.stderr)
        return 2

    misses = []
    low, high = WINDOW_MS
    print("Computer turns (first step 0.5–1.0 s after the turn starts in at least 95%, none over "
          "1.5 s):")
    for level in LEVELS:
        times = turns[level]
        if not times:
            print(f"  {level}: no turns")
            misses.append(f"no computer turns at {level}")
            continue
        share = 100.0 * sum(low <= time <= high for time in times) / len(times)
        slowest = max(times)
        passed = share >= SHARE_PERCENT and slowest <= LATEST_MS
        print(f"  {level}: {len(times)} turns, {share:.1f}% within 0.5–1.0 s, slowest {slowest} ms:"
              f" {'pass' if passed else 'miss'}")
        if not passed:
            misses.append(f"the computer's timing at {level}")

    print("Sound (the slowest start plus the output latency within 100 ms):")
    if not sounds or not latencies:
        print("  no sound lines" if not sounds else "  no output latency line")
        misses.append("no sound lines" if not sounds else "no output latency line")
    else:
        slowest, latency = max(sounds), max(latencies)
        total = slowest + latency
        passed = total <= SOUND_BUDGET_MS
        print(f"  {len(sounds)} sounds, slowest start {slowest:.1f} ms, output latency "
              f"{latency:.1f} ms, sum {total:.1f} ms: {'pass' if passed else 'miss'}")
        if not passed:
            misses.append("the sound delay")

    if misses:
        print("Missed: " + "; ".join(misses) + ".")
        return 1
    print("Every timing passes.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
