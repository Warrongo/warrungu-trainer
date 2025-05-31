#!/usr/bin/env bash
# 1) Point HOME at /tmp (prevent getpwuid)
export HOME=/tmp

# 2) Short‐circuit getpass.getuser() by setting USER/LOGNAME
export USER=hfuser
export LOGNAME=hfuser

# 3) Download the dataset if missing
if [ ! -f "./warrungu_chat_dataset.json" ]; then
  echo "Downloading warrungu_chat_dataset.json..."
  wget -O warrungu_chat_dataset.json \
    https://huggingface.co/spaces/warrungu/warrungu-trainer/resolve/main/warrungu_chat_dataset.json
fi

# 4) Run Axolotl’s preprocess step
echo "Preprocessing dataset with Axolotl..."
python3 -m axolotl.cli.preprocess --config axolotl_config.yml

# 5) Launch training
echo "Starting training..."
python3 run_training.py
