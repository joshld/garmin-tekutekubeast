"""Derive the native-96px Pet catalogue from canonical art and live references.

Only declarations are filtered. PNGs and constrained/Fenix catalogues are untouched.
"""
import argparse
import os
from pathlib import Path
import re
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
CATALOGUE = Path("resources-pet144/drawables/drawables.xml")


def references(root=ROOT):
    refs = {"LauncherIcon"}
    for path in (root / "source").glob("*.mc"):
        if path.name not in {"StateTests.mc", "RuleVectors.mc"}:
            refs.update(re.findall(r"Rez\.Drawables\.(\w+)", path.read_text(encoding="utf-8-sig")))
    # Keep indirect resource/manifest references as well as array-selected IDs.
    xml = [root / "manifest.xml"]
    for folder in ("resources", "resources-pet144", "resources-world280"):
        xml.extend((root / folder).rglob("*.xml"))
    for path in xml:
        refs.update(re.findall(r"@(?:Rez\.)?Drawables\.(\w+)", path.read_text(encoding="utf-8-sig")))
    return refs


def render(root=ROOT):
    source = root / "resources/drawables/drawables.xml"
    target = root / CATALOGUE
    tree = ET.parse(source)
    refs = references(root)
    for node in list(tree.getroot()):
        if node.tag == "bitmap" and node.get("id") not in refs:
            tree.getroot().remove(node)
            continue
        for entry in node.iter():
            filename = entry.get("filename")
            if filename is not None:
                asset = source.parent / filename
                # Retain existing local copies when identical; otherwise use
                # canonical pixels without generating or deleting any image.
                local = target.parent / filename
                if not local.is_file() or local.read_bytes() != asset.read_bytes():
                    entry.set("filename", Path(os.path.relpath(asset, target.parent)).as_posix())
    ET.indent(tree, space="    ")
    return ET.tostring(tree.getroot(), encoding="unicode")


def current(root=ROOT):
    path = root / CATALOGUE
    return path.is_file() and path.read_text(encoding="utf-8") == render(root)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    if args.check:
        if not current():
            parser.error("Pet catalogue is stale or missing referenced art; run scripts/prepare_pet_resources.py")
    else:
        rendered = render()
        target = ROOT / CATALOGUE
        if not target.is_file() or target.read_text(encoding="utf-8") != rendered:
            target.write_text(rendered, encoding="utf-8")
    print("PET_CATALOGUE: canonical referenced declarations; PNGs and Fenix unchanged")


if __name__ == "__main__":
    main()
