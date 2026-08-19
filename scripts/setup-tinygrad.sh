#!/usr/bin/env bash
set -euo pipefail
cd "${HOME:-/sachs}"
[[ -d tinygrad/.git ]] || git clone https://github.com/tinygrad/tinygrad.git
cd tinygrad
python -m venv .venv
source .venv/bin/activate
pip install -U pip
pip install -e .
