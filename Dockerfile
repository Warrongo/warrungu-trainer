#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────────────────────
# 1) Prevent getpwuid & login quirks
export HOME=/tmp
export USER=hfuser
export LOGNAME=hfuser

# ──────────────────────────────────────────────────────────────────────────────
# 2) If you passed a token, log in to HF
if [ -n "${HF_HUB_TOKEN:-}" ]; then
  echo "Logging in to Hugging Face Hub…"
  huggingface-cli login --token "$HF_HUB_TOKEN"
else
  echo "Warning: HF_HUB_TOKEN is empty; gated repos will fail."
fi

# ──────────────────────────────────────────────────────────────────────────────
# 3) Download the dataset if missing
DATA_JSON=/tmp/warrungu_chat_dataset.json
if [ ! -f "$DATA_JSON" ]; then
  echo "Downloading dataset…"
  curl -fsSL \
    https://huggingface.co/spaces/warrungu/warrungu-trainer/resolve/main/warrungu_chat_dataset.json \
    -o "$DATA_JSON"
fi

# ──────────────────────────────────────────────────────────────────────────────
# 4) Prepare paths for config patching
export ORIG_CFG=/app/axolotl_config.yml
export PATCHED_CFG=/tmp/axolotl_config.yml

# ──────────────────────────────────────────────────────────────────────────────
# 5) Patch the YAML so nothing is offloaded & tf32=false & correct paths
echo "Patching config…"
python3 - <<'PYCODE'
import os, yaml

orig = os.environ["ORIG_CFG"]
patched = os.environ["PATCHED_CFG"]

with open(orig) as f:
    cfg = yaml.safe_load(f)

# Remove offload directives
for key in ("device_map", "max_memory", "low_cpu_mem_usage", "offload_folder"):
    cfg.pop(key, None)

# Force entire model on GPU 0
cfg["device_map"] = {"": 0}
# Disable TF32 in case you’re not on Ampere+
cfg["tf32"] = False

# Point to our downloaded JSON
cfg["datasets"] = [{
    "path": "/tmp/warrungu_chat_dataset.json",
    "type": "alpaca",
    "prompt_style": "chat"
}]

# Write tokens here
cfg["dataset_prepared_path"] = "/tmp/prepared_warrungu_chat_dataset"

with open(patched, "w") as f:
    yaml.safe_dump(cfg, f, sort_keys=False)

print("Patched config written to", patched)
PYCODE

# ──────────────────────────────────────────────────────────────────────────────
# 6) Make sure the prep folder is writable
mkdir -p /tmp/prepared_warrungu_chat_dataset

# ──────────────────────────────────────────────────────────────────────────────
# 7) Preprocess
echo "Preprocessing dataset with Axolotl…"
python3 -m axolotl.cli.preprocess --config "$PATCHED_CFG"

# ──────────────────────────────────────────────────────────────────────────────
# 8) Train
echo "Starting training…"
python3 -m axolotl.cli.train "$PATCHED_CFG"
