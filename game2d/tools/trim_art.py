"""Crops Benika's part images to their visible pixels and prints each part's
sprite offset, so the part rotates around its joint (pivot) in Godot.

Run after make_art.js: python3 tools/trim_art.py
"""
from pathlib import Path

from PIL import Image

ART = Path(__file__).resolve().parent.parent / "art" / "benika"
SCALE = 2        # make_art.js renders at 2x
ORIGIN = (-40, -40)  # top-left corner of the draft space

# Joint positions in the draft space (see make_art.js).
PIVOTS = {
    "ponytail": (148, 48),
    "head": (110, 122),
    "torso": (110, 198),
    "arm_back": (96, 132),
    "arm_front": (124, 132),
    "leg_back": (102, 198),
    "leg_front": (118, 198),
}

for name, (px, py) in PIVOTS.items():
    path = ART / f"{name}.png"
    img = Image.open(path)
    left, top, right, bottom = img.getbbox()
    img.crop((left, top, right, bottom)).save(path)
    pivot_x = (px - ORIGIN[0]) * SCALE
    pivot_y = (py - ORIGIN[1]) * SCALE
    print(f'"{name}": Vector2({left - pivot_x}, {top - pivot_y}),  # pivot {(px, py)}')
