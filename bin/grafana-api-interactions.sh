#!/bin/bash

# Sometimes Terraform fails to delete Grafana resources. This script offers a workaround to delete them manually via the Grafana API.
GRAFANA_SERVICE_ACCOUNT_TOKEN=$(grep "grafana_service_account_token" terraform/terraform.tfvars | awk -F'"' '{print $2}')

if [ -z "$GRAFANA_SERVICE_ACCOUNT_TOKEN" ]; then
	echo "Error: Grafana service account token is empty. This script is trying to load it dynamically from terraform.tfvars file. Please make sure that the token is defined in the file."
	exit 1
fi

# Uncomment the below lines as you see fit. It depends on what resources you want to interact with.

# Get all contact points. This is useful to get the UID of the contact point that you want to delete.
# curl -H "Authorization: Bearer $GRAFANA_SERVICE_ACCOUNT_TOKEN" \
#      -H "Content-Type: application/json" \
#      "https://clabsmento.grafana.net/api/v1/provisioning/contact-points" | jq

# Get notification policies
# curl -H "Authorization: Bearer $GRAFANA_SERVICE_ACCOUNT_TOKEN" \
#      -H "Content-Type: application/json" \
#      "https://clabsmento.grafana.net/api/v1/provisioning/policies" | jq

# Delete a contact point
# CONTACT_POINT_UID=<contact-point-uid>
# curl -H "Authorization: Bearer $GRAFANA_SERVICE_ACCOUNT_TOKEN" \
#     -H "Content-Type: application/json" \
#     -X DELETE \
#     "https://clabsmento.grafana.net/api/v1/provisioning/contact-points/$CONTACT_POINT_UID"
