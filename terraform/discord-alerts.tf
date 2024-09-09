variable "discord_alerts_webhook_url_staging" {
  type    = string
  default = "https://discord.com/api/webhooks/1280908742346407999/j5QO_xV6PhAXVcQjmfp0gJ3FB-TRHHgg5CSiz2acErC-EZzaTIHm5Hya8Nv1B1CPkpX1"
}

variable "discord_alerts_webhook_url_prod" {
  type    = string
  default = "https://discord.com/api/webhooks/1282681325375197276/iOkrHNO5zl4cWsLjnp0CFTdxye1lcSbBxTADqBWInpN8bsbdVgVjpM_LVQTjjBKbs7Q1"
}

resource "grafana_contact_point" "discord_channel_oracle_relayers_staging" {
  name = "Discord #🚨|stg-oracle-relayers"

  discord {
    url     = var.discord_alerts_webhook_url_staging
    title   = "{{ template \"discord.message.stale_price_alert_title\" . }}"
    message = "{{ template \"discord.message.stale_price_alert_message\" . }}"
  }
}

resource "grafana_contact_point" "discord_channel_oracle_relayers_prod" {
  name = "Discord #🚨|prod-oracle-relayers"

  discord {
    url     = var.discord_alerts_webhook_url_prod
    title   = "{{ template \"discord.message.stale_price_alert_title\" . }}"
    message = "{{ template \"discord.message.stale_price_alert_message\" . }}"
  }
}


resource "grafana_message_template" "stale_price_alert_title" {
  name     = "Discord: Stale Price Alert Title"
  template = <<EOT
{{ define "discord.message.stale_price_alert_title" }}
[{{ if (len .Alerts.Firing) }}{{ len .Alerts.Firing }} FIRING{{ end }}{{ if and (len .Alerts.Firing) (len .Alerts.Resolved) }} | {{ end }}{{ if (len .Alerts.Resolved) }}{{ len .Alerts.Resolved }} RESOLVED{{ end }}] {{ .CommonLabels.alertname }}
{{ if (len .Alerts.Firing) }}Firing: {{ range $i, $alert := .Alerts.Firing -}}{{ if $i }}, {{ end }}{{ $alert.Labels.rateFeed }} on {{ $alert.Labels.chain | title }}{{ end }}{{ end }}
{{ if (len .Alerts.Resolved) }}Resolved: {{ range $i, $alert := .Alerts.Resolved -}}{{ if $i }}, {{ end }}{{ $alert.Labels.rateFeed }} on {{ $alert.Labels.chain | title }}{{ end }}{{ end }}
{{ end }}
EOT
}


resource "grafana_message_template" "stale_price_alert_message" {
  name     = "Discord: Stale Price Alert Message"
  template = <<EOT
{{ define "discord.message.stale_price_alert_message" }}
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


resource "grafana_rule_group" "oracle_relayers" {
  name             = "Oracle Relayers"
  folder_uid       = grafana_folder.oracle_relayers_folder.uid
  interval_seconds = 60

  dynamic "rule" {
    for_each = {
      alfajores = {
        label         = "Alfajores"
        contact_point = grafana_contact_point.discord_channel_oracle_relayers_staging.name
      }
      celo = {
        label         = "Celo"
        contact_point = grafana_contact_point.discord_channel_oracle_relayers_prod.name
      }
    }

    content {
      name      = "Oldest Report Expired Alert [${rule.value.label}]"
      condition = "condition"
      annotations = {
        summary = "The {{ $labels.rateFeed }} rate feed is stale on {{ $labels.chain | title }}. Check for possible issues with the oracle relayer."
      }
      labels = {
        service  = "oracles"
        severity = "info"
      }
      exec_err_state = "Error"
      for            = "1m"
      is_paused      = false
      no_data_state  = "NoData"

      notification_settings {
        contact_point = rule.value.contact_point
      }

      data {
        ref_id = "isOldestReportExpired"

        relative_time_range {
          from = 600
          to   = 0
        }

        datasource_uid = "grafanacloud-prom"
        model = jsonencode({
          disableTextWrap     = false
          expr                = "isOldestReportExpired{chain=\"${rule.key}\"}"
          fullMetaSearch      = false
          includeNullMetadata = true
          instant             = true
          intervalMs          = 1000
          legendFormat        = "__auto"
          maxDataPoints       = 43200
          range               = false
          refId               = "isOldestReportExpired"
          useBackend          = false
        })
      }
      data {
        ref_id = "condition"

        relative_time_range {
          from = 0
          to   = 0
        }

        datasource_uid = "__expr__"
        model = jsonencode({
          refId = "condition"
          conditions = [
            {
              type = "query"
              evaluator = {
                params = [0]
                type   = "gt"
              }
              operator = {
                type = "and"
              }
              query = {
                params = ["condition"]
              }
            }
          ]
          datasource = {
            type = "__expr__"
            uid  = "__expr__"
          }
          expression    = "isOldestReportExpired"
          intervalMs    = 1000
          maxDataPoints = 43200
          type          = "threshold"
        })
      }
    }
  }
}
