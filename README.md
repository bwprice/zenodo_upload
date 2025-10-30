# Zenodo Upload Scripts for HPC

A set of bash scripts to automate uploading large files to Zenodo using Slurm job scheduling on HPC systems.

## Overview

These scripts provide a robust, config-based workflow for uploading multiple large files to Zenodo repositories. They handle:
- Sequential uploads to avoid API rate limiting
- Slurm job scheduling with proper resource allocation
- Conda environment management
- Error handling and retry logic
- Email notifications on job completion

## Prerequisites

### System Requirements
- HPC cluster with Slurm scheduler
- Bash shell
- Conda/Miniconda

### Required Tools
Install these in a conda environment:
```bash
conda create -n zenodo -c conda-forge jq curl
conda activate zenodo
```

## Installation

1. Clone or download this repository to your HPC system:
```bash
cd /your/hpc/directory
git clone https://github.com/bwprice/zenodo_upload.git
cd zenodo_upload
```

2. Make scripts executable:
```bash
chmod +x zenodo_upload.sh submit_zenodo_uploads.sh
```

3. Update the conda path in `zenodo_upload.sh` if your conda is not at `/home/benjp/miniconda3`:
   - Edit line 17 to match your conda installation path

## Configuration

### 1. Edit the Config File

Copy and edit `zenodo_config.sh`:

```bash
cp zenodo_config.sh my_upload_config.sh
nano my_upload_config.sh
```

Update the following fields:

```bash
# Your Zenodo access token
ZENODO_TOKEN="your_token_here"

# Deposition ID from your Zenodo upload page
DEPOSITION_ID="12345"

# Verbose output (0 = quiet, 1 = verbose)
VERBOSE=1

# List of files to upload (full absolute paths)
FILES=(
    "/path/to/file1.zip"
    "/path/to/file2.fastq.gz"
    "/path/to/file3.bam"
)
```

### 2. Getting Your Zenodo Access Token

1. Log in to [Zenodo](https://zenodo.org) or [Zenodo Sandbox](https://sandbox.zenodo.org)
2. Go to Applications → Personal access tokens
3. Create a new token with `deposit:write` scope
4. Copy the token to your config file

### 3. Getting Your Deposition ID

1. Create a new upload on Zenodo
2. The deposition ID is in the URL: `https://zenodo.org/deposit/17472152`
3. Use just the number: `17472152`

## Usage

### Basic Usage

Submit all files from your config:

```bash
./submit_zenodo_uploads.sh
```

### Using a Custom Config File

```bash
./submit_zenodo_uploads.sh /path/to/custom_config.sh
```

### Monitoring Jobs

Check job status:
```bash
squeue -u $USER
```

View output files:
```bash
# Success/progress output
cat zenodo_[jobid].out

# Error output
cat zenodo_[jobid].err
```

Cancel pending jobs:
```bash
scancel [jobid]
```

## How It Works

### Sequential Upload Process

1. **Submission**: `submit_zenodo_uploads.sh` reads your config file
2. **Job Dependencies**: Each upload job waits for the previous one to complete (`--dependency=afterok`)
3. **Upload**: `zenodo_upload.sh` activates conda, fetches bucket URL, and uploads the file
4. **Retry Logic**: Automatically retries failed uploads up to 5 times with 5-second delays
5. **Notification**: Email sent on job completion/failure

### Resource Allocation

Default settings per upload job:
- **Memory**: 2GB
- **CPUs**: 1
- **Partition**: day

These are intentionally minimal since uploads are I/O bound, not CPU/memory intensive.

## File Structure

```
zenodo_upload/
├── README.md                    # This file
├── zenodo_upload.sh             # Main upload script (Slurm job)
├── submit_zenodo_uploads.sh     # Wrapper to submit multiple uploads
└── zenodo_config.sh             # Configuration template
```

## Scripts Overview

### `zenodo_upload.sh`
- Main Slurm job script that performs the actual upload
- Activates conda environment
- Fetches Zenodo bucket URL via API
- Uploads file with retry logic
- **Do not run directly** - use the wrapper script

### `submit_zenodo_uploads.sh`
- Wrapper script that reads config and submits jobs
- Creates job dependencies for sequential uploads
- Validates config before submission
- Provides status updates

### `zenodo_config.sh`
- Configuration template
- Store your token, deposition ID, and file list
- Keep secure (contains API token)

## Customization

### Adjusting Resource Allocation

Edit `zenodo_upload.sh` lines 5-6:

```bash
#SBATCH --mem=2G           # Increase if needed
#SBATCH --cpus-per-task=1  # Usually 1 is sufficient
```

### Changing Email Notifications

Edit `zenodo_upload.sh` lines 7-8:

```bash
#SBATCH --mail-user=your.email@example.com
#SBATCH --mail-type=ALL    # Options: NONE, BEGIN, END, FAIL, ALL
```

### Adjusting Retry Logic

Edit `zenodo_upload.sh` lines 44-46:

```bash
curl --progress-bar \
    --retry 5 \              # Number of retries
    --retry-delay 5 \        # Seconds between retries
```

### Parallel vs Sequential Uploads

Current setup: **Sequential** (recommended for Zenodo to avoid API rate limits)

To switch to parallel uploads, remove the dependency logic in `submit_zenodo_uploads.sh` lines 64-69.

## Contributing

Contributions welcome! Please:
1. Test changes on your HPC system
2. Update documentation
3. Submit pull requests

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Credits

Based on [zenodo-upload](https://github.com/jhpoelen/zenodo-upload) by jhpoelen.
