#!/usr/bin/env bash
set -e

# 1) Prevent getpwuid errors
export HOME=/tmp
export USER=hfuser
export LOGNAME=hfuser

# 2) If a token is present, log in to HF
if [ -n "$HF_HUB_TOKEN" ]; then
  echo "Logging in to Hugging Face Hub..."
  huggingface-cli login --token "$HF_HUB_TOKEN"
else
  echo "Warning: HF_HUB_TOKEN is empty; gated repos will fail."
fi

# 3) Download the dataset if missing
if [ ! -f "/tmp/warrungu_chat_dataset.json" ]; then
  echo "Downloading dataset…"
  wget -O /tmp/warrungu_chat_dataset.json \
    https://huggingface.co/spaces/warrungu/warrungu-trainer/resolve/main/warrungu_chat_dataset.json
fi

# 4) Copy & patch your config into /tmp (writable)
TMP_CFG="/tmp/axolotl_config.yml"
cp /app/axolotl_config.yml "$TMP_CFG"

# Redirect prepared data into /tmp
TMP_PREP="/tmp/prepared_warrungu_chat_dataset"
echo "Setting dataset_prepared_path to $TMP_PREP in $TMP_CFG…"
sed -e "s|^dataset_prepared_path:.*|dataset_prepared_path: $TMP_PREP|" \
    -e "s|^\(\s\+path:\).*|\1 /tmp/warrungu_chat_dataset.json|" \
    "$TMP_CFG" > "${TMP_CFG}.patched"
mv "${TMP_CFG}.patched" "$TMP_CFG"

# 5) Ensure the tmp directories exist
mkdir -p "$TMP_PREP"

# 6) Preprocess with Axolotl
echo "Preprocessing dataset with Axolotl using $TMP_CFG..."
python3 -m axolotl.cli.preprocess --config "$TMP_CFG"

# 7) Train
echo "Starting training…"
# either point run_training at the new config:
python3 -m axolotl.cli.train "$TMP_CFG"

