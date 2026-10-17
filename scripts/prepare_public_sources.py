"""Fail-closed build-time removal of owner tools; canonical personal source stays intact."""
import argparse
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def replace(text, old, new=""):
    if text.count(old) != 1:
        raise ValueError(f"Public source boundary changed: {old[:90]}")
    return text.replace(old, new, 1)


def span(text, first, after):
    start = text.index(first)
    end = text.index(after, start)
    return text[:start] + text[end:]


def remove_function(text, name):
    match = re.search(r"(?m)^    function " + name + r"\(", text)
    if not match:
        raise ValueError(f"Missing owner function {name}")
    start = match.start()
    opening = text.index("{", match.end())
    depth = 1
    end = opening + 1
    while depth:
        if text[end] == "{": depth += 1
        if text[end] == "}": depth -= 1
        end += 1
    return text[:start] + text[end:]


def public_source(name, text, tests):
    if name == "TekuTekuBeastState.mc":
        for method in ["enableDev", "setSpeed", "jump", "devSet", "simulateSleep"]:
            text = remove_function(text, method)
        text = replace(text, '    var virtualNow=0l; var anchor=0l; var speed=1;\n')
        text = replace(text, 'function now(){return dev?virtualNow+max(0l,realNow()-anchor)*speed:realNow();}', 'function now(){return realNow();}')
        text = replace(text, '        if(dev && number("forcedStage")>=0){return number("forcedStage");}\n')
        text = replace(text, 'if(dev && number("forcedFamily")>0){return number("forcedFamily");}', '')
        text = replace(text, 'if(s>prior && !(dev && number("forcedStage")>=0))', 'if(s>prior)')
        text = replace(text, 'var testNow=null; var skipWatch=false;', 'var skipWatch=false;')
        text = replace(text, 'function realNow(){return testNow==null?Time.now().value().toLong():testNow;}', 'function realNow(){return Time.now().value().toLong();}')
    if name == "TekuTekuBeastView.mc":
        text = replace(text, 'if(beast.dev){rows.add("Dev Tools");}')
        text = replace(text, '"Developer: "+(beast.dev?"ON":"OFF"),')
        text = span(text, '        else if(menu.equals("Developer"))', '        else if(menu.equals("Play"))')
        text = replace(text, '            if(n==0){openMenu(beast.dev?"Discard DEV?":"Developer");return;}', '            n++; // Public Settings omits the owner-only first row.')
        text = span(text, '        if(context.equals("Developer"))', '        if(context.equals("Collection"))')
        text = replace(text, 'if(beast.dev){rows.add("Sky preview");}')
        text = replace(text, '        else if(menu.equals("Sky preview")){rows=["Real local sky","Dawn","Day","Dusk","Night"];}\n')
        text = replace(text, 'openMenu(n==0?"Environment":(n==1?"Sun / location":"Sky preview"))', 'openMenu(n==0?"Environment":"Sun / location")')
        text = replace(text, '        if(context.equals("Sky preview")){world.preview=n-1;world.invalidate();menu=null;toast(n==0?"REAL SKY":"SKY PREVIEW","look");return true;}\n')
        text = replace(text, ' || menu.equals("Sky preview")')
        text = replace(text, '            else if(menu.equals("Dev Tools")){openMenu("Actions");}else{openMenu(beast.dev?"Dev Tools":"Actions");}', '            else{openMenu("Actions");}')
        text = replace(text, '        devBadge(dc,color);\n')
        text = remove_function(text, 'devBadge')
        text = replace(text, 'beast.dev?"CARE  DEV":"CARE"', '"CARE"')
        text = replace(text, '        if(beast.dev){label(dc,y(dc,0.25),"DEV / TEMPORARY",Graphics.FONT_XTINY);}\n')
        text = replace(text, '        if(beast.dev && tick%4<step){beast.tick();loadSprite();}\n')
    if name == 'BeastWorld.mc':
        text = replace(text, 'var preview=-1;', '')
        text = replace(text, '        if(dev && preview>=0){sample=[preview,preview==2?0.95:(preview==0?0.05:0.5),preview<3];return sample;}\n')
    if name == 'BeastGameView.mc':
        text = re.sub(r'\bdevBadge\([^;]*\);', '', text)
    return text


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--jungle', default='monkey.jungle')
    p.add_argument('--tests', action='store_true')
    args = p.parse_args()
    out = ROOT/'bin/public-build'
    out.mkdir(parents=True, exist_ok=True)
    for folder in ['source', 'legacy-source']:
        destination = out/folder
        destination.mkdir(exist_ok=True)
        source = ROOT/('source' if folder == 'source' else 'bin/legacy-source')
        expected = {p.name for p in source.glob('*.mc') if p.name != 'StateTests.mc'}
        unexpected = {p.name for p in destination.glob('*.mc')} - expected
        if unexpected:
            raise ValueError(f'Unexpected public compilation inputs: {unexpected}')
        for path in source.glob('*.mc'):
            if path.name == 'StateTests.mc':
                continue # Public QA has its own fixture; owner suite stays private.
            text = public_source(path.name, path.read_text(), args.tests)
            forbidden = r'enableDev|devSet|simulateSleep|setSpeed|virtualNow|testNow|Dev Tools|Sky preview|Developer:|DEV / TEMPORARY|\bdev\s*=\s*true'
            if re.search(forbidden, text):
                raise ValueError(f'Owner tool survived public generation: {path.name}')
            (destination/path.name).write_text(text)
    jungle = ROOT/args.jungle
    lines = []
    for line in jungle.read_text().splitlines():
        if '=' in line and not line.lstrip().startswith('#'):
            key, value = line.split('=', 1)
            if key.strip().endswith(('sourcePath', 'resourcePath', 'manifest')):
                paths = []
                for relative in value.strip().split(';'):
                    resolved = (jungle.parent/relative).resolve()
                    if resolved == ROOT/'source': resolved = out/'source'
                    if resolved == ROOT/'bin/legacy-source': resolved = out/'legacy-source'
                    paths.append(resolved.as_posix())
                line = key + '= ' + ';'.join(paths)
        lines.append(line)
    (out/'monkey.jungle').write_text('\n'.join(lines)+'\n')
    print('PUBLIC_INPUT: owner menus, mutations, accelerated clock and sky previews absent')


if __name__ == '__main__':
    main()
