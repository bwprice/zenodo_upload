# Zenodo Upload Configuration File
# 
# Instructions:
# 1. Set your Zenodo access token
# 2. Set your deposition ID
# 3. List all files to upload (one per line, full paths)
# 4. Set VERBOSE=1 for detailed output, or VERBOSE=0 for quiet mode

# Your Zenodo access token
ZENODO_TOKEN="insert_token_here"

# Deposition ID (the number from your Zenodo upload page)
DEPOSITION_ID="12345"

# Verbose output (0 = quiet, 1 = verbose)
VERBOSE=0

# List of files to upload (one per line, use full absolute paths)
# You can add as many files as needed
FILES=(
    "/path/to/your/file1.zip"
    "/path/to/your/file2.fastq.gz"
    "/path/to/your/file3.bam"
)

# Alternative: If all your files are in one directory, you can use a pattern
# Uncomment and modify this line, and comment out the FILES array above:
# FILES=(/path/to/your/data/*.zip)
