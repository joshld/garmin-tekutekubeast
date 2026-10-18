"""Verify exact historical sprite pixels, retain a QA-only old-scale specimen."""
from pathlib import Path
import subprocess
from io import BytesIO
from PIL import Image, ImageOps
from pet_art_repair import repair_nimble

root = Path(__file__).resolve().parents[1]
checked = 0
for folder in ('resources', 'resources-pet144', 'resources-native144', 'resources-native192'):
    historical = 'resources' if folder == 'resources-pet144' else folder
    for pet in (root / folder / 'drawables/v05').glob('V5*.png'):
        name = pet.stem
        if name.startswith('V5Game') or name.endswith('SleepSmall'):
            old = subprocess.check_output(['git', 'show', f'eecb6c6:{pet.relative_to(root).as_posix()}'], cwd=root)
            assert pet.read_bytes() == old, f'Game/Glance asset changed: {pet}'
            continue
        original_name = 'V4' + name[2:].removesuffix('Left') + '.png'
        path = f'{historical}/drawables/v04/{original_name}'
        original = subprocess.check_output(['git', 'show', f'e9f97c5:{path}'], cwd=root)
        expected = Image.open(BytesIO(original)).convert('RGBA')
        if name.startswith('V5Nimble'):
            # Issue #22: remove only neighbouring atlas fragments; body pixels,
            # native canvas, padding and position remain the exact v0.4 size.
            repaired = repair_nimble(expected)
            removed = sum(a[3] > 0 and b[3] == 0 for a, b in zip(expected.getdata(), repaired.getdata()))
            pose = int(name.removesuffix('Left')[-1])
            counts = {96: [0,60,220,24,36,132], 144: [0,135,495,54,81,297], 192: [0,240,880,96,144,528]}
            assert removed == counts[expected.width][pose], f'Unexpected Nimble correction: {pet}'
            expected = repaired
        if name.endswith('Left'):
            expected = ImageOps.mirror(expected)
        actual = Image.open(pet).convert('RGBA')
        assert actual.size == expected.size and actual.tobytes() == expected.tobytes(), str(pet)
        checked += 1
qa = root / 'tests/world-preview/resources'
qa.mkdir(parents=True, exist_ok=True)
(qa / 'v050-pip.png').write_bytes(subprocess.check_output([
    'git', 'show', 'eecb6c6:resources-pet144/drawables/v05/V5Pip0.png'], cwd=root))
print(f'PASS: {checked} Pet poses retain v0.4.0 body pixels/size (Nimble atlas bleed removed); games/Glance unchanged.')
