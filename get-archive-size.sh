#!/bin/bash

info_color="\033[0;36m"
error_color="\033[0;31m"
warning_color="\033[0;33m"

export TZ=UTC

### variables to call external dependencies.
script_path=$(dirname "$0")
###

function export_and_wait() {

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
        '{"lock_repositories":false,"exclude_git_data": $git,"repositories":[$repo], "exclude_metadata": $metadata}' \
        | gh api -X POST "/orgs/$source_org/migrations" -p wyandotte -H "Accept: application/vnd.github.v3+json" --input=- 
    )

    export_id=$(echo -n "$response"| jq -c .id)

    echo "$export_id"
  }

  local source_org=$1
  local repo=$2
  local type=$2

  local metadataonly=false  
  if [ "$type" == "metadata" ]; then
    metadataonly=true
  fi

  id=$(callAPI "$source_org" "$repo" $metadataonly)

  if [ "$id" == "" ] || [ "$id" == "null" ]; then
      echo -e "${error_color}Error: Starting export failed. Exiting\n\n"
      exit 1
  fi

  echo -e "${info_color}$type export started with id $id"
  
  "$script_path"/_wait_for_export.sh "$source_org" "$id"
}

if [ $# -ne 3 ]; then
    echo "Usage: $0 <org> <repo> <repo | metadata>"
    exit 1
fi

org=$1
repo=$2
type=$3

if ! "$script_path"/_validate_scopes.sh 
then
    echo -e "${error_color}Error: Missing scopes. Exiting\n\n"
    exit 1
fi

echo -e "\n\n${info_color}Getting size of $repo metadata $type from org $org"
echo -e "${warning_color}Be mindful since this actually generates an archive to calculate it's size. This can take a while and consume resources.\n\n"

export_and_wait "$org" "$repo" "$type"

if ! size=$(gh api -X GET "orgs/$org/migrations/$id/archive" --silent --include | grep -i 'Content-Length:' | sed -e 's/Content-Length: //'); then
    echo -e "\nFailed to get size of $repo metadata $type from org $org"
    exit 1
fi

# format size in bytes, MB, GB
echo -e "\n$type archive size $(echo "$size" | awk '{ split( "B KB MB GB" , v ); s=1; while( $1>1024 ){ $1/=1024; s++ } printf "%.2f %s", $1, v[s] }')"

echo -e "\n\n${info_color}Done"