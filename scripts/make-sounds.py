#!/usr/bin/env python3
"""Writes the game's four sounds from fixed recipes, or checks the committed files against them.

Usage:
  scripts/make-sounds.py            write move, capture, crowning and gameEnd.wav into the app
  scripts/make-sounds.py --check    fail, naming the file, when a committed sound no longer
                                    matches its recipe (a missing file, another length, or a
                                    sample more than one step away)
  scripts/make-sounds.py --check <dir>   check the files in another directory

The recipes are in specs/007-settings-themes-sound-and-rules/contracts/settings-and-sound.md
("Files" and "Recipe details"). Standard library only, with a fixed seed, so every run writes the
same bytes; the check allows one step of difference because another platform's maths library may
round a sample the other way. To change a sound: change its recipe here, run the script, listen,
and commit the files.
"""

import math
import random
import sys
import wave
from pathlib import Path

RATE = 44_100
SEED = 20261023
SOUNDS_DIR = Path(__file__).resolve().parent.parent / "checkers/checkers/Features/Sound/Sounds"
FADE = 0.008
FULL_SCALE = 32_767


def samples(seconds):
    return round(seconds * RATE)


def resonate(signal, frequency, radius):
    """A two-pole resonator: y[n] = x[n] + 2r·cos(2πf/rate)·y[n−1] − r²·y[n−2]."""
    coefficient = 2 * radius * math.cos(2 * math.pi * frequency / RATE)
    output, previous, before = [], 0.0, 0.0
    for value in signal:
        current = value + coefficient * previous - radius * radius * before
        output.append(current)
        before, previous = previous, current
    return output


def normalized(signal):
    peak = max(abs(value) for value in signal)
    return [value / peak for value in signal]


def click(rng, low, high, seconds=0.12):
    """A wooden click: a noise burst through two resonators, plus a low thump."""
    count = samples(seconds)
    burst = [rng.uniform(-1, 1) * math.exp(-(n / RATE) / 0.002) for n in range(count)]
    low_part = normalized(resonate(burst, low, 0.995))
    high_part = normalized(resonate(burst, high, 0.990))
    thump = [
        math.sin(2 * math.pi * 180 * n / RATE) * math.exp(-(n / RATE) / 0.018)
        for n in range(count)
    ]
    return [0.6 * a + 0.35 * b + 0.4 * c for a, b, c in zip(low_part, high_part, thump)]


PARTIALS = [(1, 1.0), (2, 0.35), (3.01, 0.15), (4.2, 0.08)]


def bell(frequency, seconds, decay):
    """A bell tone: four partials, each decaying faster than the last, with a 4 ms attack."""
    output = []
    for n in range(samples(seconds)):
        t = n / RATE
        value = sum(
            amplitude * math.exp(-t * multiple / decay)
            * math.sin(2 * math.pi * frequency * multiple * t)
            for multiple, amplitude in PARTIALS
        )
        output.append(value * min(1.0, t / 0.004))
    return output


def mix(seconds, parts):
    """Adds sounds, each starting at its offset in seconds, into one of the given length."""
    output = [0.0] * samples(seconds)
    for offset, part in parts:
        start = samples(offset)
        for index, value in enumerate(part[: len(output) - start]):
            output[start + index] += value
    return output


def finish(signal, peak_dbfs):
    """Scales to the peak level, fades out over the last 8 ms and rounds to 16 bits."""
    scale = 10 ** (peak_dbfs / 20) / max(abs(value) for value in signal)
    fade = samples(FADE)
    output = []
    for index, value in enumerate(signal):
        gain = min(1.0, (len(signal) - 1 - index) / fade)
        sample = round(value * scale * gain * FULL_SCALE)
        output.append(max(-FULL_SCALE, min(FULL_SCALE, sample)))
    return output


def sounds():
    """The four sounds by file name, as 16-bit samples."""
    rng = random.Random(SEED)
    move = click(rng, 620, 1_700)
    first = click(rng, 900, 2_300)
    second = click(rng, 1_100, 2_800)
    capture = mix(0.22, [(0, first), (0.07, second)])
    crowning = mix(0.45, [(0, bell(1_046.5, 0.45, 0.16)), (0.06, bell(1_568, 0.39, 0.14))])
    game_end = mix(
        1.2,
        [
            (0, bell(784, 0.6, 0.25)),
            (0.18, bell(1_046.5, 0.6, 0.25)),
            (0.36, bell(1_318.5, 0.84, 0.32)),
        ],
    )
    return {
        "move.wav": finish(move, -3),
        "capture.wav": finish(capture, -3),
        "crowning.wav": finish(crowning, -6),
        "gameEnd.wav": finish(game_end, -6),
    }


def frames(values):
    return b"".join(value.to_bytes(2, "little", signed=True) for value in values)


def write(directory):
    directory.mkdir(parents=True, exist_ok=True)
    for name, values in sounds().items():
        with wave.open(str(directory / name), "wb") as file:
            file.setnchannels(1)
            file.setsampwidth(2)
            file.setframerate(RATE)
            file.writeframes(frames(values))
        peak = max(abs(value) for value in values)
        print(
            f"{name}: {len(values) / RATE:.3f} s, {(directory / name).stat().st_size} bytes, "
            f"peak {20 * math.log10(peak / FULL_SCALE):.1f} dBFS"
        )


def read(path):
    with wave.open(str(path), "rb") as file:
        if (file.getnchannels(), file.getsampwidth(), file.getframerate()) != (1, 2, RATE):
            return None
        data = file.readframes(file.getnframes())
    return [int.from_bytes(data[i : i + 2], "little", signed=True) for i in range(0, len(data), 2)]


def check(directory):
    problems = []
    for name, expected in sounds().items():
        path = directory / name
        if not path.exists():
            problems.append(f"{name}: missing")
            continue
        try:
            actual = read(path)
        except (wave.Error, EOFError) as error:
            problems.append(f"{name}: unreadable ({error})")
            continue
        if actual is None:
            problems.append(f"{name}: not 16-bit mono at {RATE} Hz")
        elif len(actual) != len(expected):
            problems.append(f"{name}: {len(actual)} samples, the recipe makes {len(expected)}")
        else:
            worst = max(abs(a - b) for a, b in zip(actual, expected))
            if worst > 1:
                problems.append(f"{name}: a sample differs from its recipe by {worst} steps")
    for problem in problems:
        print(problem, file=sys.stderr)
    if not problems:
        print(f"All four sounds match their recipes ({directory})")
    return not problems


def main(arguments):
    if arguments[:1] == ["--check"]:
        directory = Path(arguments[1]) if len(arguments) > 1 else SOUNDS_DIR
        return 0 if check(directory) else 1
    if arguments:
        print(__doc__, file=sys.stderr)
        return 2
    write(SOUNDS_DIR)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
