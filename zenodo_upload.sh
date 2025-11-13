#!/bin/bash
#SBATCH --partition=day
#SBATCH --output=zenodo_%j.out
#SBATCH --error=zenodo_%j.err
#SBATCH --mem=2G
#SBATCH --cpus-per-task=1
#SBATCH --mail-user=your_email@example.com
#SBATCH --mail-type=ALL

# Upload big files to Zenodo using the NEW FILES API (supports up to 50GB)
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

set -xe

# Use environment variables instead of positional arguments
VERBOSE=${VERBOSE:-0}

# Strip deposition url prefix if provided
DEPOSITION=$( echo $DEPOSITION_ID | sed 's+^http[s]*://zenodo.org/deposit/++g' )
FILENAME=$(basename "$FILEPATH")
ZENODO_ENDPOINT=${ZENODO_ENDPOINT:-https://zenodo.org}

# Get file size for logging
FILESIZE=$(stat -c%s "$FILEPATH" 2>/dev/null || stat -f%z "$FILEPATH" 2>/dev/null)

if [ "$VERBOSE" -eq 1 ]; then
    echo "=========================================="
    echo "Zenodo Upload - NEW API"
    echo "=========================================="
    echo "Deposition ID: $DEPOSITION"
    echo "File path: $FILEPATH"
    echo "File name: $FILENAME"
    echo "File size: $FILESIZE bytes (~$(numfmt --to=iec-i --suffix=B $FILESIZE 2>/dev/null || echo $FILESIZE))"
    echo "Endpoint: $ZENODO_ENDPOINT"
fi

# Step 1: Get the bucket URL from the deposition
# Using Bearer token authentication (NEW API)
if [ "$VERBOSE" -eq 1 ]; then
    echo ""
    echo "Step 1: Fetching bucket URL..."
fi

BUCKET=$(curl -s "${ZENODO_ENDPOINT}/api/deposit/depositions/${DEPOSITION}" \
    -H "Authorization: Bearer ${ZENODO_TOKEN}" \
    | jq -r '.links.bucket')

if [ -z "$BUCKET" ] || [ "$BUCKET" = "null" ]; then
    echo "ERROR: Failed to get bucket URL. Check your deposition ID and access token."
    exit 1
fi

if [ "$VERBOSE" -eq 1 ]; then
    echo "Bucket URL: $BUCKET"
    echo ""
    echo "Step 2: Uploading file to bucket..."
    echo "This may take a while for large files..."
fi

# Step 2: Upload file using NEW API with PUT request to bucket
# The NEW API supports files up to 50GB (vs 100MB in old API)
# Using Bearer token in header (more secure than URL parameter)
curl --progress-bar \
    --request PUT \
    --upload-file "$FILEPATH" \
    --header "Authorization: Bearer ${ZENODO_TOKEN}" \
    --retry 10 \
    --retry-delay 10 \
    --retry-max-time 7200 \
    --connect-timeout 300 \
    --max-time 0 \
    --keepalive-time 60 \
    "${BUCKET}/${FILENAME}"

UPLOAD_STATUS=$?

echo ""
if [ $UPLOAD_STATUS -eq 0 ]; then
    echo "=========================================="
    echo "✓ Upload completed successfully!"
    echo "=========================================="
    echo "File: $FILENAME"
    echo "Size: $(numfmt --to=iec-i --suffix=B $FILESIZE 2>/dev/null || echo $FILESIZE)"
    echo "Deposition: https://zenodo.org/deposit/${DEPOSITION}"
    echo "=========================================="
else
    echo "=========================================="
    echo "✗ Upload failed with status code: $UPLOAD_STATUS"
    echo "=========================================="
    exit $UPLOAD_STATUS
fi
