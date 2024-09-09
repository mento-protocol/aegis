terraform {
  required_version = ">= 1.8"

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

variable "grafana_service_account_token" {
  description = "Grafana Service Account Token allowing Terraform to manage Grafana resources on the Mento Stack"
  type        = string
  sensitive   = true
}

provider "grafana" {
  url  = "https://clabsmento.grafana.net"
  auth = var.grafana_service_account_token
}
