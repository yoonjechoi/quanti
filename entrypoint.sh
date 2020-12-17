#!/usr/bin/env bash
source /usr/local/root/bin/thisroot.sh
export JUPYTER_PATH=/root/.local/share/jupyter
export JUPYTER_CONFIG_DIR=/root/.jupyter
jupyter lab --no-browser --allow-root --ip=0.0.0.0
