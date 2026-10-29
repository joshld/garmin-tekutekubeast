"""Prune unused legacy IDs for CIQ 3.x's 254-members-per-module limit.

Original PNGs, pixels and standard-profile catalogs stay unchanged. The selected
catalog contains every live production drawable, not reduced-quality artwork.
"""
from pathlib import Path
import re
import shutil
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
    rendered=ET.tostring(tree.getroot(),encoding='unicode')
    if not out.exists() or out.read_text()!=rendered:
        out.write_text(rendered)
    strings = ROOT / output / 'strings/strings.xml'
    strings.parent.mkdir(parents=True, exist_ok=True)
    content=(ROOT / 'resources/strings/strings.xml').read_bytes()
    if not strings.exists() or strings.read_bytes()!=content:
        strings.write_bytes(content)
    print(f'LEGACY_CATALOG: {output}: {len(tree.getroot())} core IDs; PNGs unchanged')

# CIQ 3.x has 254 drawable names per module. Put the four newest themes in
# a resource-only barrel; identical PNGs, separate compile-time namespace.
barrel = ROOT/'bin/scenery-barrel'
(barrel/'source').mkdir(parents=True, exist_ok=True)
(barrel/'source/SceneryPack.mc').write_text('module SceneryPack {}\n')
ns = '{http://www.garmin.com/xml/connectiq}'
ET.register_namespace('iq', ns[1:-1])
manifest = ET.Element(ns+'manifest', version='3')
library = ET.SubElement(manifest, ns+'barrel', id='CEE97E189A055182A483AC7B66506D13', module='SceneryPack', version='1.0.0', minApiLevel='3.2.0')
products = ET.SubElement(library, ns+'products')
for product in ET.parse(ROOT/'manifest.xml').getroot().iter(ns+'product'):
    ET.SubElement(products, ns+'product', id=product.get('id'))
ET.SubElement(library, ns+'permissions')
ET.SubElement(library, ns+'languages')
ET.SubElement(library, ns+'barrels')
ET.SubElement(library, ns+'annotations')
ET.indent(manifest, space='  ')
ET.ElementTree(manifest).write(barrel/'manifest.xml', encoding='unicode')
extra = ('Bamboo', 'Coast', 'Japanese', 'Winter')
for size in (218,240,260,280,390):
    original = ROOT/f'resources-world{size}/drawables.xml'
    terrain = ET.parse(original)
    packed = ET.Element('resources')
    for bitmap in list(terrain.getroot()):
        bitmap.set('filename', (original.parent/bitmap.get('filename')).as_posix())
        if bitmap.get('id').startswith(extra):
            terrain.getroot().remove(bitmap)
            destination = barrel/f'world{size}/drawables'/Path(bitmap.get('filename')).name
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(bitmap.get('filename'), destination)
            bitmap.set('filename', 'drawables/'+destination.name)
            packed.append(bitmap)
    for folder, tree in [(ROOT/f'bin/legacy-world{size}', terrain), (barrel/f'world{size}', ET.ElementTree(packed))]:
        folder.mkdir(parents=True, exist_ok=True)
        ET.indent(tree, space='    ')
        tree.write(folder/'drawables.xml', encoding='unicode')
lines=['project.manifest = manifest.xml', 'base.sourcePath = source']
for line in (ROOT/'monkey.jungle').read_text().splitlines():
    if '.resourcePath' in line and 'bin/legacy-world' in line:
        key, value = line.split('=',1)
        size = re.search(r'legacy-world(\d+)',value).group(1)
        lines.append(f'{key.strip()} = world{size}')
(barrel/'monkey.jungle').write_text('\n'.join(lines)+'\n')
print('LEGACY_SCENERY: 24 app + 16 resource-only barrel IDs; original PNGs unchanged')
