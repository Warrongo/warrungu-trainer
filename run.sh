#!/usr/bin/env bash
set -e

# 1) Prevent getpwuid errors
export HOME=/tmp
export USER=hfuser
export LOGNAME=hfuser

# 2) If a token is present, log in to HF
if [ -n "$HF_HUB_TOKEN" ]; then
  echo "Logging in to Hugging Face Hub..."
  echo "$HF_HUB_TOKEN" | huggingface-cli login --token
else
  echo "Warning: HF_HUB_TOKEN is empty, gated repos will fail."
fi

# 3) Download the dataset if missing
if [ ! -f "./warrungu_chat_dataset.json" ]; then
  echo "Downloading dataset…"
  wget -O warrungu_chat_dataset.json \
    https://huggingface.co/spaces/warrungu/warrungu-trainer/resolve/main/warrungu_chat_dataset.json
fi

# 4) Preprocess
echo "Preprocessing dataset with Axolotl..."
python3 -m axolotl.cli.preprocess --config axolotl_config.yml

# 5) Train
echo "Starting training…"
python3 run_training.py
