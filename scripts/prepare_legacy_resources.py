"""Prune unused legacy IDs for CIQ 3.x's 254-members-per-module limit.

Original PNGs, pixels and standard-profile catalogs stay unchanged. The selected
catalog contains every live production drawable, not reduced-quality artwork.
"""
from pathlib import Path
import re
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
refs = set()
for source in (ROOT / 'source').glob('*.mc'):
    refs.update(re.findall(r'Rez\.Drawables\.(\w+)', source.read_text()))
refs.add('LauncherIcon')
for original, output in [('resources','resources-legacy'), ('resources-native144','resources-legacy-native144')]:
    tree = ET.parse(ROOT / original / 'drawables/drawables.xml')
    for bitmap in list(tree.getroot()):
        if bitmap.get('id') not in refs:
            tree.getroot().remove(bitmap)
        else:
            bitmap.set('filename', f'../../{original}/drawables/' + bitmap.get('filename'))
    out = ROOT / output / 'drawables/drawables.xml'
    out.parent.mkdir(parents=True, exist_ok=True)
    ET.indent(tree, space='    ')
    tree.write(out, encoding='unicode')
    strings = ROOT / output / 'strings/strings.xml'
    strings.parent.mkdir(parents=True, exist_ok=True)
    strings.write_bytes((ROOT / 'resources/strings/strings.xml').read_bytes())
    print(f'LEGACY_CATALOG: {output}: {len(tree.getroot())} core IDs + 16 scenery; PNGs unchanged')
