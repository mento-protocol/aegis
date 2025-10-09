resource "grafana_message_template" "aegis_service_alert_title" {
  name     = "Discord: Aegis Service Alert Title"
  template = <<EOT
{{ define "discord.aegis_service_alert_title" }}
[{{ if (len .Alerts.Firing) }}{{ len .Alerts.Firing }} FIRING{{ end }}{{ if and (len .Alerts.Firing) (len .Alerts.Resolved) }} | {{ end }}{{ if (len .Alerts.Resolved) }}{{ len .Alerts.Resolved }} RESOLVED{{ end }}] {{ .CommonLabels.alertname }}
{{ if (len .Alerts.Firing) }}Firing: {{ range $i, $alert := .Alerts.Firing -}}{{ if $i }}, {{ end }}{{ $alert.Labels.alertname }}{{ end }}{{ end }}
{{ if (len .Alerts.Resolved) }}Resolved: {{ range $i, $alert := .Alerts.Resolved -}}{{ if $i }}, {{ end }}{{ $alert.Labels.alertname }}{{ end }}{{ end }}
{{ end }}
EOT
}

resource "grafana_message_template" "aegis_service_alert_message" {
  name     = "Discord: Aegis Service Alert Message"
  template = <<EOT
{{ define "discord.aegis_service_alert_message" }}
{{ if eq (len .Alerts.Firing) 0 }}No alerts are currently firing.{{ end }}
{{ range .Alerts.Firing }}
{{ if eq .Labels.alertname "Number of failed rpc calls" }}
**🚨 FIRING: High number of failed RPC calls detected**
- More than 10 errors were detected in a 5-minute timespan
- Check the Aegis service logs for potential issues via `pnpm logs`
- Verify RPC endpoint connectivity and stability
{{ else if eq .Labels.alertname "Aegis does not report new data" }}
**🚨 FIRING: Aegis service is not reporting new data**
- Aegis has not pushed any new data for more than 5 minutes
- The service may be down or experiencing issues
- Check Aegis service status and logs immediately
{{ else }}
**🚨 FIRING: {{ .Labels.alertname }}**
{{ .Annotations.summary }}
{{ end }}
{{ end }}
{{ range .Alerts.Resolved }}
{{ if eq .Labels.alertname "Number of failed rpc calls" }}
**✅ RESOLVED: RPC call failures have decreased**
- The number of failed RPC calls is now within acceptable limits
{{ else if eq .Labels.alertname "Aegis does not report new data" }}
**✅ RESOLVED: Aegis service is reporting data again**
- Aegis has resumed normal data reporting
{{ else }}
**✅ RESOLVED: {{ .Labels.alertname }}**
{{ end }}
{{ end }}
{{ end }}
EOT
}
