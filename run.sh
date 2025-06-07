#!/usr/bin/env bash
set -euo pipefail

# 1) Prevent getpwuid errors
export HOME=/tmp
export USER=hfuser
export LOGNAME=hfuser

# 2) Log in to HF if you provided a token
if [[ -n "${HF_HUB_TOKEN:-}" ]]; then
  echo "Logging in to Hugging Face Hub…"
  huggingface-cli login --token "$HF_HUB_TOKEN"
else
  echo "⚠️  HF_HUB_TOKEN is empty; gated repos will fail!"
fi

# 3) Download the dataset (if missing)
DATA_JSON="/tmp/warrungu_chat_dataset.json"
if [[ ! -f "$DATA_JSON" ]]; then
  echo "Downloading dataset…"
  curl --fail -L \
    "https://huggingface.co/spaces/warrungu/warrungu-trainer/resolve/main/warrungu_chat_dataset.json" \
    -o "$DATA_JSON"
fi

# 4) Prepare paths for Python patch
export ORIG_CFG="/app/axolotl_config.yml"
export PATCHED_CFG="/tmp/axolotl_config.yml"

# 5) Rewrite your YAML config safely with Python
python3 - <<'PYCODE'
import os, yaml

orig = os.environ["ORIG_CFG"]
patched = os.environ["PATCHED_CFG"]

cfg = yaml.safe_load(open(orig))

# Drop any offloading directives (keep model fully on GPU)
cfg.pop("device_map", None)
cfg.pop("max_memory", None)

# Point to our downloaded JSON
cfg["datasets"] = [{
    "path": "/tmp/warrungu_chat_dataset.json",
    "type": "alpaca",
    "prompt_style": "chat"
}]

# Write prepared data into /tmp so it's writable
cfg["dataset_prepared_path"] = "/tmp/prepared_warrungu_chat_dataset"

# Turn tf32 off if your GPU doesn’t support it
cfg["tf32"] = False

with open(patched, "w") as f:
    yaml.safe_dump(cfg, f)
PYCODE

echo "Patched config written to $PATCHED_CFG:"
grep -nE "datasets:|dataset_prepared_path:|tf32:" "$PATCHED_CFG"

# 6) Prep the output directory
mkdir -p /tmp/prepared_warrungu_chat_dataset

# 7) Preprocess
echo "Preprocessing dataset…"
python3 -m axolotl.cli.preprocess --config "$PATCHED_CFG"

# 8) Train
echo "Starting training…"
python3 -m axolotl.cli.train "$PATCHED_CFG"
