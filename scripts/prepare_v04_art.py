"""Deterministic conversion of generated atlas originals; no sprite drawing."""
from pathlib import Path
from PIL import Image
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / 'resources/drawables/v04'
DEST.mkdir(parents=True, exist_ok=True)
resources = ET.parse(ROOT / 'resources/drawables/drawables.xml')
root = resources.getroot()
for bitmap in list(root):
    if bitmap.get('id', '').startswith('V4'):
        root.remove(bitmap)

def palette(image):
    return image.point(lambda value: min(255, ((value + 42) // 85) * 85))

def output(image, name, size):
    canvas = Image.new('RGBA', (size, size))
    canvas.alpha_composite(image, ((size-image.width)//2, size-image.height))
    canvas.save(DEST / f'{name}.png', optimize=True)
    attrs = {'id':name, 'filename':f'v04/{name}.png', 'dithering':'none'}
    if name.endswith('Small'): attrs['scope']='glance'
    ET.SubElement(root, 'bitmap', **attrs)

names = ['Egg', 'Pip', 'Nimble']
egg = Image.open(ROOT / 'resources/drawables/egg.png').convert('RGBA')
egg = egg.crop(egg.getbbox()).resize((32, 42), Image.Resampling.NEAREST)
for frame in range(6):
    output(egg.resize((64,84),Image.Resampling.NEAREST), f'V4Egg{frame}', 96)
output(egg, 'V4EggSmall', 40)

for family, rows in [('shared',2),('grove',3),('ember',3),('tide',3),('wisp',3)]:
    atlas = Image.open(ROOT / f'art/source/v04/{family}-expressive.png').convert('RGBA')
    cellw, cellh = atlas.width / 6, atlas.height / rows
    for row in range(rows):
        name = ['Pip','Nimble'][row] if family=='shared' else family.title()+str(row+3)
        if family!='shared': names.append(name)
        cells=[]
        for col in range(6):
            cell=atlas.crop((round(col*cellw),round(row*cellh),round((col+1)*cellw),round((row+1)*cellh)))
            alpha=cell.getchannel('A').point(lambda a:255 if a>=128 else 0)
            cell.putalpha(alpha)
            bounds=alpha.getbbox()
            if not bounds: raise ValueError(f'Empty {name} frame {col}')
            cells.append(cell.crop(bounds))
        # Same scale across poses preserves relative height of a curled sleeper.
        scale=min(44/max(c.width for c in cells),44/max(c.height for c in cells))
        for frame, cell in enumerate(cells):
            small=cell.resize((max(1,round(cell.width*scale)),max(1,round(cell.height*scale))),Image.Resampling.NEAREST)
            rgb=palette(small.convert('RGB'));rgb.putalpha(small.getchannel('A'))
            output(rgb.resize((rgb.width*2,rgb.height*2),Image.Resampling.NEAREST),f'V4{name}{frame}',96)
            if frame==0:
                tiny=rgb.copy();tiny.thumbnail((36,36),Image.Resampling.NEAREST)
                output(tiny,f'V4{name}Small',40)

ET.indent(resources,space='    ')
resources.write(ROOT/'resources/drawables/drawables.xml',encoding='unicode')
Image.open(DEST/'V4PipSmall.png').save(ROOT/'resources/drawables/beast-launcher.png')
# Transformed palette bitmaps are unsupported on some AMOLED renderers. Compile
# nearest-neighbour native-size assets instead of scaling them on the watch.
for size in (144,192):
    variant=ROOT/f'resources-native{size}'
    (variant/'drawables/v04').mkdir(parents=True,exist_ok=True)
    (variant/'strings').mkdir(parents=True,exist_ok=True)
    (variant/'strings/strings.xml').write_bytes((ROOT/'resources/strings/strings.xml').read_bytes())
    derived=ET.parse(ROOT/'resources/drawables/drawables.xml')
    for bitmap in derived.getroot():
        filename=bitmap.get('filename','')
        if bitmap.get('id','').startswith('V4') and not bitmap.get('id','').endswith('Small'):
            image=Image.open(ROOT/'resources/drawables'/filename)
            image.resize((size,size),Image.Resampling.NEAREST).save(variant/'drawables'/filename,optimize=True)
        else:
            bitmap.set('filename','../../resources/drawables/'+filename)
    ET.indent(derived,space='    ')
    derived.write(variant/'drawables/drawables.xml',encoding='unicode')
print(f'Prepared {len(names)} species, six poses each, plus glance sprites.')
