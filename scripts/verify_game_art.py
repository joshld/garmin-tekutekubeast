"""Issue #22: reviewed neighbour pixels only; no lost main-body/tail pixels."""
from collections import deque
from pathlib import Path
from PIL import Image
from pet_art_repair import repair_game

ROOT = Path(__file__).resolve().parents[1]
# Independent counts from inspection of historical native artwork + source atlases.
REMOVED = {
    'Nimble': [0, 60, 220, 24, 36, 132],
    'Grove4': [156, 168, 164, 0, 220, 156],
    'Grove5': [0, 184, 332, 232, 48, 368],
    'Ember4': [0, 0, 0, 0, 4, 0],
    'Ember5': [0, 0, 12, 40, 64, 0],
    'Tide3': [0, 32, 76, 0, 0, 0],
    'Tide4': [16, 200, 212, 32, 16, 24],
    'Tide5': [0, 228, 396, 20, 0, 24],
    'Wisp3': [0, 0, 40, 44, 24, 0],
    'Wisp4': [0, 160, 428, 340, 28, 212],
    'Wisp5': [0, 308, 768, 0, 172, 444],
}
checked = 0
for species, counts in REMOVED.items():
    for pose, expected in enumerate(counts):
        original = Image.open(ROOT / f'resources/drawables/v04/V4{species}{pose}.png').convert('RGBA')
        clean = repair_game(original, species, pose)
        opaque = {(x, y) for y in range(96) for x in range(96) if original.getpixel((x, y))[3]}
        parts = []
        pending = set(opaque)
        while pending:
            queue = deque([pending.pop()]); component = set(queue)
            while queue:
                x, y = queue.popleft()
                for point in ((x-1, y), (x+1, y), (x, y-1), (x, y+1)):
                    if point in pending:
                        pending.remove(point); component.add(point); queue.append(point)
            parts.append(component)
        body = max(parts, key=len)
        erased = {point for point in opaque if not clean.getpixel(point)[3]}
        assert len(erased) == expected, (species, pose, len(erased), expected)
        assert not erased.intersection(body), f'Main body/tail touched: {species}{pose}'
        assert all(original.getpixel(p) == clean.getpixel(p) for p in body)
        checked += 1
# Pet rendering must never crop at its bitmap boundary, including mirrored tails.
for variant in ('resources', 'resources-pet144', 'resources-native144', 'resources-native192'):
    for path in (ROOT / variant / 'drawables/v05').glob('V5Nimble*.png'):
        if path.stem.endswith('SleepSmall'):
            continue
        im = Image.open(path).convert('RGBA'); bounds = im.getbbox()
        assert bounds[0] > 0 and bounds[2] < im.width, f'Nimble tail at canvas edge: {path}'
print(f'PASS: {checked} source poses; exact neighbour counts; every main-body pixel retained; Nimble Pet tails inside canvases.')
