variable "grafana_service_account_token" {
  description = "Grafana Service Account Token allowing Terraform to manage Grafana resources on the Mento Stack"
  type        = string
  sensitive   = true
}

variable "oracle_relayers_folder" {
  description = "The grafana folder in which to create the oracle relayer alerts"
  type = object({
    uid = string
  })
}

variable "discord_alerts_webhook_url_staging" {
  type    = string
  default = "https://discord.com/api/webhooks/1280908742346407999/j5QO_xV6PhAXVcQjmfp0gJ3FB-TRHHgg5CSiz2acErC-EZzaTIHm5Hya8Nv1B1CPkpX1"
}

variable "discord_alerts_webhook_url_prod" {
  type    = string
  default = "https://discord.com/api/webhooks/1282681325375197276/iOkrHNO5zl4cWsLjnp0CFTdxye1lcSbBxTADqBWInpN8bsbdVgVjpM_LVQTjjBKbs7Q1"
}

locals {
  chain_config = {
    alfajores = {
      label         = "Alfajores"
      contact_point = grafana_contact_point.discord_channel_oracle_relayers_staging.name
    }
    celo = {
      label         = "Celo"
      contact_point = grafana_contact_point.discord_channel_oracle_relayers_prod.name
    }
  }
  discord_alert_oracle_relayer_config = {
    title   = <<EOT
{{ if or (eq .CommonLabels.alertname "Oldest Report Expired Alert [Alfajores]") (eq .CommonLabels.alertname "Oldest Report Expired Alert [Celo]") }}
{{ template "discord.message.stale_price_alert_title" . }}
{{ else if or (eq .CommonLabels.alertname "Low CELO Balance Alert [Alfajores]") (eq .CommonLabels.alertname "Low CELO Balance Alert [Celo]") }}
{{ template "discord.message.low_celo_balance_alert_title" . }}
{{ else }}
Alert without a configured alert template: {{ .CommonLabels.alertname }}
{{ end }}
EOT
    message = <<EOT
{{ if or (eq .CommonLabels.alertname "Oldest Report Expired Alert [Alfajores]") (eq .CommonLabels.alertname "Oldest Report Expired Alert [Celo]") }}
{{ template "discord.message.stale_price_alert_message" . }}
{{ else if or (eq .CommonLabels.alertname "Low CELO Balance Alert [Alfajores]") (eq .CommonLabels.alertname "Low CELO Balance Alert [Celo]") }}
{{ template "discord.message.low_celo_balance_alert_message" . }}
{{ else if eq .CommonLabels.alertname "DatasourceError" }}
The Grafana alert query might be broken. Please check the alert configuration.
{{ else }}
Alert without a configured alert template: {{ .CommonLabels.alertname }}
Alert Labels:
{{ range $k, $v := .CommonLabels }}
  {{ $k }}: {{ $v }}
{{ end }}
{{ end }}
EOT
  }
}
