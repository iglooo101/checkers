#!/usr/bin/env python3
"""Draws the app icon in its three variants, or checks the committed files against the drawing.

Usage:
  scripts/make-icon.py            write AppIcon.png, AppIcon-Dark.png and AppIcon-Tinted.png into
                                  the app's AppIcon set and name them in its Contents.json
  scripts/make-icon.py --check    fail, naming the file, when a committed icon no longer matches
                                  the drawing (a missing file, another size or kind of image, or a
                                  channel more than one step away)

The artwork is in specs/008-release-1-0/research.md (R10): one light king centered on a
two-by-two corner of Classic board squares, in the Classic theme's colors, with no text and no thin
lines. The default icon is opaque RGB; the dark one is the piece and its crown on a transparent
background, where the system puts its own; the tinted one is the default artwork in 8-bit
grayscale. Every shape is filled, with 4 × 4 samples per pixel for smooth edges. Standard library
only, so every run draws the same pixels; the check allows one step of difference because another
platform may round a value the other way. To change the icon: change the shapes here, run the
script, look at the files, and commit them.
"""

import json
import math
import struct
import sys
import zlib
from itertools import accumulate
from pathlib import Path

SIZE = 1024
SAMPLES = 4
ICON_DIR = (
    Path(__file__).resolve().parent.parent / "checkers/checkers/Assets.xcassets/AppIcon.appiconset"
)

LIGHT_SQUARE = (0xF1, 0xDF, 0xB9)
DARK_SQUARE = (0x7A, 0x4A, 0x24)
PIECE = (0xFF, 0xFA, 0xF0)
PIECE_EDGE = (0xA8, 0x8F, 0x5F)
CROWN = (0x6B, 0x44, 0x26)

CENTER = SIZE / 2
PIECE_RADIUS = 320
EDGE_WIDTH = 40
CROWN_POINTS = [
    (342, 656), (682, 656), (700, 436), (602, 536), (512, 396), (422, 536), (324, 436),
]
CROWN_BALL_RADIUS = 28
CROWN_BALLS = [(324, 436), (512, 396), (700, 436)]

# PNG color types.
GRAY, RGB, RGBA = 0, 2, 6
CHANNELS = {GRAY: 1, RGB: 3, RGBA: 4}


def circle(cx, cy, radius):
    """The x interval a circle covers on a horizontal line, or nothing."""
    def spans(y):
        dy = y - cy
        if abs(dy) >= radius:
            return []
        half = math.sqrt(radius * radius - dy * dy)
        return [(cx - half, cx + half)]
    return spans


def polygon(points):
    """The x intervals a simple polygon covers on a horizontal line (even-odd rule)."""
    edges = list(zip(points, points[1:] + points[:1]))

    def spans(y):
        crossings = sorted(
            x0 + (y - y0) * (x1 - x0) / (y1 - y0)
            for (x0, y0), (x1, y1) in edges
            if (y0 <= y < y1) or (y1 <= y < y0)
        )
        return list(zip(crossings[::2], crossings[1::2]))
    return spans


def merged(intervals):
    """Joins overlapping intervals, so shapes of one color count each sample once."""
    result = []
    for start, end in sorted(intervals):
        if result and start <= result[-1][1]:
            result[-1] = (result[-1][0], max(result[-1][1], end))
        else:
            result.append((start, end))
    return result


def add(changes, start, end, count):
    """Adds count to every pixel from start up to end, as two changes."""
    changes[start] += count
    changes[end] -= count


def coverage(shapes):
    """Rows of per-pixel counts (0 to 16) of the samples that any of the shapes covers."""
    rows = []
    for row in range(SIZE):
        changes = [0] * (SIZE + 2)
        for sub_row in range(SAMPLES):
            y = row + (sub_row + 0.5) / SAMPLES
            for start, end in merged(span for shape in shapes for span in shape(y)):
                # Sample column c sits at x = (c + 0.5) / SAMPLES.
                first = max(0, math.ceil(start * SAMPLES - 0.5))
                last = min(SIZE * SAMPLES, math.ceil(end * SAMPLES - 0.5))
                if first >= last:
                    continue
                # Counted as changes along the row: the first pixel, the full ones, the last.
                left, right = first // SAMPLES, (last - 1) // SAMPLES
                if left == right:
                    add(changes, left, left + 1, last - first)
                else:
                    add(changes, left, left + 1, (left + 1) * SAMPLES - first)
                    add(changes, left + 1, right, SAMPLES)
                    add(changes, right, right + 1, last - right * SAMPLES)
        rows.append(list(accumulate(changes))[:SIZE])
    return rows


def layers():
    """The piece and its crown, bottom to top, as (color, coverage rows)."""
    return [
        (PIECE_EDGE, coverage([circle(CENTER, CENTER, PIECE_RADIUS)])),
        (PIECE, coverage([circle(CENTER, CENTER, PIECE_RADIUS - EDGE_WIDTH)])),
        (
            CROWN,
            coverage(
                [polygon(CROWN_POINTS)]
                + [circle(x, y, CROWN_BALL_RADIUS) for x, y in CROWN_BALLS]
            ),
        ),
    ]


def square(x, y):
    """The board square under a pixel: a dark square at the bottom left, as on the board."""
    return DARK_SQUARE if (x < SIZE // 2) == (y >= SIZE // 2) else LIGHT_SQUARE


def composite(background, cover):
    """Paints each layer over the background with its coverage; colors are premultiplied."""
    red, green, blue, alpha = background
    for (r, g, b), count in cover:
        share = count / (SAMPLES * SAMPLES)
        red = r * share + red * (1 - share)
        green = g * share + green * (1 - share)
        blue = b * share + blue * (1 - share)
        alpha = share + alpha * (1 - share)
    return red, green, blue, alpha


def channel(value):
    return max(0, min(255, round(value)))


def luma(red, green, blue):
    """Gray from sRGB values with the Rec. 709 weights."""
    return 0.2126 * red + 0.7152 * green + 0.0722 * blue


def icons():
    """The three icons by file name, as (color type, rows of channel bytes)."""
    drawn = layers()
    default_rows, dark_rows, tinted_rows = [], [], []
    for y in range(SIZE):
        default_row, dark_row, tinted_row = bytearray(), bytearray(), bytearray()
        cache = {}
        counts = [rows[y] for _, rows in drawn]
        for x in range(SIZE):
            key = (square(x, y),) + tuple(row[x] for row in counts)
            if key not in cache:
                cover = list(zip((color for color, _ in drawn), key[1:]))
                red, green, blue, _ = composite(key[0] + (1.0,), cover)
                default = bytes(channel(v) for v in (red, green, blue))
                red, green, blue, alpha = composite((0.0, 0.0, 0.0, 0.0), cover)
                if alpha > 0:
                    dark = bytes(channel(v / alpha) for v in (red, green, blue))
                else:
                    dark = bytes(3)
                dark += bytes([channel(alpha * 255)])
                tinted = bytes([channel(luma(*default))])
                cache[key] = default, dark, tinted
            default, dark, tinted = cache[key]
            default_row += default
            dark_row += dark
            tinted_row += tinted
        default_rows.append(bytes(default_row))
        dark_rows.append(bytes(dark_row))
        tinted_rows.append(bytes(tinted_row))
    return {
        "AppIcon.png": (RGB, default_rows),
        "AppIcon-Dark.png": (RGBA, dark_rows),
        "AppIcon-Tinted.png": (GRAY, tinted_rows),
    }


def chunk(kind, data):
    body = kind + data
    return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body))


def png(color_type, rows):
    header = struct.pack(">IIBBBBB", SIZE, SIZE, 8, color_type, 0, 0, 0)
    pixels = b"".join(b"\x00" + row for row in rows)
    return (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", header)
        + chunk(b"sRGB", b"\x00")
        + chunk(b"IDAT", zlib.compress(pixels, 9))
        + chunk(b"IEND", b"")
    )


def unfiltered(data, width, channels):
    """Undoes PNG's per-row filters (types 0 to 4) on 8-bit pixels."""
    stride = width * channels
    rows, previous, position = [], bytes(stride), 0
    while position < len(data):
        kind, line = data[position], bytearray(data[position + 1 : position + 1 + stride])
        position += 1 + stride
        for i in range(stride):
            left = line[i - channels] if i >= channels else 0
            up = previous[i]
            corner = previous[i - channels] if i >= channels else 0
            if kind == 1:
                line[i] = (line[i] + left) & 0xFF
            elif kind == 2:
                line[i] = (line[i] + up) & 0xFF
            elif kind == 3:
                line[i] = (line[i] + (left + up) // 2) & 0xFF
            elif kind == 4:
                guess = left + up - corner
                distances = (abs(guess - left), abs(guess - up), abs(guess - corner))
                nearest = (left, up, corner)[distances.index(min(distances))]
                line[i] = (line[i] + nearest) & 0xFF
        rows.append(bytes(line))
        previous = line
    return rows


def read(path):
    """A PNG file's (width, height, color type, rows); raises ValueError if it cannot be read."""
    data = path.read_bytes()
    if not data.startswith(b"\x89PNG\r\n\x1a\n"):
        raise ValueError("not a PNG file")
    position, compressed, header = 8, b"", None
    while position < len(data):
        (length,) = struct.unpack(">I", data[position : position + 4])
        kind = data[position + 4 : position + 8]
        body = data[position + 8 : position + 8 + length]
        position += 12 + length
        if kind == b"IHDR":
            header = struct.unpack(">IIBBBBB", body)
        elif kind == b"IDAT":
            compressed += body
    if header is None:
        raise ValueError("no IHDR chunk")
    width, height, depth, color_type, _, _, interlace = header
    if depth != 8 or interlace != 0 or color_type not in CHANNELS:
        return width, height, None, []
    rows = unfiltered(zlib.decompress(compressed), width, CHANNELS[color_type])
    return width, height, color_type, rows


KINDS = {GRAY: "8-bit grayscale", RGB: "8-bit RGB", RGBA: "8-bit RGBA"}


def check(directory):
    problems = []
    for name, (color_type, expected) in icons().items():
        path = directory / name
        if not path.exists():
            problems.append(f"{name}: missing")
            continue
        try:
            width, height, actual_type, actual = read(path)
        except (ValueError, zlib.error, struct.error) as error:
            problems.append(f"{name}: unreadable ({error})")
            continue
        if (width, height) != (SIZE, SIZE):
            problems.append(f"{name}: {width} × {height}, the drawing is {SIZE} × {SIZE}")
        elif actual_type != color_type:
            problems.append(f"{name}: not {KINDS[color_type]}")
        elif actual != expected:
            worst = max(
                abs(a - b)
                for actual_row, expected_row in zip(actual, expected)
                for a, b in zip(actual_row, expected_row)
            )
            if worst > 1 or len(actual) != len(expected):
                problems.append(f"{name}: a channel differs from the drawing by {worst} steps")
    for problem in problems:
        print(problem, file=sys.stderr)
    if not problems:
        print(f"All three icons match the drawing ({directory})")
    return not problems


def name_files(directory):
    """Names each file in Contents.json's entry for its appearance, keeping Xcode's layout."""
    files = {None: "AppIcon.png", "dark": "AppIcon-Dark.png", "tinted": "AppIcon-Tinted.png"}
    path = directory / "Contents.json"
    contents = json.loads(path.read_text())
    for image in contents["images"]:
        appearance = next(
            (
                item["value"]
                for item in image.get("appearances", [])
                if item.get("appearance") == "luminosity"
            ),
            None,
        )
        image["filename"] = files[appearance]
    path.write_text(json.dumps(contents, indent=2, separators=(",", " : "), sort_keys=True) + "\n")


def write(directory):
    for name, (color_type, rows) in icons().items():
        (directory / name).write_bytes(png(color_type, rows))
        print(f"{name}: {SIZE} × {SIZE} {KINDS[color_type]}, {(directory / name).stat().st_size} bytes")
    name_files(directory)


def main(arguments):
    if arguments == ["--check"]:
        return 0 if check(ICON_DIR) else 1
    if arguments:
        print(__doc__, file=sys.stderr)
        return 2
    write(ICON_DIR)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
