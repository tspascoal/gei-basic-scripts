#!/bin/bash

info_color="\033[0;36m"
error_color="\033[0;31m"

### variables to call external dependencies.
script_path=$(dirname "$0")
###

if [ $# -ne 1 ]; then
    echo "Usage: $0 <org>"
    exit 1
fi

if ! "$script_path"/_validate_scopes.sh 
then
    echo -e "${error_color}Error: Missing scopes. Exiting\n\n"
    exit 1
fi

gh api "orgs/$1/migrations" --jq '.[] | select(.archive_url).id' --paginate | while read -r id; do
    echo -e "${info_color}Deleting migration archive $id"
    gh api -X DELETE "/orgs/$1/migrations/$id/archive"
done

echo -e "\n\n${info_color}Done"