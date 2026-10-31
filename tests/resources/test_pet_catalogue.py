"""Focused catalogue guard; no SDK, image generation or production edits."""
from pathlib import Path
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts"))
from prepare_pet_resources import CATALOGUE, current, render


class PetCatalogueTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "source").mkdir()
        (self.root / "resources/drawables").mkdir(parents=True)
        (self.root / "manifest.xml").write_text('@Drawables.LauncherIcon')
        (self.root / "source/Pet.mc").write_text(
            'var frames=[Rez.Drawables.Pet]; var glance=Rez.Drawables.SleepSmall;')
        (self.root / "source/StateTests.mc").write_text('Rez.Drawables.Historical')
        (self.root / "resources/indirect.xml").write_text('@Drawables.Indirect')
        catalogue = ET.Element("resources")
        for name in ["LauncherIcon", "Pet", "SleepSmall", "Indirect", "Historical"]:
            (self.root / "resources/drawables" / (name + ".png")).write_bytes(name.encode())
            ET.SubElement(catalogue, "bitmap", id=name, filename=name + ".png",
                          scope="glance" if name == "SleepSmall" else "foreground")
        ET.ElementTree(catalogue).write(self.root / "resources/drawables/drawables.xml")
        (self.root / CATALOGUE).parent.mkdir(parents=True)

    def save(self):
        (self.root / CATALOGUE).write_text(render(self.root), encoding="utf-8")

    def test_production_array_indirect_launcher_and_glance_survive(self):
        self.save()
        nodes = ET.parse(self.root / CATALOGUE).getroot()
        self.assertEqual({n.get("id") for n in nodes},
                         {"LauncherIcon", "Pet", "SleepSmall", "Indirect"})
        self.assertEqual(next(n for n in nodes if n.get("id") == "SleepSmall").get("scope"), "glance")
        for node in nodes:
            asset = (self.root / CATALOGUE).parent / node.get("filename")
            self.assertEqual(asset.read_bytes(), node.get("id").encode())
        self.assertTrue((self.root / "resources/drawables/Historical.png").exists())

    def test_missing_referenced_declaration_is_rejected(self):
        self.save()
        tree = ET.parse(self.root / CATALOGUE)
        tree.getroot().remove(next(n for n in tree.getroot() if n.get("id") == "Pet"))
        tree.write(self.root / CATALOGUE)
        self.assertFalse(current(self.root))

    def test_native_profile_xml_reference_survives(self):
        self.save()
        (self.root / "resources-pet144/indirect.xml").write_text('@Drawables.Historical')
        self.assertFalse(current(self.root))
        self.save()
        self.assertIn("Historical", {n.get("id") for n in ET.parse(self.root / CATALOGUE).getroot()})

    def test_new_reference_is_restored_from_canonical_catalogue(self):
        self.save()
        with (self.root / "source/Pet.mc").open("a") as stream:
            stream.write(' var extra=Rez.Drawables.Historical;')
        self.assertFalse(current(self.root))
        self.save()
        self.assertTrue(current(self.root))
        self.assertIn("Historical", {n.get("id") for n in ET.parse(self.root / CATALOGUE).getroot()})


if __name__ == "__main__":
    unittest.main()
