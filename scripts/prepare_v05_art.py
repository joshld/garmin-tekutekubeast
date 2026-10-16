"""Trim/re-export existing pixel sprites; no generated or redrawn artwork.

Keep v0.4 resources intact for Glance/games. Compile larger native Pet resources
and two mirrored walking poses, avoiding palette-bitmap transforms at runtime.
"""
from pathlib import Path
from PIL import Image, ImageOps
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
variants = [("resources",128),("resources-pet144",144),
            ("resources-native144",200),("resources-native192",232)]
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
        for frame in range(6):
            with Image.open(ROOT / f"resources/drawables/v04/{name}{frame}.png") as source:
                rgba = source.convert("RGBA")
                cells.append(rgba.crop(rgba.getbbox()))
        scale = (extent-8) / max(max(c.width,c.height) for c in cells)
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
            resized = cell.resize((round(cell.width*scale),round(cell.height*scale)),Image.Resampling.NEAREST)
            canvas = Image.new("RGBA", (extent,extent))
            canvas.alpha_composite(resized,((extent-resized.width)//2,extent-resized.height-4))
            for suffix, image in [(str(frame),canvas)]+([(str(frame)+"Left",ImageOps.mirror(canvas))] if frame<2 else []):
                identifier="V5"+name[2:]+suffix
                filename=f"v05/{identifier}.png"
                image.save(resource/"drawables"/filename,optimize=True)
                ET.SubElement(tree.getroot(),"bitmap",{"id":identifier,"filename":filename,"dithering":"none"})
    ET.indent(tree,space="    ")
    tree.write(resource/"drawables/drawables.xml",encoding="unicode")
print("Prepared 15 padded-trimmed species, native Pet sizes and mirrored walking poses.")
