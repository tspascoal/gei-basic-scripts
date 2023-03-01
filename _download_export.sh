#!/bin/bash

if [ $# -ne 3 ]; then
    echo "Usage: $0 <org> <id> <filename>"
    echo "filename should have .tar.gz extension"
    exit 1
fi

echo ""
echo " writing migration $2 from org $1 to $3"

if ! gh api -X GET "/orgs/$1/migrations/$2/archive" > "$3"; then
    echo -e "\nFailed to download migration $2 from org $1"
    exit 1
fi

echo "    $3 size:  $(du "$3" -a -h | awk '{print $1}')"