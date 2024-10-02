resource "grafana_message_template" "reserve_balance_alert_title" {
  name     = "Discord: Reserve Balance Alert Title"
  template = <<EOT
  {{ define "discord.reserve_balance_alert_title" }}
  [{{ if (len .Alerts.Firing) -}}{{ len .Alerts.Firing }} FIRING{{ end -}}
  {{ if and (len .Alerts.Firing) (len .Alerts.Resolved) -}} | {{ end -}}
  {{ if (len .Alerts.Resolved) -}}{{ len .Alerts.Resolved }} RESOLVED{{ end -}}] {{ .CommonLabels.alertname -}}
  {{ end -}}
  EOT
}

resource "grafana_message_template" "reserve_balance_alert_message" {
  name     = "Discord: Reserve Balance Alert Message"
  template = <<EOT
  {{ define "discord.reserve_balance_alert_message" }}
  {{ if eq (len .Alerts.Firing) 0 }}No alerts are currently firing.{{ end }}
  {{ range .Alerts.Firing -}}
  {{ $token := .Labels.token -}}
  {{ $reserveAddress := .Labels.ownerValue -}}
**🚨 FIRING: Low {{ $token }} balance — {{ .Annotations.currentBalance }} left**
Please top up the {{ $token }} balance of the [{{ .Labels.owner }}](https://celoscan.io/address/{{ $reserveAddress }}) above the alert threshold of {{ .Annotations.threshold }} {{ $token }}
{{ if .GeneratorURL -}}[Grafana Alert Link ->]({{ .GeneratorURL }}){{- end }}
  {{ end -}}
  {{ range .Alerts.Resolved -}}
  {{ $token := .Labels.token -}}
  {{ $reserveAddress := .Labels.ownerValue -}}
**✅ RESOLVED: Sufficient {{ $token }} balance restored for the [{{ .Labels.owner }}](https://celoscan.io/address/{{ $reserveAddress }}) — {{ .Annotations.currentBalance }}**
  {{ end -}}
  {{ end -}}
  EOT
}
