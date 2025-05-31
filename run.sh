#!/usr/bin/env bash

# 1) Point HOME at /tmp (prevent getpwuid for “home”)
export HOME=/tmp

# 2) Short‐circuit getpass.getuser() by setting USER/LOGNAME
export USER=hfuser
export LOGNAME=hfuser

# 3) Now run Axolotl’s preprocess step
python3 -m axolotl.cli.preprocess --config axolotl_config.yml

# 4) Then launch training (or whatever follows)
python3 run_training.py
