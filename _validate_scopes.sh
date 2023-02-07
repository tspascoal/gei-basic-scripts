#!/bin/bash

function array_contains {
  ARRAY=$2
  compare_with=$1
  # There is not globbing since scopes have no wildcards
  # shellcheck disable=SC2048
  for item in ${ARRAY[*]}
  do
    if [[ "$item" == "$compare_with" ]]
    then
      return 0
    fi
  done
  return 1
}

_scope=$(gh api user -i | grep -i "X-Oauth-Scopes:" | sed -e 's/X-Oauth-Scopes: //')
scopeslist=$(echo -n "$_scope"  | tr "," "+" | tr -d '\n\r' | tr -d ' ')

echo "User has the following scopes: $_scope"
echo

# split the scopes into an array
IFS='+' read -r -a scopes <<< "$scopeslist "

missing=0
declare -a checkscopes=("repo" "admin:org")
for scope in "${checkscopes[@]}"
do
    if ! array_contains "$scope" "${scopes[*]}"
    then
        echo "missing $scope scope. Please add $scope scope to your PAT"
        missing=1
    fi
done

exit $missing
