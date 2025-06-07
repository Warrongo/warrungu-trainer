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

# 4) Rewrite your YAML config safely with Python
ORIG="/app/axolotl_config.yml"
PATCHED="/tmp/axolotl_config.yml"
python3 - <<'PYCODE'
import yaml
cfg = yaml.safe_load(open("$(printf '%s' "$ORIG")"))
# Remove any offloading
cfg.pop("device_map", None)
cfg.pop("max_memory", None)
# Point at our downloaded JSON
cfg["datasets"] = [{"path": "/tmp/warrungu_chat_dataset.json",
                    "type": "alpaca",
                    "prompt_style": "chat"}]
# Write prepared data into /tmp so it's writable
cfg["dataset_prepared_path"] = "/tmp/prepared_warrungu_chat_dataset"
# Turn tf32 off if your GPU doesn’t support it
cfg["tf32"] = False
with open("$(printf '%s' "$PATCHED")", "w") as f:
    yaml.safe_dump(cfg, f)
PYCODE

echo "Patched config written to $PATCHED:"
grep -nE "datasets:|dataset_prepared_path:|tf32:" "$PATCHED"

# 5) Prep the output directory
mkdir -p /tmp/prepared_warrungu_chat_dataset

# 6) Preprocess
echo "Preprocessing dataset…"
python3 -m axolotl.cli.preprocess --config "$PATCHED"

# 7) Train
echo "Starting training…"
python3 -m axolotl.cli.train "$PATCHED"
