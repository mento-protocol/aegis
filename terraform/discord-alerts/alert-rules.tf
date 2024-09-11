resource "grafana_rule_group" "oracle_relayers" {
  name             = "Oracle Relayer Alerts"
  folder_uid       = var.oracle_relayers_folder.uid
  interval_seconds = 60

  dynamic "rule" {
    for_each = local.chain_config

    content {
      name      = "Oldest Report Expired Alert [${rule.value.label}]"
      condition = "isExpired"
      for       = "1m"
      annotations = {
        summary = "The {{ $labels.rateFeed }} rate feed is stale on {{ $labels.chain | title }}. Check for possible issues with the oracle relayer."
      }
      labels = {
        service  = "oracles"
        severity = rule.key == "celo" ? "critical" : "warning"
      }
      exec_err_state = "Error"
      is_paused      = false
      no_data_state  = "NoData"

      notification_settings {
        contact_point = rule.value.contact_point
      }

      data {
        ref_id         = "oldestReportStatus"
        datasource_uid = "grafanacloud-prom"

        relative_time_range {
          from = 600
          to   = 0
        }

        model = jsonencode({
          refId         = "oldestReportStatus"
          expr          = "isOldestReportExpired{chain=\"${rule.key}\"}"
          instant       = true
          intervalMs    = 1000
          maxDataPoints = 43200
        })
      }
      data {
        ref_id         = "isExpired"
        datasource_uid = "__expr__"

        relative_time_range {
          from = 0
          to   = 0
        }

        model = jsonencode({
          refId = "isExpired"
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
                params = ["isExpired"]
              }
            }
          ]
          datasource = {
            type = "__expr__"
            uid  = "__expr__"
          }
          expression = "oldestReportStatus"
          intervalMs = 1000
          type       = "threshold"
        })
      }
    }
  }

  dynamic "rule" {
    for_each = local.chain_config

    content {
      name      = "Low CELO Balance Alert [${rule.value.label}]"
      condition = "lowerThan20CELO"
      for       = "1m" // Alert if balance is low for at least 1 minute
      annotations = {
        summary = "Low CELO balance for {{ $labels.owner }} on {{ $labels.chain | title }}. Current balance: {{ humanize $values.reducedBalanceOf }} CELO"
      }
      labels = {
        service  = "oracles"
        severity = rule.key == "celo" ? "critical" : "warning"
      }
      exec_err_state = "Error"
      is_paused      = false
      no_data_state  = "NoData"

      notification_settings {
        contact_point = rule.value.contact_point
      }

      data {
        ref_id         = "balanceOf"
        datasource_uid = "grafanacloud-prom"
        relative_time_range {
          from = 600
          to   = 0
        }
        model = jsonencode({
          expr  = "balanceOf{chain=\"${rule.key}\"}"
          refId = "balanceOf"
        })
      }
      data {
        ref_id         = "reducedBalanceOf"
        datasource_uid = "__expr__"
        relative_time_range {
          from = 0
          to   = 0
        }
        model = jsonencode({
          expression = "balanceOf",
          type       = "reduce",
          reducer    = "last",
          refId      = "reducedBalanceOf"
        })
      }
      data {
        ref_id         = "lowerThan20CELO"
        datasource_uid = "__expr__"
        relative_time_range {
          from = 0
          to   = 0
        }
        model = jsonencode({
          type       = "threshold",
          expression = "reducedBalanceOf",
          refId      = "lowerThan20CELO"
          conditions = [
            {
              evaluator = {
                params = [20],
                type   = "lt",
              },
              operator = {
                type = "and",
              },
              reducer = {
                params = [],
                type   = "last",
              },
              type = "query",
            },
          ],
        })
      }
    }
  }
}
