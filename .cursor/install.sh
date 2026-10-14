#!/usr/bin/env bash
# Idempotent dependency setup for the ADUC-SDR (Euia-AducSdr) Gradio app.
# Cloud Agent VMs have no GPU, so torch/torchvision are installed from the
# PyPI CPU index. The rest of the project requirements are installed on top;
# the unpinned `torch`/`torchvision` entries in requirements.txt are then
# already satisfied by the CPU builds installed here.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# The default Ubuntu image ships python3 without the venv/ensurepip module.
# Install it (and ffmpeg, used at runtime for the video editor steps) if missing.
if ! python3 -c "import ensurepip" >/dev/null 2>&1; then
  sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y python3.12-venv
fi
if ! command -v ffmpeg >/dev/null 2>&1; then
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ffmpeg
fi

python3 -m venv .venv
# shellcheck disable=SC1091
source .venv/bin/activate

python -m pip install --upgrade pip wheel setuptools

# CPU-only PyTorch (no CUDA device is present in Cloud Agent VMs).
pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu

# Project dependencies. torch/torchvision are already satisfied above.
pip install -r app/requirements.txt

# requirements.txt leaves `gradio` unpinned, but the app targets the Gradio SDK
# version declared by the Hugging Face Space (app/README.md -> sdk_version).
# Pin it so the UI (e.g. gr.Gallery type="video") matches the code as written.
pip install "gradio==5.42.0"

echo "ADUC-SDR install complete. Virtualenv at ${REPO_ROOT}/.venv"
