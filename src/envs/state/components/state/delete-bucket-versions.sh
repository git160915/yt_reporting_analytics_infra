#!/bin/bash
set -e

# Ensure a bucket name is provided.
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <bucket-name>"
    exit 1
fi

BUCKET="$1"
echo "Processing bucket: $BUCKET"

# Check if jq is installed; if not, install it.
if ! command -v jq &>/dev/null; then
    echo "jq is not installed. Installing jq..."
    sudo apt-get update && sudo apt-get install -y jq
fi

# Create a temporary file to hold the JSON output.
TEMP_FILE=$(mktemp)

# List all object versions for the specified bucket and save to the temporary file.
echo "Listing object versions in bucket $BUCKET..."
aws s3api list-object-versions --bucket "$BUCKET" --output json --query '{Objects: Versions[].{Key: Key, VersionId: VersionId}}' > "$TEMP_FILE"

# Check if any objects were found using jq.
OBJECT_COUNT=$(jq -r '.Objects | length' "$TEMP_FILE")
if [ "$OBJECT_COUNT" -eq 0 ]; then
    echo "No object versions found in bucket $BUCKET. Exiting."
    rm "$TEMP_FILE"
    exit 0
fi

# Display the number of objects found.
echo "Found $OBJECT_COUNT object versions. Deleting..."

# Delete the objects using the temporary JSON file.
aws s3api delete-objects --bucket "$BUCKET" --delete "file://$TEMP_FILE"

# Clean up the temporary file.
rm "$TEMP_FILE"

echo "Deletion complete for bucket $BUCKET."
