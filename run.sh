#!/usr/bin/env bash
set -euo pipefail

# 1) Prevent getpwuid & login quirks
export HOME=/tmp
export USER=hfuser
export LOGNAME=hfuser

# 2) If a token is present, log in to HF
if [ -n "${HF_HUB_TOKEN:-}" ]; then
  echo "Logging in to Hugging Face Hub…"
  huggingface-cli login --token "$HF_HUB_TOKEN"
else
  echo "Warning: HF_HUB_TOKEN is empty; gated repos will fail."
fi

# 3) Download dataset if missing
DATA_JSON=/tmp/warrungu_chat_dataset.json
if [ ! -f "$DATA_JSON" ]; then
  echo "Downloading dataset…"
  curl -fsSL \
    https://huggingface.co/spaces/warrungu/warrungu-trainer/resolve/main/warrungu_chat_dataset.json \
    -o "$DATA_JSON"
fi

# 4) Prepare config paths
export ORIG_CFG=/app/axolotl_config.yml
export PATCHED_CFG=/tmp/axolotl_config.yml

# 5) Patch the YAML for local-only setup
echo "Patching config…"
python3 - <<'PYCODE'
import os, yaml
orig    = os.environ["ORIG_CFG"]
patched = os.environ["PATCHED_CFG"]
with open(orig) as f:
    cfg = yaml.safe_load(f)
# strip offload directives
for key in ("device_map","max_memory","low_cpu_mem_usage","offload_folder"):
    cfg.pop(key, None)
# force GPU 0, disable TF32
cfg["device_map"] = {"": 0}
cfg["tf32"]        = False
# reinstate a valid hub_strategy
cfg["hub_strategy"]      = "every_save"
# point to our JSON dataset
cfg["datasets"] = [{
    "path": "/tmp/warrungu_chat_dataset.json",
    "type": "alpaca",
    "prompt_style": "chat"
}]
cfg["dataset_prepared_path"] = "/tmp/prepared_warrungu_chat_dataset"
with open(patched, "w") as f:
    yaml.safe_dump(cfg, f, sort_keys=False)
print("Patched config written to", patched)
PYCODE

# 6) Prep folder
mkdir -p /tmp/prepared_warrungu_chat_dataset

# 7) Preprocess
echo "Preprocessing dataset…"
python3 -m axolotl.cli.preprocess --config "$PATCHED_CFG"

# 8) Train
echo "Starting training…"
python3 -m axolotl.cli.train "$PATCHED_CFG"
