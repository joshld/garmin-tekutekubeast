"""Contact sheets from actual, unmodified simulator captures, never mockups.

The crop is supplied after inspecting the native simulator window. Originals
remain alongside the sheets; only cropping/layout/labels happen here.
"""
import argparse
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

p = argparse.ArgumentParser()
p.add_argument('--crop', required=True, help='Observed display rectangle: left,top,width,height')
args = p.parse_args()
left, top, width, height = (int(v) for v in args.crop.split(','))
root = Path(__file__).resolve().parents[1] / 'art/store/v0.5.1'
raw = root / 'captures'
font = ImageFont.truetype('C:/Windows/Fonts/consola.ttf', 18)
small = ImageFont.truetype('C:/Windows/Fonts/consola.ttf', 14)

def capture(name):
    image = Image.open(raw / f'{name}.png').convert('RGB')
    assert left >= 0 and top >= 0 and left+width <= image.width and top+height <= image.height
    return image.crop((left, top, left+width, top+height))

def centered(draw, x, y, label, face=font):
    draw.text((x, y), label, font=face, fill='white', anchor='mt')

themes = ('forest', 'meadow', 'lakeside', 'garden')
phases = ('dawn', 'day', 'dusk', 'night')
cell_w, cell_h = width+20, height+58
sheet = Image.new('RGB', (cell_w*4, cell_h*4+68), '#102026')
draw = ImageDraw.Draw(sheet)
centered(draw, sheet.width/2, 10, 'v0.5.1 - actual Enduro 4 simulator QA captures')
centered(draw, sheet.width/2, 36, 'Production renderer; in-memory Pip; DEV sky previews; sleep OFF', small)
for row, theme in enumerate(themes):
    for col, phase in enumerate(phases):
        x, y = col*cell_w+10, row*cell_h+78
        sheet.paste(capture(f'enduro4-{theme}-{phase}'), (x, y))
        centered(draw, x+width/2, y+height+8, f'{theme.title()} / {phase.title()}')
sheet.save(root / 'worlds-contact-sheet.png')

comparison = Image.new('RGB', (cell_w*3, height+132), '#102026')
draw = ImageDraw.Draw(comparison)
centered(draw, comparison.width/2, 8, 'Exact historical pixel scale vs restored v0.5.1')
labels = ('v0.4 original pixels', 'v0.5 enlarged pixels', 'v0.5.1 original size')
names = ('enduro4-v04-pixels', 'enduro4-v05-pixels', 'enduro4-forest-day')
for col, (name, label) in enumerate(zip(names, labels)):
    x = col*cell_w+10
    comparison.paste(capture(name), (x, 42))
    centered(draw, x+width/2, height+52, label)
centered(draw, comparison.width/2, height+91, 'Historical assets re-rendered in QA, not historical full-release UI.', small)
centered(draw, comparison.width/2, height+111, 'Same native 280px display crop; no rescaling or AI alterations.', small)
comparison.save(root / 'size-comparison.png')
print('Saved contact sheets from 18 real simulator captures; raw originals retained.')
