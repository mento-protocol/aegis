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

module "grafana_alerts" {
  source                                           = "./grafana-alerts"
  grafana_service_account_token                    = var.grafana_service_account_token
  oracle_relayers_folder                           = grafana_folder.oracle_relayers
  reserve_folder                                   = data.grafana_folder.reserve
  trading_modes_folder                             = grafana_folder.trading_modes
  splunk_on_call_alerts_webhook_url                = var.splunk_on_call_alerts_webhook_url
  discord_alerts_webhook_url_staging               = var.discord_alerts_webhook_url_staging
  discord_alerts_webhook_url_prod                  = var.discord_alerts_webhook_url_prod
  discord_alerts_webhook_url_reserve               = var.discord_alerts_webhook_url_reserve
  discord_alerts_webhook_url_trading_modes_staging = var.discord_alerts_webhook_url_trading_modes_staging
  discord_alerts_webhook_url_trading_modes_prod    = var.discord_alerts_webhook_url_trading_modes_prod
  discord_alerts_webhook_url_catch_all             = var.discord_alerts_webhook_url_catch_all
}
