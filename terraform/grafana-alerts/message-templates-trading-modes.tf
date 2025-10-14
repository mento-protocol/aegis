resource "grafana_message_template" "trading_mode_alert_title" {
  name     = "Discord: Trading Mode Alert Title"
  template = <<EOT
  {{ define "discord.trading_mode_alert_title" }}
  [{{ if (len .Alerts.Firing) -}}{{ len .Alerts.Firing }} FIRING{{ end -}}
  {{ if and (len .Alerts.Firing) (len .Alerts.Resolved) -}} | {{ end -}}
  {{ if (len .Alerts.Resolved) -}}{{ len .Alerts.Resolved }} RESOLVED{{ end -}}] {{ .CommonLabels.alertname -}}
  {{ end -}}
  EOT
}

resource "grafana_message_template" "trading_mode_alert_message" {
  name     = "Discord: Trading Mode Alert Message"
  template = <<EOT
{{ define "discord.trading_mode_alert_message" }}
{{ range .Alerts.Firing -}}
{{ $rateFeedWithHyphen := reReplaceAll "([A-Z]{3,})([A-Z]{3})" "$1-$2" .Labels.rateFeed -}}
{{ $chain := .Labels.chain | title -}}
**🚨 Trading halted for [{{ .Labels.rateFeed }}]({{ .GeneratorURL }}&tab=instances) on {{ $chain }}**{{ if eq $chain "Celo" }}
- Check the [Circuit Breaker Dashboard](https://dune.com/mento-labs-eng/circuit-breakers) for tripped breakers
- Check the [Chainlink feed](https://data.chain.link/feeds/celo/mainnet/{{ $rateFeedWithHyphen }}) for volatility around the alert time{{ end }}
{{ end -}}

{{ range .Alerts.Resolved -}}
{{ $rateFeedWithSlash := reReplaceAll "([A-Z]{3,})([A-Z]{3})" "$1/$2" .Labels.rateFeed -}}
{{ $chain := .Labels.chain | title -}}
- **✅ Trading resumed for {{ $rateFeedWithSlash }} on {{ $chain }}**
{{ end -}}
{{ end -}}

{{ if eq (len .Alerts.Firing) 0 }}No alerts are currently firing 🙂.{{ end }}
EOT
}
