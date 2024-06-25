#!/bin/bash

# List all files tracked by Git
git ls-files | while read -r file; do
    # Extract the extension of the file
    ext="${file##*.}"

    # Print the filename
    echo "$file"

    # Print the content of the file in the specified format
    echo "\`\`\`$ext"
    cat "$file"
    echo "\`\`\`"
    echo
done

