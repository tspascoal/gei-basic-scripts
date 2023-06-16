#!/bin/bash

if [ $# -lt 2 ]; then
    echo "Usage: $0 <org> <id> [id...]"
    exit 1
fi

org=$1
shift
ids=("$@")

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

# initialize states with empty strings with the size of ids array
states=("${ids[@]/#//}")

while [[ "${states[*]}" != *"exported"* ]]; do
    sleepvalue=${sleeptime[$sleepidx]}
    echo "  sleeping for ${sleepvalue} seconds"
    sleep "${sleepvalue}"s

    # iterate over ids
    for i in "${!ids[@]}"; do
        # no need to call it if it's already exported
        if [[ "${states[$i]}" != "exported" ]]; then
            states[$i]=$(getState "$org" "${ids[$i]}") || exit 1
            echo "  ${ids[$i]} state=${states[$i]}"
        fi

        if [[ "${states[$i]}" == "failed" ]]; then
            echo "  export $i failed"
            exit 1
        fi
    done    

    sleepidx=$(((sleepidx + 1) % ${#sleeptime[@]}))
done