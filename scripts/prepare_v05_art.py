"""Trim/re-export existing pixel sprites; no generated or redrawn artwork.

Keep v0.4 resources intact. v0.5.1 Pet poses use the EXACT v0.4 native
canvases/body pixels, including intentional padding. Nimble's detached atlas
bleed is removed without changing its body; mirrored walk copies are reused.
Game poses erase reviewed neighbouring atlas fragments at their existing scale
and origin. Glance resource generation remains unchanged.
"""
from pathlib import Path
from PIL import Image, ImageOps
from pet_art_repair import repair_nimble, repair_game
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
variants = [("resources",96),("resources-pet144",96),
            ("resources-native144",144),("resources-native192",192)]
original = ET.parse(ROOT / "resources/drawables/drawables.xml")
entries = [b for b in original.getroot() if b.get("id", "").startswith("V4") and not b.get("id", "").endswith("Small")]
species = sorted({b.get("id")[:-1] for b in entries})
for folder, extent in variants:
    resource = ROOT / folder
    (resource / "drawables/v05").mkdir(parents=True, exist_ok=True)
    if folder == "resources-pet144":
        (resource / "strings").mkdir(exist_ok=True)
        (resource / "strings/strings.xml").write_bytes((ROOT / "resources/strings/strings.xml").read_bytes())
        tree = ET.parse(ROOT / "resources/drawables/drawables.xml")
        for bitmap in tree.getroot():
            bitmap.set("filename", "../../resources/drawables/" + bitmap.get("filename"))
    else:
        tree = ET.parse(resource / "drawables/drawables.xml")
    for bitmap in list(tree.getroot()):
        if bitmap.get("id", "").startswith("V5"):
            tree.getroot().remove(bitmap)
    for name in species:
        cells = []
        game_cells = []
        for frame in range(6):
            with Image.open(ROOT / f"resources/drawables/v04/{name}{frame}.png") as source:
                rgba = source.convert("RGBA")
                cells.append(rgba.crop(rgba.getbbox()))
                game_cells.append(repair_game(rgba, name[2:], frame).crop(rgba.getbbox()))
        scale = (extent-8) / max(max(c.width,c.height) for c in cells)
        game_extent = 80 if folder in ("resources","resources-pet144") else (128 if folder=="resources-native144" else 144)
        game_scale = (game_extent-8) / max(max(c.width,c.height) for c in cells)
        if name == "V4Egg":
            scale *= .72
        asleep = cells[3].copy()
        asleep.thumbnail((36,36),Image.Resampling.NEAREST)
        tile = Image.new("RGBA",(40,40))
        tile.alpha_composite(asleep,((40-asleep.width)//2,40-asleep.height))
        tile_name = "V5"+name[2:]+"SleepSmall"
        tile.save(resource/f"drawables/v05/{tile_name}.png",optimize=True)
        ET.SubElement(tree.getroot(),"bitmap",{"id":tile_name,"filename":f"v05/{tile_name}.png","scope":"glance","dithering":"none"})
        for frame, cell in enumerate(cells):
            game_cell = game_cells[frame].resize((round(cell.width*game_scale),round(cell.height*game_scale)),Image.Resampling.NEAREST)
            game_canvas = Image.new("RGBA",(game_extent,game_extent))
            game_canvas.alpha_composite(game_cell,((game_extent-game_cell.width)//2,game_extent-game_cell.height-4))
            game_id = "V5Game"+name[2:]+str(frame)
            game_canvas.save(resource/f"drawables/v05/{game_id}.png",optimize=True)
            ET.SubElement(tree.getroot(),"bitmap",{"id":game_id,"filename":f"v05/{game_id}.png","dithering":"none"})
            native = "resources" if folder == "resources-pet144" else folder
            canvas = Image.open(ROOT / native / f"drawables/v04/{name}{frame}.png").convert("RGBA")
            assert canvas.size == (extent, extent)
            if name == "V4Nimble":
                canvas = repair_nimble(canvas)
            for suffix, image in [(str(frame),canvas)]+([(str(frame)+"Left",ImageOps.mirror(canvas))] if frame<2 else []):
                identifier="V5"+name[2:]+suffix
                filename=f"v05/{identifier}.png"
                image.save(resource/"drawables"/filename,optimize=True)
                ET.SubElement(tree.getroot(),"bitmap",{"id":identifier,"filename":filename,"dithering":"none"})
    ET.indent(tree,space="    ")
    tree.write(resource/"drawables/drawables.xml",encoding="unicode")
print("Retained Pet/Glance pixels and sizes; repaired reviewed game atlas bleed at original scale/origin.")
