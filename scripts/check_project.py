#!/usr/bin/env python3
"""Fast, SDK-independent structural preflight; NOT a Monkey C compiler."""
from pathlib import Path
import sys
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
    check(len(app.get("id", "")) == 32, "Keep 32-character app ID for saved game compatibility")
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
        check("StepPal" not in content, "Stale class name in " + filename)

if "App" in source:
    check("Background.registerForStepsEvent" in source["App"], "Missing steps subscription")
if "Service" in source:
    check("function onSteps()" in source["Service"], "Missing step background callback")
    check("Background.exit" in source["Service"], "Missing background exit")
if "State" in source:
    for required in ["ActivityMonitor.getInfo()", "ActivityMonitor.getHistory()",
                     "Storage.setValue", "function mastery()", "function syncToday()"]:
        check(required in source["State"], "Missing expected state feature: " + required)

check((ROOT / "monkey.jungle").is_file(), "Missing monkey.jungle")
check((ROOT / "resources/drawables/launcher.png").is_file(), "Missing launcher icon")
if errors:
    print("Preflight FAILED (structural checks only):")
    for e in errors:
        print(" - " + e)
    sys.exit(1)
print("Preflight OK: target, resources, app entry, core step integration.")
print("NOTE: Monkey C compilation/simulator execution has NOT been performed.")
