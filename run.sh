#!/usr/bin/env bash
set -e

echo "Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

echo "Preprocessing dataset with Axolotl..."
python3 -m axolotl.cli.preprocess --config axolotl_config.yml

echo "Starting Axolotl training..."
python3 -m axolotl.cli.train --config axolotl_config.yml
