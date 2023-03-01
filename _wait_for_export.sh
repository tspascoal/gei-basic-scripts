#!/bin/bash


if [ $# -ne 3 ]; then
    echo "Usage: $0 <org> <git metadata id> <metadata id>"
    exit 1
fi

org=$1
git_id=$2
metadata_id=$3

sleeptime=(10 15 20 25 30 10 40 15 50 55 60)
sleepidx=0

function getState() {
    org=$1
    id=$2

    local state

    state=$(gh api "/orgs/$org/migrations/$id" | jq -cr '.state') 

    if [ "$state" == "failed" ]; then
        >&2 echo "export failed, no need to wait for it. Dumping status:"

        >&2 gh api "/orgs/$org/migrations/$id"
        exit 1
    fi

    echo "$state"
}

while [ "$state_git" != "exported" ] || [ "$state_metadata" != "exported" ]; do
    sleepvalue=${sleeptime[$sleepidx]}
    echo "sleeping for ${sleepvalue} seconds"
    sleep "${sleepvalue}"s

    state_git=$(getState "$org" "$git_id") || exit 1
    echo "$id git state=$state_git"

    state_metadata=$(getState "$org" "$metadata_id") || exit 1
    echo "$id metadata state=$state_metadata"

    sleepidx=$(((sleepidx + 1) % ${#sleeptime[@]}))
done
