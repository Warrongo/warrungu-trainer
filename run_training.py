# run_training.py
import sys
from axolotl.cli.main import train

if __name__ == "__main__":
    # This is equivalent to running: `axolotl train axolotl_config.yml`
    sys.argv = ["axolotl", "train", "axolotl_config.yml"]
    train()
