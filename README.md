# Zenodo Upload Scripts for HPC

A set of bash scripts to automate uploading large files to Zenodo using Slurm job scheduling on HPC systems. Uses Zenodo's modern Files API supporting uploads up to 50GB per file.

## Overview

These scripts provide a robust, config-based workflow for uploading multiple large files to Zenodo repositories. They handle:
- Sequential uploads to avoid API rate limiting
- Zenodo's NEW Files API (supports up to 50GB files)
- Bearer token authentication for enhanced security
- Slurm job scheduling with proper resource allocation
- Conda environment management
- Comprehensive error handling and retry logic
- Email notifications on job completion

## Features

✅ **Large File Support** - Upload files up to 50GB using Zenodo's modern API  
✅ **Sequential Processing** - Jobs run one after another to prevent API conflicts  
✅ **Smart Retries** - Automatic retry with exponential backoff for network issues  
✅ **Config-Based** - Manage tokens and file lists in a single configuration file  
✅ **Slurm Integration** - Native job scheduling with dependencies  
✅ **Progress Tracking** - Real-time upload progress and detailed logging

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

**Note:** `curl` and `bash` are typically pre-installed on HPC systems. `jq` is used for JSON parsing of API responses.

## Installation

1. Clone this repository to your HPC system:
```bash
cd /your/hpc/directory
git clone https://github.com/bwprice/zenodo_upload.git
cd zenodo_upload
```

2. Make scripts executable:
```bash
chmod +x zenodo_upload.sh submit_zenodo_uploads.sh
```

3. Configure email notifications in `zenodo_upload.sh`:
   - Edit line 7 to set your email address for job notifications:
     ```bash
     #SBATCH --mail-user=your_email@example.com
     ```

4. Update the conda path in `zenodo_upload.sh` if your conda installation is not at `/home/benjp/miniconda3`:
   - Edit lines 16-26 to match your conda installation path

## Configuration

### 1. Edit the Config File

Create your configuration file from the template:

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
2. Go to **Account** → **Applications** → **Personal access tokens**
3. Click **New token**
4. Select scopes: `deposit:write` and `deposit:actions`
5. Create token and copy it to your config file

**Important:** Keep your token secure! Never commit config files with tokens to public repositories.

### 3. Getting Your Deposition ID

1. Create a new upload on Zenodo
2. The deposition ID is the number in the URL: `https://zenodo.org/deposit/17472152`
3. Use just the number in your config: `DEPOSITION_ID="17472152"`

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

### Output

The wrapper script will display:
```
==========================================
Zenodo Upload Batch Submission
==========================================
Deposition ID: 17472152
Number of files: 4
Upload script: /path/to/zenodo_upload.sh
Verbose mode: 1

✓ Submitted: file1.zip (Job ID: 12345, starts immediately)
✓ Submitted: file2.fastq.gz (Job ID: 12346, waits for Job 12345)
✓ Submitted: file3.bam (Job ID: 12347, waits for Job 12346)
✓ Submitted: file4.tar.gz (Job ID: 12348, waits for Job 12347)

==========================================
Total jobs submitted: 4
==========================================

Monitor your jobs with: squeue -u $USER
Check output files: zenodo_[jobid].out
Check error files: zenodo_[jobid].err
```

### Monitoring Jobs

Check job status:
```bash
squeue -u $USER
```

View upload progress in real-time:
```bash
tail -f zenodo_[jobid].out
```

View output files:
```bash
# Success/progress output
cat zenodo_[jobid].out

# Error output (if any)
cat zenodo_[jobid].err
```

Cancel pending jobs:
```bash
scancel [jobid]
```

## How It Works

### Sequential Upload Process

The scripts use Slurm job dependencies to ensure uploads happen one at a time:

1. **Configuration Loading**: `submit_zenodo_uploads.sh` reads your config file
2. **Job Submission**: Creates one Slurm job per file with dependencies
   - First job starts immediately
   - Each subsequent job waits for the previous one (`--dependency=afterok`)
3. **Upload Execution**: Each `zenodo_upload.sh` job:
   - Activates conda environment
   - Fetches bucket URL from Zenodo API
   - Uploads file using Zenodo's NEW Files API (supports up to 50GB)
   - Uses Bearer token authentication for security
4. **Retry Logic**: Automatically retries failed uploads:
   - Up to 10 retry attempts
   - 10-second delay between retries
   - 2-hour maximum retry window
5. **Notification**: Email sent on job completion/failure

### API Details

The scripts use **Zenodo's NEW Files API** which:
- Supports files up to 50GB (vs 100MB in old API)
- Uses `PUT` requests to bucket URLs
- Requires Bearer token authentication (`Authorization: Bearer TOKEN`)
- Is more performant and reliable for large files

### Resource Allocation

Default settings per upload job:
- **Memory**: 2GB
- **CPUs**: 1 core
- **Partition**: day

These are intentionally minimal since uploads are I/O bound, not CPU/memory intensive.

## File Structure

```
zenodo_upload/
├── README.md                    # This file
├── LICENSE                      # MIT License
├── zenodo_upload.sh             # Main upload script (Slurm job)
├── submit_zenodo_uploads.sh     # Wrapper to submit multiple uploads
└── zenodo_config.sh             # Configuration template
```

## Scripts Overview

### `zenodo_upload.sh`
- Main Slurm job script that performs the actual upload
- Activates conda environment with jq
- Uses Zenodo NEW Files API with Bearer authentication
- Fetches bucket URL via API
- Uploads file with comprehensive retry logic
- Supports files up to 50GB
- **Do not run directly** - use the wrapper script

### `submit_zenodo_uploads.sh`
- Wrapper script that reads config and submits jobs
- Creates Slurm job dependencies for sequential uploads
- Validates config before submission
- Provides detailed status updates and job IDs

### `zenodo_config.sh`
- Configuration template
- Store your token, deposition ID, and file list
- Keep secure (contains API token)


## API Compliance

This implementation follows the [Zenodo REST API documentation](https://developers.zenodo.org/) and uses:

✅ **NEW Files API** - Modern endpoint supporting 50GB files  
✅ **Bearer Token Authentication** - Secure header-based auth  
✅ **PUT Requests** - Proper HTTP method for file uploads  
✅ **Bucket URLs** - Direct upload to storage buckets  
✅ **Rate Limiting Respect** - Sequential uploads prevent API abuse

## Testing

### Using Zenodo Sandbox

Before uploading to production Zenodo, test with the sandbox environment:

1. Create account at [sandbox.zenodo.org](https://sandbox.zenodo.org)
2. Generate a sandbox access token
3. Set `ZENODO_ENDPOINT` in your config:
   ```bash
   ZENODO_ENDPOINT="https://sandbox.zenodo.org"
   ```
4. Use a sandbox deposition ID

**Note:** Sandbox uses test DOIs with prefix `10.5072` instead of production `10.5281`.

## Contributing

Contributions welcome! Please:
1. Test changes on your HPC system
2. Update documentation
3. Follow existing code style
4. Submit pull requests with clear descriptions

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Credits

- Based on [zenodo-upload](https://github.com/jhpoelen/zenodo-upload) by jhpoelen
- Updated to use Zenodo NEW Files API
- Enhanced for HPC environments with Slurm


## Changelog

### Version 2.0 (Current)
- **Major Update**: Migrated to Zenodo NEW Files API
- Support for files up to 50GB (vs 100MB previously)
- Bearer token authentication for enhanced security
- Improved error handling and logging
- Better retry logic for large files
- Comprehensive documentation

### Version 1.0
- Initial release
- Sequential upload support via Slurm dependencies
- Config-based workflow
- Conda environment integration
- Email notifications
