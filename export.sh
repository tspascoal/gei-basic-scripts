#!/bin/bash

info_color="\033[0;36m"
error_color="\033[0;31m"

export TZ=UTC

### variables to call external dependencies.
script_path=$(dirname "$0")
###

function export_archives() {

 function callAPI()
  {
    local source_org=$1
    local repo=$2
    if [ "$3" == "true" ]; then
        git=false
        metadata=true
    else 
        git=true
        metadata=false
    fi

    local export_id

    response=$(jq --null-input --argjson git "$git" --argjson metadata "$metadata" --arg repo "$repo" \
        '{"lock_repositories":false,"exclude_git_data": $git,"exclude_owner_projects":true,"repositories":[$repo], "exclude_metadata": $metadata}' \
        | gh api -X POST "/orgs/$source_org/migrations" -p wyandotte -H "Accept: application/vnd.github.v3+json" --input=- 
    )

    export_id=$(echo -n "$response"| jq -c .id)

    echo "$export_id"
  }

  local source_org=$1
  local repo=$2

  git_id=$(callAPI "$source_org" "$repo" true)

  if [ "$git_id" == "" ] || [ "$git_id" == "null" ]; then
      echo -e "${error_color}Error: Starting git metadata failed. Exiting\n\n"
      exit 1
  fi

  echo -e "${info_color}Git metadata export started with id $git_id"
  
  metadata_id=$(callAPI "$source_org" "$repo" false)

  if [ "$metadata_id" == "" ] || [ "$metadata_id" == "null" ]; then
      echo -e "${error_color}Error: Starting git metadata failed. Exiting\n\n"
      exit 1
  fi

  echo -e "${info_color}Metadata export started with id $metadata_id"

  "$script_path"/_wait_for_export.sh "$source_org" "$git_id" "$metadata_id"

  base_name="${repo}$(date +"%Y%m%d_%H%M_%S")"

  git_archive_name="${base_name}-${git_id}-git_archive.tar.gz"
  metadata_archive_name="${base_name}-${metadata_id}-metadata_archive.tar.gz"

  "$script_path"/_download_export.sh "$source_org" "$git_id" "$git_archive_name"  
  "$script_path"/_download_export.sh "$source_org" "$metadata_id" "$metadata_archive_name"
}

if [ $# -ne 2 ]; then
    echo "Usage: $0 <org> <repo>"
    exit 1
fi

if ! "$script_path"/_validate_scopes.sh 
then
    echo -e "${error_color}Error: Missing scopes. Exiting\n\n"
    exit 1
fi

export_archives "$1" "$2"

echo -e "\n\n${info_color}Done"