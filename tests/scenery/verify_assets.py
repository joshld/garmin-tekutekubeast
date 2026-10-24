"""Read-only resource checks, not device/simulator certification."""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[2]
checked = 0
for size in (240, 260, 280, 390, 416, 454):
    for theme in ('Autumn', 'Countryside'):
        for phase in ('Dawn', 'Day', 'Dusk', 'Night'):
            path = root / f'resources-world{size}/drawables/{theme}{phase}.png'
            image = Image.open(path).convert('RGBA')
            assert image.size == (size, size), path
            assert image.getpixel((size // 2, size // 5))[3] == 0, path
            pixels = {p for _, p in image.getcolors(size * size)}
            colours = {p[:3] for p in pixels if p[3]}
            assert len(colours) <= 15, (path, len(colours))
            assert all(v in (0, 85, 170, 255) for p in colours for v in p), path
            assert {p[3] for p in pixels} <= {0, 255}, path
            for slot in range(5):
                x = int(size * (.26 + .12 * slot))
                assert image.getpixel((x, int(size * .77)))[3] == 255, path
            checked += 1
print(f'PASS: {checked} native-size assets, palette/alpha/sky/ground slots')
