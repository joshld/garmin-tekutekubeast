"""Build-only scope variant, never a fork of the gameplay implementation.

CIQ 3.x loads background code before calling a delegate: a runtime memory guard
cannot prevent the loader OOM. Strip only the background scope markers from the
unchanged State/Store classes and supply a tiny stale-registration cleanup
delegate. Higher-budget devices compile the original sources unchanged.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'bin/legacy-source'
OUT.mkdir(parents=True, exist_ok=True)
for path in (ROOT/'source').glob('*.mc'):
    text = path.read_text()
    if path.name in ('TekuTekuBeastState.mc', 'BeastStore.mc', 'BeastProgression.mc', 'BeastActivityRules.mc', 'GarminActivity.mc', 'BeastGameRules.mc'):
        assert text.count('(:background)') == 1
        text = text.replace('(:background)', '// Foreground-only scope on constrained profiles.', 1)
    if path.name == 'TekuTekuBeastService.mc':
        text = (ROOT/'source/DeferredService.mc.template').read_text()
    if path.name == 'BeastScenery.mc':
        for theme in ('Bamboo','Coast','Japanese','Winter'):
            text = text.replace('Rez.Drawables.'+theme, 'SceneryPack.Rez.Drawables.'+theme)
    target=OUT/path.name
    if not target.exists() or target.read_text()!=text:
        target.write_text(text)
print('LEGACY_SCOPE: generated from current source; State/Store excluded from background')
