#!/usr/bin/env bash
set -e

# 1) Prevent getpwuid errors
export HOME=/tmp
export USER=hfuser
export LOGNAME=hfuser

# 2) If a token is present, log in to Hugging Face
if [ -n "$HF_HUB_TOKEN" ]; then
  echo "Logging in to Hugging Face Hub..."
  huggingface-cli login --token "$HF_HUB_TOKEN"
else
  echo "Warning: HF_HUB_TOKEN is empty; gated repos will fail."
fi

# 3) Download the dataset if missing
if [ ! -f "./warrungu_chat_dataset.json" ]; then
  echo "Downloading dataset…"
  wget -O warrungu_chat_dataset.json \
    https://huggingface.co/spaces/warrungu/warrungu-trainer/resolve/main/warrungu_chat_dataset.json
fi

# 4) Redirect prepared‐data into a writable /tmp folder
TMP_PREP="/tmp/prepared_warrungu_chat_dataset"
echo "Patching axolotl_config.yml to use $TMP_PREP as dataset_prepared_path…"
# This sed replaces the dataset_prepared_path line
sed -i 's|^dataset_prepared_path:.*|dataset_prepared_path: '"$TMP_PREP"'|' axolotl_config.yml

# 5) Make sure /tmp/prepared_warrungu_chat_dataset exists
echo "Ensuring $TMP_PREP exists and is empty…"
rm -rf "$TMP_PREP"
mkdir -p "$TMP_PREP"

# 6) Preprocess with Axolotl
echo "Preprocessing dataset with Axolotl..."
python3 -m axolotl.cli.preprocess --config axolotl_config.yml

# 7) Launch training
echo "Starting training…"
python3 run_training.py

