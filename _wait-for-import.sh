#!/bin/bash

set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <id>"
    exit 1
fi

id=$1

sleeptime=(10 15 20 25 30 10 40 15 50 55 60)
sleepidx=0

function getState() {
    id=$1

    local state

	state=$(GITHUB_TOKEN =$TARGET_PAT gh api graphql \
	-F id="$id" \
	-f query='query ($id: ID!) {
		node(id: $id) {
			... on Migration {
				id
				state
				failureReason
			}
		}
	}' -q .data.node.state) 

	if [ -z "$state" ]; then
		>&2 echo "Failed to get state for migration $id"
		exit 1
	fi

    if [ "$state" == "FAILED" ] || [ "$state" == "FAILED_VALIDATION" ]; then
        >&2 echo "import failed, no need to wait for it. Dumping status:"
        >&2 GITHUB_TOKEN =$TARGET_PAT gh api graphql \
			-F id="$id" \
			-f query='query ($id: ID!) {
				node(id: $id) {
					... on Migration {
						id
						state
						failureReason
					}
				}
			}' | jq .

		exit 1		
	fi

    echo "$state"
}

while [ "$state" != "SUCCEEDED" ] ; do
    sleepvalue=${sleeptime[$sleepidx]}
    echo " sleeping for ${sleepvalue} seconds"
    sleep "${sleepvalue}"s

    state=$(getState "$id") || exit 1
    echo "  state=$state"

    sleepidx=$(((sleepidx + 1) % ${#sleeptime[@]}))
done

