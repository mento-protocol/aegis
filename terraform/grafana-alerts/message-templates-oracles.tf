resource "grafana_message_template" "oracle_stale_price_alert_title" {
  name     = "Discord: Stale Price Alert Title"
  template = <<EOT
{{ define "discord.oracle_stale_price_alert_title" }}
[{{ if (len .Alerts.Firing) }}{{ len .Alerts.Firing }} FIRING{{ end }}{{ if and (len .Alerts.Firing) (len .Alerts.Resolved) }} | {{ end }}{{ if (len .Alerts.Resolved) }}{{ len .Alerts.Resolved }} RESOLVED{{ end }}] {{ .CommonLabels.alertname }}
{{ if (len .Alerts.Firing) }}Firing: {{ range $i, $alert := .Alerts.Firing -}}{{ if $i }}, {{ end }}{{ $alert.Labels.rateFeed }} on {{ $alert.Labels.chain | title }}{{ end }}{{ end }}
{{ if (len .Alerts.Resolved) }}Resolved: {{ range $i, $alert := .Alerts.Resolved -}}{{ if $i }}, {{ end }}{{ $alert.Labels.rateFeed }} on {{ $alert.Labels.chain | title }}{{ end }}{{ end }}
{{ end }}
EOT
}


resource "grafana_message_template" "oracle_stale_price_alert_message" {
  name     = "Discord: Stale Price Alert Message"
  template = <<EOT
{{ define "discord.oracle_stale_price_alert_message" }}
{{ if eq (len .Alerts.Firing) 0 }}No alerts are currently firing.{{ end }}
{{ range .Alerts.Firing }}
**🚨 FIRING: Stale price for {{ .Labels.rateFeed }} rate feed on {{ .Labels.chain | title }}**
1. Check the latest transactions of the {{ .Labels.rateFeed }} relayer on {{ .Labels.chain | title }}
2. Check if the relayer cloud function is still being triggered regularly
{{ end }}
{{ range .Alerts.Resolved }}
**✅ RESOLVED: Price is fresh again for {{ .Labels.rateFeed }} rate feed on {{ .Labels.chain }}**
{{ end }}
{{ end }}
EOT
}

resource "grafana_message_template" "oracle_relayer_low_celo_balance_alert_title" {
  name     = "Discord: Low CELO Balance Alert Title"
  template = <<EOT
{{ define "discord.oracle_relayer_low_celo_balance_alert_title" }}
[{{ if (len .Alerts.Firing) }}{{ len .Alerts.Firing }} FIRING{{ end }}{{ if and (len .Alerts.Firing) (len .Alerts.Resolved) }} | {{ end }}{{ if (len .Alerts.Resolved) }}{{ len .Alerts.Resolved }} RESOLVED{{ end }}] Low CELO Balance Alert
{{ if (len .Alerts.Firing) }}Firing: {{ range $i, $alert := .Alerts.Firing -}}{{ if $i }}, {{ end }}{{ $alert.Labels.owner }} on {{ $alert.Labels.chain | title }}{{ end }}{{ end }}
{{ if (len .Alerts.Resolved) }}Resolved: {{ range $i, $alert := .Alerts.Resolved -}}{{ if $i }}, {{ end }}{{ $alert.Labels.owner }} on {{ $alert.Labels.chain | title }}{{ end }}{{ end }}
{{ end }}
EOT
}


resource "grafana_message_template" "oracle_relayer_low_celo_balance_alert_message" {
  name     = "Discord: Low CELO Balance Alert Message"
  template = <<EOT
{{ define "discord.oracle_relayer_low_celo_balance_alert_message" }}
{{ if eq (len .Alerts.Firing) 0 }}No alerts are currently firing.{{ end }}
{{ range .Alerts.Firing }}
**🚨 FIRING: Low CELO balance for {{ .Labels.owner }} on {{ .Labels.chain | title }} — {{ .Annotations.currentBalance }} CELO left**
- Please top up the {{ .Labels.owner }} wallet to ensure continued operation of the relayer
- You can do this by running the [refill script](https://github.com/mento-protocol/oracle-relayer?tab=readme-ov-file#refilling-relayer-signer-accounts) in the oracle-relayer repo
- Or alternatively, send 50 CELO to the {{ .Labels.owner }} ([{{ .Labels.ownerValue }}](https://{{ if eq .Labels.chain "alfajores" }}alfajores.{{ end }}celoscan.io/address/{{ .Labels.ownerValue }})) on {{ .Labels.chain | title }} from our Deployer wallet
- You can get the deployer wallet's private key by running `npm run secrets:get` in the [mento-deployment](https://github.com/mento-protocol/mento-deployment/blob/main/bin/get-secrets.sh) repo
{{ end }}
{{ range .Alerts.Resolved }}
**✅ RESOLVED: Sufficient CELO balance restored for [{{ .Labels.owner }}](https://{{ if eq .Labels.chain "alfajores" }}alfajores.{{ end }}celoscan.io/address/{{ .Labels.ownerValue }}) on {{ .Labels.chain | title }} — {{ .Annotations.currentBalance }} CELO**

{{ end }}
{{ end }}
EOT
}
