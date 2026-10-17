"""Build-time only: original generated layers -> crisp native Garmin resources.

No runtime image scaling or colour transforms. Keep originals and alpha. The
watch receives at most 15 MIP-safe RGB colours plus transparent per scene.
"""
from pathlib import Path
from PIL import Image
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
sizes = (240, 260, 280, 390, 416, 454)
phases = ('Dawn', 'Day', 'Dusk', 'Night')
themes = ('Forest', 'Meadow', 'Lakeside', 'Garden')
def mip(v):
    return max(0, min(255, round(v / 85) * 85))

for theme in themes:
    image = Image.open(ROOT / f'art/source/v051/{theme.lower()}.png').convert('RGBA')
    # Enlarge the WORLD's walkable clearing, never the creature. Move the
    # distant horizon up, leaving feet room to roam from ~53 to 75% height.
    split = round(image.height * .64)
    tile = Image.new('RGBA', (140, 140))
    tile.alpha_composite(image.crop((0, 0, image.width, split)).resize((140, 70), Image.Resampling.NEAREST), (0, 0))
    tile.alpha_composite(image.crop((0, split, image.width, image.height)).resize((140, 70), Image.Resampling.NEAREST), (0, 70))
    alpha = tile.getchannel('A').point(lambda a: 255 if a >= 128 else 0)
    rgb = tile.convert('RGB').quantize(colors=15, method=Image.Quantize.MEDIANCUT)
    palette = rgb.getpalette()
    for phase in phases:
        mapped = []
        for index in range(15):
            r, g, b = palette[index*3:index*3+3]
            if phase == 'Dawn':
                r, g, b = r*1.05, g*.93, b*.86
            elif phase == 'Dusk':
                r, g, b = r*1.05, g*.77, b*.83
            elif phase == 'Night':
                r, g, b = r*.30+10, g*.35+10, b*.50+32
            mapped.extend((mip(r), mip(g), mip(b)))
        toned = rgb.copy()
        toned.putpalette(mapped + [0] * (768-len(mapped)))
        rgba = toned.convert('RGBA')
        rgba.putalpha(alpha)
        for size in sizes:
            folder = ROOT / f'resources-world{size}'
            (folder / 'drawables').mkdir(parents=True, exist_ok=True)
            rgba.resize((size, size), Image.Resampling.NEAREST).save(folder / f'drawables/{theme}{phase}.png', optimize=True)
for size in sizes:
    tree = ET.ElementTree(ET.Element('resources'))
    for theme in themes:
        for phase in phases:
            name = theme + phase
            ET.SubElement(tree.getroot(), 'bitmap', id=name, filename=f'drawables/{name}.png', dithering='none')
    ET.indent(tree, space='    ')
    tree.write(ROOT / f'resources-world{size}/drawables.xml', encoding='unicode')
print('Prepared 4 original landscapes x 4 stepped palettes x 6 native display sizes, with transparent skies.')
