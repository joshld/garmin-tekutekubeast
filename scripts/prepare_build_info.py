"""Small compile-time identity-independent version/channel module."""
import argparse,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def render():
    version=json.loads((ROOT/'config/build-identities.json').read_text())['version']
    return '// Generated from config/build-identities.json; public preparation selects stable.\nmodule BeastBuild {\n    const VERSION='+json.dumps(version)+';\n    const LABEL='+json.dumps('Version '+version+' beta')+';\n    const CHANNEL="beta";\n}\n'
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--check',action='store_true');args=p.parse_args()
    path=ROOT/'source/BeastBuild.mc';expected=render()
    if args.check:
        if not path.exists() or path.read_text(encoding='utf8')!=expected:raise SystemExit('Build version metadata is stale; run scripts/prepare_build_info.py')
    else:path.write_text(expected,encoding='utf8')
