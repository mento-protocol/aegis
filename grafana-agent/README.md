### Grafana agent

The grafana agent pushes the prometheus metrics to grafana. This folder contains the deployment logic for the grafana-agent as an app engine service.

### Deployment

- agent.yaml.tml - Template of the agent.yaml configuration file for the grafana-agent, it contains variables that need to be replaced with secrets during deployment.
- template-agent.sh - Script that turns agent.yaml.tml into agent.yaml, replacing variables with values from the environment.
- Dockerfile - the Dockerfile of the service that gets deployed to app engine.
- cloudbuild.yaml - Google Cloud Build Configuration that prepares and executs the deployment.
- grafana-agent.yaml - The runtime configuration of the app engine service

#### Deployment flow

Requirements: `gcloud` is setup locally and pointing to the `mento-prod` project.

1. Somebody executes `gcloud builds submit` in this folder, creating and running a cloud build job.
2. [CloudBuild Step 1] Runs `template-agent.sh` with values from google cloud secrets and prepares the `agent.yaml` file.
3. [CloudBuild Step 2] Runs `gcloud app deploy grafana-agent.yaml` which starts the app engine deploy flow.
4. [App engine deploy] Dockerfile is executed and image starts running.
