#!/usr/bin/env python3
"""Fast, SDK-independent structural preflight; NOT a Monkey C compiler."""
from pathlib import Path
import sys
import struct
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "source"
MANIFEST = ROOT / "manifest.xml"
NS = "{http://www.garmin.com/xml/connectiq}"
errors = []

def check(condition, message):
    if not condition:
        errors.append(message)

app = ET.parse(MANIFEST).getroot().find(NS + "application")
check(app is not None, "Application is missing in manifest.xml")
if app is not None:
    check(app.get("entry") == "TekuTekuBeastApp", "Incorrect manifest entry point")
    check(app.get("type") == "watch-app", "App must run natively on the watch")
    check(app.get("id") == "54A4F9D3B6584CA4B01C232D20438E5B", "Application ID changed: save compatibility at risk")
    products = [p.get("id") for p in app.findall(".//" + NS + "product")]
    check("enduro4" in products, "Missing Enduro 4 target")
    permissions = [p.get("id") for p in app.findall(".//" + NS + "uses-permission")]
    check("Background" in permissions, "Background permission required for step events")

strings = ET.parse(ROOT / "resources/strings/strings.xml").getroot()
check(any(n.get("id") == "AppName" and (n.text or "").strip() == "TekuTekuBeast"
          for n in strings.iter("string")), "Incorrect app display name")

expected = ["App", "Input", "Service", "State", "View"]
source = {}
for suffix in expected:
    filename = "TekuTekuBeast" + suffix + ".mc"
    path = SRC / filename
    check(path.is_file(), "Missing " + filename)
    if path.is_file():
        content = path.read_text(encoding="utf-8")
        source[suffix] = content
        check("class TekuTekuBeast" + suffix in content,
              "Missing class in " + filename)

if "App" in source:
    check("Background.registerForStepsEvent" in source["App"], "Missing steps subscription")
if "Service" in source:
    check("function onSteps()" in source["Service"], "Missing step background callback")
    check("Background.exit" in source["Service"], "Missing background exit")
if "State" in source:
    for required in ["ActivityMonitor.getInfo()", "ActivityMonitor.getHistory()",
                     'store.write("v4"', "function mastery()", "function syncToday()"]:
        check(required in source["State"], "Missing expected state feature: " + required)
    check('if(!dev)' in source["State"], "Missing DEV commit guard")
    check('data["xp"]+=delta' in source["State"], "Missing genuine step ledger")
    check('"baseGrowth"' in source["State"], "Missing separate passive growth")

check((ROOT / "monkey.jungle").is_file(), "Missing monkey.jungle")
for module in ["BeastStore", "BeastArt", "BeastGameView", "FeedbackManager", "TekuTekuBeastGlanceView"]:
    check((SRC / (module + ".mc")).is_file(), "Missing v0.4 module: " + module)
glance = (SRC / "TekuTekuBeastGlanceView.mc").read_text(encoding="utf-8")
check("(:glance)" in glance, "Missing glance scope")
check("Storage.setValue" not in glance and "Timer.Timer" not in glance,
      "Glance must remain read-only without an animation timer")
check("function getGlanceView()" in source.get("App", ""), "Missing native Glance entry")
drawables_path = ROOT / "resources/drawables/drawables.xml"
drawables = ET.parse(drawables_path).getroot()
for bitmap in drawables.iter("bitmap"):
    bitmap_path = drawables_path.parent / bitmap.get("filename", "")
    check(bitmap_path.is_file(), "Missing bitmap: " + str(bitmap_path))
    if bitmap.get("id", "").startswith("V4") and bitmap_path.is_file():
        header = bitmap_path.read_bytes()[:24]
        expected_size = 40 if bitmap.get("id").endswith("Small") else 96
        check(struct.unpack(">II", header[16:24]) == (expected_size, expected_size),
              "Wrong sprite size: " + bitmap.get("id"))
        if bitmap.get("id").endswith("Small"):
            check(bitmap.get("scope") == "glance", "Glance sprite has wrong resource scope")
    if bitmap.get("id") == "LauncherIcon" and bitmap_path.is_file():
        header = bitmap_path.read_bytes()[:24]
        check(header[:8] == b"\x89PNG\r\n\x1a\n" and len(header) == 24,
              "Launcher must be a valid PNG")
        if len(header) == 24:
            check(struct.unpack(">II", header[16:24]) == (40, 40),
                  "Enduro 4 launcher must be 40x40")
for native_size in (144, 192):
    native_xml = ROOT / f"resources-native{native_size}/drawables/drawables.xml"
    check(native_xml.is_file(), f"Missing native {native_size}px asset catalog")
    if not native_xml.is_file():
        continue
    for bitmap in ET.parse(native_xml).getroot().iter("bitmap"):
        path = native_xml.parent / bitmap.get("filename", "")
        check(path.is_file(), "Missing native resource: " + str(path))
        resource_id = bitmap.get("id", "")
        if path.is_file() and resource_id.startswith("V4") and not resource_id.endswith("Small"):
            header = path.read_bytes()[:24]
            check(struct.unpack(">II", header[16:24]) == (native_size, native_size),
                  "Wrong native sprite size: " + resource_id)

for directory, size in (("resources",128),("resources-pet144",144),("resources-native144",200),("resources-native192",232)):
    catalog = ROOT / directory / "drawables/drawables.xml"
    check(catalog.is_file(), "Missing v0.5 resource catalog: " + directory)
    if not catalog.is_file():
        continue
    for bitmap in ET.parse(catalog).getroot().iter("bitmap"):
        resource_id = bitmap.get("id", "")
        if not resource_id.startswith("V5"):
            continue
        path = catalog.parent / bitmap.get("filename", "")
        check(path.is_file(), "Missing v0.5 bitmap: " + str(path))
        if path.is_file():
            header = path.read_bytes()[:24]
            expected = 40 if resource_id.endswith("Small") else size
            check(struct.unpack(">II",header[16:24]) == (expected,expected), "Wrong v0.5 bitmap size: " + resource_id)
            if resource_id.endswith("Small"):
                check(bitmap.get("scope") == "glance", "Sleeping Glance sprite lacks glance scope")

if errors:
    print("Preflight FAILED (structural checks only):")
    for e in errors:
        print(" - " + e)
    sys.exit(1)
print("Preflight OK: target, resources, app entry, core step integration.")
print("This script checks structure only; see validation notes for SDK/simulator results.")
