variable "grafana_service_account_token" {
  description = "Grafana Service Account Token allowing Terraform to manage Grafana resources on the Mento Stack"
  type        = string
  sensitive   = true
}

variable "aegis_folder" {
  description = "The aegis folder in which to create the Grafana dashboard"
  type = object({
    uid = string
  })
}

locals {
  chains                    = ["celo", "alfajores"]
  prometheus_datasource_uid = "grafanacloud-clabsmento-prom"
  common_panel_config = {
    datasource = {
      type = "prometheus"
      uid  = local.prometheus_datasource_uid
    }
    legend = {
      showLegend  = true
      displayMode = "list"
      placement   = "bottom"
    }
    tooltip = {
      mode = "single"
      sort = "none"
    }
  }

  state_timeline_config = {
    type = "state-timeline"
    options = {
      mergeValues = false
      showValue   = "never"
      alignValue  = "center"
      rowHeight   = 0.9
    }
    fieldConfig = {
      defaults = {
        custom = {
          lineWidth   = 0
          fillOpacity = 70
          spanNulls   = false
          insertNulls = false
        }
        color = {
          mode = "continuous-GrYlRd"
        }
      }
    }
  }
}
