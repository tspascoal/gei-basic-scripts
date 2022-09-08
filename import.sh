#!/bin/bash

### variables to call external dependencies.
script_path=$(dirname "$0")
###


if [ -z "$TARGET_PAT" ]; then
    echo "TARGET_PAT environment variable missing"
    exit 1
fi

if [ "$#" -ne 6 ];
then
    echo "Usage: $0 <org> <source repo url> <source base url> <target repo name> <git archive url> <metadata archive url>"
	echo "eg $0 octo-org https://HOST/org/repo https://HOST newrepo https://test.com/gitarchive.tar.gz https://test.com/metadata.tar.gz"
    exit 1
fi

target_org=$1
source_repo_url=$2
source_url=$3
repo=$4
git_archive_url=$5
metadata_archive_url=$6

echo ""
orgid=$(GITHUB_TOKEN =$TARGET_PAT gh api "orgs/$target_org" -q .node_id)

echo "orgid: $orgid"

migration_source_id=$(GITHUB_TOKEN =$TARGET_PAT gh api graphql \
    -F name="GHES" \
    -F "url=$source_url" \
    -F "ownerId=$orgid" \
    -F type="GITHUB_ARCHIVE" \
    -f query='mutation createMigrationSource(
	$name: String!
	$url: String!
	$ownerId: ID!
	$type: MigrationSourceType!
) {
	createMigrationSource(
		input: { name: $name, url: $url, ownerId: $ownerId, type: $type }
	) {
		migrationSource {
			id
			name
			url
			type
		}
	}
}' -q .data.createMigrationSource.migrationSource.id)

echo "migration_source_id: $migration_source_id"

migration_id=$(GITHUB_TOKEN =$TARGET_PAT gh api graphql \
-F sourceId="$migration_source_id" \
-F ownerId="$orgid" \
-F sourceRepositoryUrl="$source_repo_url" \
-F repositoryName="$repo" \
-F continueOnError="true" \
-F gitArchiveUrl="$git_archive_url" \
-F metadataArchiveUrl="$metadata_archive_url" \
-F lockRepositories="false" \
-F accessToken="****" \
-F githubPat="$TARGET_PAT" \
-F skipReleases="false" \
-F lockSource="false" \
-f query='mutation startRepositoryMigration(
	$sourceId: ID!
	$ownerId: ID!
	$sourceRepositoryUrl: URI!
	$repositoryName: String!
	$continueOnError: Boolean!
	$gitArchiveUrl: String
	$metadataArchiveUrl: String
	$accessToken: String!
	$githubPat: String
	$skipReleases: Boolean
	$lockSource: Boolean
) {
	startRepositoryMigration(
		input: {
			sourceId: $sourceId
			ownerId: $ownerId
			sourceRepositoryUrl: $sourceRepositoryUrl
			repositoryName: $repositoryName
			continueOnError: $continueOnError
			gitArchiveUrl: $gitArchiveUrl
			metadataArchiveUrl: $metadataArchiveUrl
			accessToken: $accessToken
			githubPat: $githubPat
			skipReleases: $skipReleases
			lockSource: $lockSource
		}
	) {
		repositoryMigration {
			id
			migrationSource {
				id
				name
				type
			}
			sourceUrl
			state
			failureReason
		}
	}
}' -q .data.startRepositoryMigration.repositoryMigration.id)

if [ $? -ne 0 ] || [ -z "$migration_id" ]; then
    echo "Failed to start migration."
    exit 1
fi

echo "migration id: ${migration_id}"

"$script_path/_wait-for-import.sh" "${migration_id}"

logs_url=$(GITHUB_TOKEN =$TARGET_PAT gh api graphql \
	-F id="$migration_id" \
	-f query='query ($id: ID!) {
		node(id: $id) {
			... on Migration {
				migrationLogUrl
			}
		}
	}' -q .data.node.migrationLogUrl)

echo "You can see logs at: $logs_url or in the repo as an issue"
