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

# 4) Patch your config to:
#    • remove device_map & max_memory (no offloading)
#    • point at /tmp for dataset and prepared output
#    • disable tf32
ORIG_CFG="/app/axolotl_config.yml"
PATCHED_CFG="/tmp/axolotl_config.yml"

sed -e "/^device_map:/d" \
    -e "/^max_memory:/d" \
    -e "s|^datasets:.*|datasets:|g" \
    -e "/^datasets:/a\  - path: $DATA_JSON\n    type: alpaca\n    prompt_style: chat" \
    -e "s|^dataset_prepared_path:.*|dataset_prepared_path: /tmp/prepared_warrungu_chat_dataset|g" \
    -e "s|^tf32:.*|tf32: false|g" \
    "$ORIG_CFG" > "$PATCHED_CFG"

echo "Patched config:"
grep -E "datasets:|dataset_prepared_path:|tf32:" -n "$PATCHED_CFG"

# 5) Prepare the temp folder for tokenized data
mkdir -p /tmp/prepared_warrungu_chat_dataset

# 6) Preprocess
echo "Preprocessing dataset…"
python3 -m axolotl.cli.preprocess --config "$PATCHED_CFG"

# 7) Train
echo "Starting training…"
python3 -m axolotl.cli.train "$PATCHED_CFG"
