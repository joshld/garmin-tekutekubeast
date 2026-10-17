"""Combine current executed results; promote only explicit native passes.

Does not run tests, infer a pass from a build or silently include an untested
candidate. Earlier failed attempts remain in ignored logs; later focused results
replace only that same device's row.
"""
import argparse
import csv
import json
import os
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
p = argparse.ArgumentParser()
p.add_argument('--promote', action='store_true')
args = p.parse_args()
targets = json.loads((ROOT/'scripts/compatibility_candidates.json').read_text())
results = {}
for prefix in ['compat-representatives','compat-218-final','compat-new']:
    path = ROOT/'bin'/f'{prefix}-device-matrix.json'
    if path.exists():
        records = json.loads(path.read_text(encoding='utf-8-sig'))
        if isinstance(records, dict): records = [records]
        for record in records: results[record['device']] = record
accepted = []
held = {'venu2','venu2s','venu2plus'}
rows = []
for name, (size, kind, deferred) in targets.items():
    result = results.get(name, {})
    good = result.get('unit') == 'PASS' and result.get('layout') == 'PASS' and result.get('tests') == 33 and result.get('peak',1) < result.get('total',0)
    if good and name not in held: accepted.append(name)
    device = Path(os.environ['APPDATA'])/'Garmin/ConnectIQ/Devices'/name
    compiler = json.loads((device/'compiler.json').read_text())
    simulator = json.loads((device/'simulator.json').read_text())
    rows.append(dict(profile=name, api=compiler['deviceGroup'], display=f'{size}px {compiler["displayType"]}',
        input=f'{len(simulator["keys"])} buttons'+(' + touch' if simulator['display']['isTouch'] else ''),
        activity='foreground catch-up' if deferred else 'background + foreground',
        status='PASS' if good else ('FAIL' if result else 'NOT RUN'),
        release='HELD: background/input acceptance outstanding' if name in held else ('INCLUDED' if good else 'EXCLUDED'),
        tests=result.get('tests',''), scenes=983 if good and name in ['fenix6spro','fr265s','fr255s'] else (473 if good else ''),
        sampled_peak=result.get('peak',''), usable_bytes=result.get('total',''),
        reason=str(result.get('error',''))[:400]))
out = ROOT/'docs/compatibility'
out.mkdir(parents=True, exist_ok=True)
with (out/'sdk-results.csv').open('w',newline='',encoding='utf-8') as f:
    writer=csv.DictWriter(f,fieldnames=list(rows[0]));writer.writeheader();writer.writerows(rows)
if args.promote:
    ns='{http://www.garmin.com/xml/connectiq}'
    ET.register_namespace('iq',ns[1:-1])
    path=ROOT/'manifest.xml';tree=ET.parse(path)
    products=tree.getroot().find(f'{ns}application/{ns}products')
    existing={x.get('id') for x in products}
    for name in accepted:
        if name not in existing: ET.SubElement(products,ns+'product',id=name)
    # Failed candidates must never have been advertised by this work.
    for name in targets:
        if name not in accepted and name in existing: raise SystemExit(f'Refusing promotion: {name} has no accepted native result')
    ET.indent(tree,space='  ');tree.write(path,encoding='unicode')
    print(f'PROMOTED: {len(accepted)} newly validated candidates; existing profiles preserved')
print(f'COMPATIBILITY: {len(accepted)}/{len(targets)} candidates accepted for release; CSV records actual coverage')
