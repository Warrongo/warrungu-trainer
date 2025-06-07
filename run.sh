#!/usr/bin/env bash
set -e

# 1) Avoid getpwuid & login quibbles
export HOME=/tmp
export USER=hfuser
export LOGNAME=hfuser

if [ -n "$HF_HUB_TOKEN" ]; then
  echo "Logging in to Hugging Face Hub…"
  huggingface-cli login --token "$HF_HUB_TOKEN"
else
  echo "Warning: HF_HUB_TOKEN is empty; gated repos will fail."
fi

# 2) Download dataset if needed
DATA_JSON=/tmp/warrungu_chat_dataset.json
if [ ! -f "$DATA_JSON" ]; then
  echo "Downloading dataset…"
  curl -fsSL \
    https://huggingface.co/spaces/warrungu/warrungu-trainer/resolve/main/warrungu_chat_dataset.json \
    -o "$DATA_JSON"
fi

# 3) Patch your config so nothing is offloaded and tf32=false
ORIG_CFG=/app/axolotl_config.yml
PATCHED_CFG=/tmp/axolotl_config.yml

python3 - <<'PYCODE'
import os, yaml

orig = os.environ["ORIG_CFG"]
patched = os.environ["PATCHED_CFG"]

with open(orig) as f:
    cfg = yaml.safe_load(f)

# remove any offload directives
for key in ("device_map", "max_memory", "low_cpu_mem_usage", "offload_folder"):
    cfg.pop(key, None)

# force entire model on GPU 0
cfg["device_map"] = {"": 0}
# disable tf32 unless you have Ampere+ hardware
cfg["tf32"] = False

# point at our in‐container dataset
cfg["datasets"] = [{
    "path": "/tmp/warrungu_chat_dataset.json",
    "type": "alpaca",
    "prompt_style": "chat"
}]
cfg["dataset_prepared_path"] = "/tmp/prepared_warrungu_chat_dataset"

# update hub settings to your namespace
cfg["hub_model_id"] = "warrungu/warrungu-mistral-chat-ai"
cfg["hub_private_repo"] = True

with open(patched, "w") as f:
    yaml.safe_dump(cfg, f, sort_keys=False)
print("Patched config written to", patched)
PYCODE

# 4) Make sure the prep folder exists
mkdir -p /tmp/prepared_warrungu_chat_dataset

# 5) Preprocess
echo "Preprocessing dataset with patched config…"
python3 -m axolotl.cli.preprocess --config "$PATCHED_CFG"

# 6) Train
echo "Starting training…"
python3 -m axolotl.cli.train "$PATCHED_CFG"
