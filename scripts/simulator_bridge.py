"""Bounded wrapper for the official SDK runner; no UI automation or save edits."""
import argparse
import os
import subprocess
import sys
from pathlib import Path

p=argparse.ArgumentParser()
p.add_argument('--sdk',required=True)
p.add_argument('--java',required=True)
p.add_argument('--program',required=True)
p.add_argument('--device',required=True)
p.add_argument('--temp',required=True)
p.add_argument('--tests',action='store_true')
args=p.parse_args()
sdk=Path(args.sdk)
command=[args.java,f'-Djava.io.tmpdir={args.temp}','-classpath',str(sdk/'bin/monkeybrains.jar'),
         'com.garmin.monkeybrains.monkeydodeux.MonkeyDoDeux','-f',args.program,
         '-d',args.device,'-s',str(sdk/'bin/shell.exe')]
if args.tests:command.append('-t')
process=subprocess.Popen(command,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,
                         creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
glance_capture=Path(args.program).name.startswith('matrix-glance-')
try:
    # A Glance is resident rather than a foreground app; System.exit() does not
    # close the simulator's Glance host. Capture its explicit memory result.
    output,_=process.communicate(timeout=20 if glance_capture else 180)
except subprocess.TimeoutExpired as expired:
    # Kill exactly this test bridge's process tree, never the simulator or any
    # other Java process. This also closes inherited console pipe handles.
    subprocess.run(['taskkill.exe','/PID',str(process.pid),'/T','/F'],capture_output=True)
    try:output,_=process.communicate(timeout=5)
    except subprocess.TimeoutExpired as closing:
        # An inherited SDK pipe may remain open after Java terminates. Do not
        # discard bytes already read from the verified simulator execution.
        output=closing.output or expired.output or b''
    captured=output.decode('utf-8',errors='replace')
    print(captured)
    if glance_capture and 'GLANCE_AUDIT: ' in captured and 'Error' not in captured and 'crash' not in captured:
        print('SDK_GLANCE_CAPTURE_STOPPED')
        sys.exit(0)
    print('SIMULATOR_TIMEOUT')
    sys.exit(2)
text=output.decode('utf-8',errors='replace')
print(text,end='')
if args.tests and 'PASSED (passed=' in text and ', failed=0, errors=0)' in text:
    sys.exit(0)
sys.exit(process.returncode or 0)
