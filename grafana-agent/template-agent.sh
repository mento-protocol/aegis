#!/bin/bash

# Prepare agent.yaml with values from environment variables
sed "s|GRAFANA_AGENT_ENDPOINT|$GRAFANA_AGENT_ENDPOINT|g" agent.yaml.tmpl | \
  sed "s|GRAFANA_AGENT_USERNAME|$GRAFANA_AGENT_USERNAME|g" | \
  sed "s|GRAFANA_AGENT_PASSWORD|$GRAFANA_AGENT_PASSWORD|g" > agent.yaml

