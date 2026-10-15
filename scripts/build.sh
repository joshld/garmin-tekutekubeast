#!/usr/bin/env bash
# Compile TekuTekuBeast for the Enduro 4 after installing Garmin Connect IQ SDK.
set -euo pipefail
cd "$(dirname "$0")/.."
python3 scripts/check_project.py
if ! command -v monkeyc >/dev/null 2>&1; then
    echo "Error: Garmin Connect IQ compiler (monkeyc) not found on PATH." >&2
    echo "Install Connect IQ SDK 9.2.x and Enduro 4 device support first." >&2
    echo "See docs/BUILD.md for setup." >&2
    exit 2
fi
KEY="${CIQ_DEVELOPER_KEY:-}"
if [[ -z "$KEY" || ! -f "$KEY" ]]; then
    echo "Error: set CIQ_DEVELOPER_KEY to your developer_key.der path." >&2
    echo "Generate a key via the official Monkey C VS Code extension." >&2
    exit 2
fi
mkdir -p build
monkeyc -f monkey.jungle -d enduro4 -w -o build/TekuTekuBeast.prg -y "$KEY"
echo "Built build/TekuTekuBeast.prg"
echo "To simulate: start 'connectiq' then run 'monkeydo build/TekuTekuBeast.prg enduro4'"
