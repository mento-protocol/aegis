resource "grafana_message_template" "trading_limits_alert_title" {
  name     = "Discord: Trading Limits Alert Title"
  template = <<EOT
  {{ define "discord.trading_limits_alert_title" }}
  [{{ if (len .Alerts.Firing) -}}{{ len .Alerts.Firing }} FIRING{{ end -}}
  {{ if and (len .Alerts.Firing) (len .Alerts.Resolved) -}} | {{ end -}}
  {{ if (len .Alerts.Resolved) -}}{{ len .Alerts.Resolved }} RESOLVED{{ end -}}] {{ .CommonLabels.alertname -}}
  {{ end -}}
  EOT
}

resource "grafana_message_template" "trading_limits_alert_message" {
  name     = "Discord: Trading Limits Alert Message"
  template = <<EOT
{{ define "discord.trading_limits_alert_message" }}
{{ range .Alerts.Firing -}}
{{ $chain := .Labels.chain | title -}}
{{ $limitType := .Labels.limitType -}}
{{ $utilization := printf "%.1f" .Values.utilization.Value -}}
**🚨 Trading Limit {{ $limitType }} at {{ $utilization }}% for [{{ .Labels.limitId }}]({{ .GeneratorURL }}&tab=instances) on {{ $chain }}**
- Current utilization: {{ $utilization }}%
- Limit Type: {{ $limitType }}{{ if eq $limitType "L0" }} - short-term (5 minutes){{ else if eq $limitType "L1" }} - medium-term (daily){{ else if eq $limitType "LG" }} - global (has to be manually reset){{ end }}{{ if or (eq $limitType "L1") (eq $limitType "LG") }}
- **Action Required**: This is a {{ if eq $limitType "L1" }}medium-term (daily){{ else }}lifetime{{ end }} limit breach{{ end }}
{{ end -}}

{{ range .Alerts.Resolved -}}
{{ $chain := .Labels.chain | title -}}
{{ $limitType := .Labels.limitType -}}
- **✅ Trading Limit {{ $limitType }} resolved for {{ .Labels.limitId }} on {{ $chain }}**
{{ end -}}
{{ end -}}

{{ if eq (len .Alerts.Firing) 0 }}No alerts are currently firing 🙂.{{ end }}
EOT
}

