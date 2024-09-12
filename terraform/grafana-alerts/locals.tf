# For shared local values that are used across multiple resources
# See https://www.terraform.io/docs/language/values/locals.html
locals {
  chains = ["celo", "alfajores"]
  oracle_relayer_alert_config = {
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
