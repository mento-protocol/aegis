resource "grafana_rule_group" "trading_modes" {
  name             = "Trading Mode Alerts"
  folder_uid       = var.trading_modes_folder.uid
  interval_seconds = 120

  dynamic "rule" {
    for_each = local.chains

    content {
      name      = "Trading Mode Alert [${title(rule.value)}]"
      condition = "isTradingHalted"
      for       = "5m"
      annotations = {
        summary = "Trading is halted for the {{ $labels.rateFeed }} rate feed on {{ $labels.chain | title }}. Check if a breaker tripped."
      }
      labels = {
        service  = "exchanges"
        severity = "warning"
      }
      exec_err_state = "Error"
      is_paused      = false
      no_data_state  = "NoData"

      data {
        ref_id         = "tradingMode"
        datasource_uid = "grafanacloud-prom"

        relative_time_range {
          from = 600
          to   = 0
        }

        model = jsonencode({
          refId         = "tradingMode"
          expr          = "BreakerBox_getRateFeedTradingMode{chain=\"${rule.value}\"}"
          instant       = true
          intervalMs    = 1000
          maxDataPoints = 43200
        })
      }
      data {
        ref_id         = "isTradingHalted"
        datasource_uid = "__expr__"

        relative_time_range {
          from = 0
          to   = 0
        }

        model = jsonencode({
          refId = "isTradingHalted"
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
                params = ["isTradingHalted"]
              }
            }
          ]
          datasource = {
            type = "__expr__"
            uid  = "__expr__"
          }
          expression = "tradingMode"
          intervalMs = 1000
          type       = "threshold"
        })
      }
    }
  }
}
