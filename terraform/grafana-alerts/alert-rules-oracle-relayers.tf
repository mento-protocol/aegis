resource "grafana_rule_group" "oracle_relayers" {
  name             = "Oracle Relayer Alerts"
  folder_uid       = var.oracle_relayers_folder.uid
  interval_seconds = 120

  dynamic "rule" {
    for_each = local.chains

    content {
      name           = "Oldest Report Expired [${title(rule.value)}]"
      condition      = "isExpired"
      for            = "5m"
      exec_err_state = "Error"
      no_data_state  = "NoData"

      annotations = {
        summary = "The {{ $labels.rateFeed }} rate feed is stale on {{ $labels.chain | title }}. Check for possible issues with the oracle relayer."
      }

      labels = {
        service  = "oracle-relayers"
        severity = rule.value == "celo" ? "page" : "warning"
      }

      data {
        ref_id         = "oldestReportStatus"
        datasource_uid = "grafanacloud-prom"

        relative_time_range {
          from = 600
          to   = 0
        }

        model = jsonencode({
          refId   = "oldestReportStatus"
          expr    = "SortedOracles_isOldestReportExpired{chain=\"${rule.value}\"}"
          instant = true
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
          type       = "threshold"
        })
      }
    }
  }

  dynamic "rule" {
    for_each = local.chains

    content {
      name           = "Low CELO Balance [${title(rule.value)}]"
      condition      = "lowerThan20CELO"
      for            = "1m" // Alert if balance is low for at least 1 minutes
      exec_err_state = "Error"
      no_data_state  = "NoData"

      annotations = {
        summary        = "Low CELO balance for {{ $labels.owner }} on {{ $labels.chain | title }}: {{ humanize (index $values \"balance\").Value }} CELO"
        currentBalance = "{{ humanize (index $values \"balance\").Value }}"
      }

      labels = {
        service  = "oracle-relayers"
        severity = rule.value == "celo" ? "warning" : "info"
      }

      data {
        ref_id         = "balanceOfRaw"
        datasource_uid = "grafanacloud-prom"
        relative_time_range {
          from = 600
          to   = 0
        }
        model = jsonencode({
          # NOTE: Grafana syntax is a bit confusing here in that 'expr' and 'expression' mean different things
          # This is a Prometheus PromQL query that fetches the balance of the CELO token for all RelayerSigner accounts
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
          # This is a Grafana expression that reduces the balance of the CELO token for all RelayerSigner accounts to a single value
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
