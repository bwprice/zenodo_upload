#!/bin/bash
#
# Wrapper script to submit multiple Zenodo uploads to Slurm using a config file
#
# Usage: ./submit_zenodo_uploads.sh [path/to/config_file]
#        ./submit_zenodo_uploads.sh zenodo_config.sh
#
# If no config file is specified, it looks for zenodo_config.sh in the same directory
#

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Determine config file location
if [ $# -eq 1 ]; then
    CONFIG_FILE="$1"
else
    CONFIG_FILE="${SCRIPT_DIR}/zenodo_config.sh"
fi

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not found: $CONFIG_FILE"
    echo ""
    echo "Usage: $0 [path/to/config_file]"
    echo "Or place zenodo_config.sh in the same directory as this script"
    exit 1
fi

# Source the config file to load variables
echo "Loading configuration from: $CONFIG_FILE"
source "$CONFIG_FILE"

# Validate required variables
if [ -z "$ZENODO_TOKEN" ]; then
    echo "Error: ZENODO_TOKEN not set in config file"
    exit 1
fi

if [ -z "$DEPOSITION_ID" ]; then
    echo "Error: DEPOSITION_ID not set in config file"
    exit 1
fi

if [ ${#FILES[@]} -eq 0 ]; then
    echo "Error: No files specified in FILES array in config file"
    exit 1
fi

echo ""
echo "=========================================="
echo "Zenodo Upload Batch Submission"
echo "=========================================="
echo "Deposition ID: $DEPOSITION_ID"
echo "Number of files: ${#FILES[@]}"
echo "Upload script: ${SCRIPT_DIR}/zenodo_upload.sh"
echo "Verbose mode: $VERBOSE"
echo ""

# Counter for submitted jobs
JOB_COUNT=0
PREVIOUS_JOB_ID=""

# Loop through all files in the FILES array
for FILEPATH in "${FILES[@]}"; do
    # Check if file exists
    if [ ! -f "$FILEPATH" ]; then
        echo "Warning: File not found, skipping: $FILEPATH"
        continue
    fi
    
    # Get just the filename for display
    FILENAME=$(basename "$FILEPATH")
    
    # Build the sbatch command with dependencies
    SBATCH_CMD="sbatch --export=DEPOSITION_ID=$DEPOSITION_ID,FILEPATH=$FILEPATH,VERBOSE=$VERBOSE,ZENODO_TOKEN=$ZENODO_TOKEN --job-name=zenodo_${FILENAME}"
    
    # If there's a previous job, make this one depend on it
    if [ -n "$PREVIOUS_JOB_ID" ]; then
        SBATCH_CMD="$SBATCH_CMD --dependency=afterok:$PREVIOUS_JOB_ID"
    fi
    
    # Submit the job
    JOB_ID=$($SBATCH_CMD "${SCRIPT_DIR}/zenodo_upload.sh" | awk '{print $4}')
    
    if [ -n "$PREVIOUS_JOB_ID" ]; then
        echo "✓ Submitted: $FILENAME (Job ID: $JOB_ID, waits for Job $PREVIOUS_JOB_ID)"
    else
        echo "✓ Submitted: $FILENAME (Job ID: $JOB_ID, starts immediately)"
    fi
    
    # Store this job ID for the next iteration
    PREVIOUS_JOB_ID=$JOB_ID
    ((JOB_COUNT++))
done

echo ""
echo "=========================================="
echo "Total jobs submitted: $JOB_COUNT"
echo "=========================================="
echo ""
echo "Monitor your jobs with: squeue -u $USER"
echo "Check output files: zenodo_[jobid].out"
echo "Check error files: zenodo_[jobid].err"
