resource "grafana_rule_group" "oracle_relayers" {
  name             = "Oracle Relayer Alerts"
  folder_uid       = var.oracle_relayers_folder.uid
  interval_seconds = 120

  dynamic "rule" {
    for_each = local.chains

    content {
      name      = "Oldest Report Expired Alert [${title(rule.value)}]"
      condition = "isExpired"
      for       = "5m"
      annotations = {
        summary = "The {{ $labels.rateFeed }} rate feed is stale on {{ $labels.chain | title }}. Check for possible issues with the oracle relayer."
      }
      labels = {
        service  = "oracle-relayers"
        severity = rule.value == "celo" ? "page" : "warning"
      }
      exec_err_state = "Error"
      is_paused      = false
      no_data_state  = "NoData"

      data {
        ref_id         = "oldestReportStatus"
        datasource_uid = "grafanacloud-prom"

        relative_time_range {
          from = 600
          to   = 0
        }

        model = jsonencode({
          refId         = "oldestReportStatus"
          expr          = "SortedOracles_isOldestReportExpired{chain=\"${rule.value}\"}"
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
    for_each = local.chains

    content {
      name      = "Low CELO Balance Alert [${title(rule.value)}]"
      condition = "lowerThan20CELO"
      for       = "1m" // Alert if balance is low for at least 1 minutes
      annotations = {
        summary        = "Low CELO balance for {{ $labels.owner }} on {{ $labels.chain | title }}: {{ humanize (index $values \"balance\").Value }} CELO"
        currentBalance = "{{ humanize (index $values \"balance\").Value }}"
      }
      labels = {
        service  = "oracle-relayers"
        severity = rule.value == "celo" ? "warning" : "info"
      }
      exec_err_state = "Error"
      is_paused      = false
      no_data_state  = "NoData"

      data {
        ref_id         = "balanceOfRaw"
        datasource_uid = "grafanacloud-prom"
        relative_time_range {
          from = 600
          to   = 0
        }
        model = jsonencode({
          expr  = "CELOToken_balanceOf{chain=\"${rule.value}\", owner=~\"^RelayerSigner.*\"}"
          refId = "balanceOfRaw"
        })
      }
      data {
        ref_id         = "balance"
        datasource_uid = "__expr__"
        relative_time_range {
          from = 0
          to   = 0
        }
        model = jsonencode({
          expression = "balanceOfRaw",
          type       = "reduce",
          reducer    = "last",
          refId      = "balance"
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
          expression = "balance",
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
