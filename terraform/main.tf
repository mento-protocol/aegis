terraform {
  required_version = ">= 1.9"

  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.7.0"
    }
  }

  backend "gcs" {
    bucket                      = "mento-terraform-tfstate-6ed6"
    prefix                      = "aegis"
    impersonate_service_account = "org-terraform@mento-terraform-seed-ffac.iam.gserviceaccount.com"
  }
}

provider "grafana" {
  url  = "https://clabsmento.grafana.net"
  auth = var.grafana_service_account_token
}

module "grafana_dashboard" {
  source                        = "./grafana-dashboard"
  grafana_service_account_token = var.grafana_service_account_token
  aegis_folder                  = grafana_folder.aegis
}

module "discord_alerts" {
  source                        = "./discord-alerts"
  grafana_service_account_token = var.grafana_service_account_token
  oracle_relayers_folder        = grafana_folder.oracle_relayers
}
