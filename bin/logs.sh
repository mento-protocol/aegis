#!/bin/bash
set -e          # Fail on any error
set -o pipefail # Ensure piped commands propagate exit codes properly
set -u          # Treat unset variables as an error when substituting

# Make sure the mento-prod project is set as the default project
gcloud config set project mento-prod
gcloud auth application-default set-quota-project mento-prod

# Fetch the logs from the mento-prod project
gcloud app logs tail