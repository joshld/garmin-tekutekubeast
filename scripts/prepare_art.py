#!/usr/bin/env python3
"""Prepare generated source artwork for the Enduro 4 MIP palette.

Requires Pillow. Run from any directory; source PNGs are kept in art/source.
Only size/palette/alpha conversion is applied here; creature art is generated.
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
PALETTE = [(0, 0, 0), (0, 85, 0), (85, 170, 85),
           (170, 255, 85), (255, 255, 170), (255, 255, 255)]


def prepare(name, logical_height):
    source = Image.open(ROOT / "art" / "source" / (name + ".png")).convert("RGBA")
    alpha = source.getchannel("A").point(lambda value: 255 if value >= 128 else 0)
    bounds = alpha.getbbox()
    if bounds is None:
        raise ValueError("Empty artwork: " + name)
    source.putalpha(alpha)
    source = source.crop(bounds)
    source.thumbnail((52, logical_height), Image.Resampling.NEAREST)
    pixels = source.load()
    for y in range(source.height):
        for x in range(source.width):
            r, g, b, a = pixels[x, y]
            if a:
                color = min(PALETTE, key=lambda c: (r-c[0])**2 + (g-c[1])**2 + (b-c[2])**2)
                pixels[x, y] = (*color, 255)
            else:
                pixels[x, y] = (0, 0, 0, 0)
    canvas = Image.new("RGBA", (56, 56), (0, 0, 0, 0))
    canvas.alpha_composite(source, ((56-source.width)//2, 54-source.height))
    output = ROOT / "resources" / "drawables" / (name + ".png")
    canvas.resize((112, 112), Image.Resampling.NEAREST).save(output, optimize=True)
    print(name + ": 112x112, binary alpha, six device-native colors")
    return canvas


if __name__ == "__main__":
    sprites = {name: prepare(name, height) for name, height in
               [("egg", 44), ("pip", 48), ("nimble", 52)]}
    # A separately named, correctly sized launcher keeps existing source intact.
    icon = Image.new("RGBA", (40, 40), (0, 0, 0, 0))
    pip = sprites["pip"]
    pip = pip.crop(pip.getchannel("A").getbbox())
    pip.thumbnail((36, 36), Image.Resampling.NEAREST)
    icon.alpha_composite(pip, ((40-pip.width)//2, (40-pip.height)//2))
    icon.save(ROOT / "resources" / "drawables" / "beast-launcher.png", optimize=True)
