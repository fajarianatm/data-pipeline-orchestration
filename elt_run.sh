#!/bin/bash

echo "========== Start Orcestration Process =========="

# Virtual Environment Path
VENV_PATH="/Users/fajarianatm/exc/olist_data-pipeline-orchestration/.venv/bin/activate"

# Activate Virtual Environment
source "$VENV_PATH"

# Set Python script
PYTHON_SCRIPT="/Users/fajarianatm/exc/olist_data-pipeline-orchestration/elt_main.py"

# Run Python Script 
python3 "$PYTHON_SCRIPT"


echo "========== End of Orcestration Process =========="