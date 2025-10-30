#!/bin/bash
#SBATCH --partition=day
#SBATCH --output=zenodo_%j.out
#SBATCH --error=zenodo_%j.err
#SBATCH --mem=2G
#SBATCH --cpus-per-task=1
#SBATCH --mail-user=you@email.com
#SBATCH --mail-type=ALL

# Upload big files to Zenodo.
#
# This script is submitted via the wrapper script: submit_zenodo_uploads.sh
# Environment variables required: DEPOSITION_ID, FILEPATH, ZENODO_TOKEN, VERBOSE (optional)
#

# Activate conda env
# Initialize conda (adjust path if your conda is installed elsewhere)
if [ -f "/home/benjp/miniconda3/etc/profile.d/conda.sh" ]; then
    source "/home/benjp/miniconda3/etc/profile.d/conda.sh"
elif [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
    source "$HOME/miniconda3/etc/profile.d/conda.sh"
elif [ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]; then
    source "$HOME/anaconda3/etc/profile.d/conda.sh"
elif [ -f "/opt/conda/etc/profile.d/conda.sh" ]; then
    source "/opt/conda/etc/profile.d/conda.sh"
fi

# Activate the zenodo environment
conda activate zenodo

# ZENODO_TOKEN should be passed via environment variable from the wrapper script
# No need to hardcode it here

set -xe

# Use environment variables instead of positional arguments
VERBOSE=${VERBOSE:-0}

# strip deposition url prefix if provided
DEPOSITION=$( echo $DEPOSITION_ID | sed 's+^http[s]*://zenodo.org/deposit/++g' )
FILENAME=$(echo $FILEPATH | sed 's+.*/++g')
FILENAME=${FILENAME// /%20}
ZENODO_ENDPOINT=${ZENODO_ENDPOINT:-https://zenodo.org}

BUCKET=$(curl ${ZENODO_ENDPOINT}/api/deposit/depositions/"$DEPOSITION"?access_token="$ZENODO_TOKEN" | jq --raw-output .links.bucket)

if [ "$VERBOSE" -eq 1 ]; then
    echo "Deposition ID: $DEPOSITION"
    echo "File path: $FILEPATH"
    echo "File name: $FILENAME"
    echo "Bucket URL: $BUCKET"
    echo "Uploading file..."
fi

curl --progress-bar \
    --retry 5 \
    --retry-delay 5 \
    -o /dev/null \
    --upload-file "$FILEPATH" \
    $BUCKET/"$FILENAME"?access_token="$ZENODO_TOKEN"
