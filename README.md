# Github Enterprise Importer Basic scripts

> This is just a quick hack, you **shouldn't us** this unless you have a very good reason to. Use [Github Enterprise Importer CLI](https://github.com/github/gh-gei) instead, which is fully featured, supported, maintained and battle tested. Github Enterprise Importer CLI [supports both azure as well as S3](https://docs.github.com/en/early-access/enterprise-importer/migrating-repositories-with-github-enterprise-importer/migrating-repositories-to-github-enterprise-cloud/migrating-repositories-from-github-enterprise-server-to-github-enterprise-cloud#step-5-set-up-blob-storage)

You can use this _basic_ scripts to migrate a repo from GHEC or GHES to GHEC, it is not fully automated and requires some manual steps.

## Pre Requirements

The provided scripts require the following tools to be installed:

- [GitHub CLI](https://cli.github.com/)
- [jq](https://stedolan.github.io/jq/)

## Exporting from GHES

In order to export data from GHES, you need to define two environment variables: 

- `GH_HOST`
- `GH_ENTERPRISE_TOKEN`

See more [at](https://cli.github.com/manual/#github-enterprise)

## Exporting Data

The token being used requires two permissions:

- admin:org
- repo

See you how can configure GitHub CLIg [here](https://cli.github.com/manual/#configuration)

call `export.sh` to generate two archives that GEI can use to import a repo into GHEC.

This script requires two parameters:

- Organization name
- Repository name

eg:

```console
$ ./export.sh my-org my-repo
Git metadata export started with id 1551501
Metadata export started with id 1551502
sleeping for 10 seconds
 git state=exporting
 metadata state=exported
 writing migration 1551501 from org my-org to my-repo20220824_1716_42-1551501-git_archive.tar.gz
my-repo20220824_1716_42-1551501-git_archive.tar.gz size:  11K
 writing migration 1551502 from org my-org to my-repo20220824_1716_42-1551502-metadata_archive.tar.gz
my-repo20220824_1716_42-1551502-metadata_archive.tar.gz size:  1.4K

Done
```

## Storing the Data

In order for the repo to be imported, the two generated archives will need to be placed in an internet accessible URL that GEI can access (they can be deleted after the import is complete).

You can use Azure Blob Storage or AWS S3 to store the archives, it is recommended that the archives are stored privately, so in order for GEI to access the archives, you will need to provide a URL with a SAS token.

Consult Azure Storage or S3 documentation for instructions to upload and to generate the URL with a SAS token.

## Importing Data

After you stored the archives, you are not ready to import the data. For that you can use the `import.sh` script.

You will need to store a GitHub token in an environment variable called `TARGET_TOKEN` that has the following permissions:

- admin:org (or have the migrator role)
- repo
- user
- workflow

See [Managing access for GitHub Enterprise Importer](https://docs.github.com/en/early-access/github/migrating-with-github-enterprise-importer/running-a-migration-with-github-enterprise-importer/managing-access-for-github-enterprise-importer#about-required-access-for-github-enterprise-importer) for more information.

`import.sh` has the following parameters:

- Organization name (the target organization)
- Source repository URL
- Target repository name (The repo name you want to create. It can be different from the original one)
- Git Archive URL - The URL to the git archive that you have stored previously.
- Metadata Archive URL - The URL to the metadata archive that you have stored previously.

eg:

```console
./import.sh target-org https://github.com/my-org/my-repo my-repo "https://dummy.blob.core.windows.net/archives/my-repo20220824_1058_01-1549512-git_archive.tar.gz?sp=r&st=2022-08-23T13:23:55Z&se=2022-08-27T21:23:55Z&spr=https&sv=2021-06-08&sr=b&sig=THISISJUSTADUMMYSAS" "https://dummy.blob.core.windows.net/archives/my-repo20220824_1058_01-1549514-metadata_archive.tar.gz?sp=r&st=2020-08-23T13:24:55Z&se=2022-08-26T21:24:55Z&spr=https&sv=2021-06-08&sr=b&sig=THISISJUSTADUMMYSAS"

orgid: O_kgDOBX2Y1g
migration_source_id: MS_kgDaACQ4MGMxYWIyOerwerwerewewNDktYWQwZi0xNDdhOWYyNDVjY2Y
migration id: RM_kgDaACRlOWFmNjBjMi02XDD323232ZjNC0wYzZjMjhkZWM0MWY
 sleeping for 10 seconds
 state=IN_PROGRESS
 sleeping for 15 seconds
 state=IN_PROGRESS
 sleeping for 20 seconds
 state=IN_PROGRESS
 sleeping for 25 seconds
 state=IN_PROGRESS
 sleeping for 30 seconds
 state=IN_PROGRESS
 sleeping for 10 seconds
 state=IN_PROGRESS
 sleeping for 40 seconds
 state=IN_PROGRESS
 sleeping for 15 seconds
 state=IN_PROGRESS
 sleeping for 50 seconds
 state=SUCCEEDED
```
