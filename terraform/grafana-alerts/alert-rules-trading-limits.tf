resource "grafana_rule_group" "trading_limits" {
  name             = "Trading Limits Alerts"
  folder_uid       = var.trading_limits_folder.uid
  interval_seconds = 120

  # L0 Short-term Limit Alert (Discord only)
  rule {
    name           = "L0 Trading Limit Alert [Celo]"
    condition      = "limitExceeded"
    for            = "5m"
    exec_err_state = "Error"
    no_data_state  = "NoData"

    annotations = {
      summary = "L0 (short-term) trading limit at {{ printf \"%.1f\" (index $values \"utilization\").Value }}% for {{ $labels.limitId }} on {{ $labels.chain | title }}"
    }

    labels = {
      service   = "trading-limits"
      severity  = "warning"
      limitType = "L0"
    }

    data {
      ref_id         = "netflow"
      datasource_uid = "grafanacloud-prom"

      relative_time_range {
        from = 600
        to   = 0
      }

      model = jsonencode({
        refId   = "netflow"
        expr    = "Broker_tradingLimitsState_netflow0{chain=\"celo\"}"
        instant = true
      })
    }

    data {
      ref_id         = "limit"
      datasource_uid = "grafanacloud-prom"

      relative_time_range {
        from = 600
        to   = 0
      }

      model = jsonencode({
        refId   = "limit"
        expr    = "clamp_min(abs(Broker_tradingLimitsConfig_limit0{chain=\"celo\"}), 1)"
        instant = true
      })
    }

    data {
      ref_id         = "utilization"
      datasource_uid = "__expr__"

      relative_time_range {
        from = 0
        to   = 0
      }

      model = jsonencode({
        refId      = "utilization"
        type       = "math"
        expression = "(abs($netflow) / $limit) * 100"
        datasource = {
          type = "__expr__"
          uid  = "__expr__"
        }
      })
    }

    data {
      ref_id         = "limitExceeded"
      datasource_uid = "__expr__"

      relative_time_range {
        from = 0
        to   = 0
      }

      model = jsonencode({
        refId = "limitExceeded"
        conditions = [
          {
            type = "query"
            evaluator = {
              params = [90]
              type   = "gt"
            }
            operator = {
              type = "and"
            }
            query = {
              params = ["limitExceeded"]
            }
          }
        ]
        datasource = {
          type = "__expr__"
          uid  = "__expr__"
        }
        expression = "utilization"
        type       = "threshold"
      })
    }
  }

  # L1 Medium-term Limit Alert (Discord + VictorOps)
  rule {
    name           = "L1 Trading Limit Alert [Celo]"
    condition      = "limitExceeded"
    for            = "5m"
    exec_err_state = "Error"
    no_data_state  = "NoData"

    annotations = {
      summary = "L1 (medium-term) trading limit at {{ printf \"%.1f\" (index $values \"utilization\").Value }}% for {{ $labels.limitId }} on {{ $labels.chain | title }}"
    }

    labels = {
      service   = "trading-limits"
      severity  = "page"
      limitType = "L1"
    }

    data {
      ref_id         = "netflow"
      datasource_uid = "grafanacloud-prom"

      relative_time_range {
        from = 600
        to   = 0
      }

      model = jsonencode({
        refId   = "netflow"
        expr    = "Broker_tradingLimitsState_netflow1{chain=\"celo\"}"
        instant = true
      })
    }

    data {
      ref_id         = "limit"
      datasource_uid = "grafanacloud-prom"

      relative_time_range {
        from = 600
        to   = 0
      }

      model = jsonencode({
        refId   = "limit"
        expr    = "clamp_min(abs(Broker_tradingLimitsConfig_limit1{chain=\"celo\"}), 1)"
        instant = true
      })
    }

    data {
      ref_id         = "utilization"
      datasource_uid = "__expr__"

      relative_time_range {
        from = 0
        to   = 0
      }

      model = jsonencode({
        refId      = "utilization"
        type       = "math"
        expression = "(abs($netflow) / $limit) * 100"
        datasource = {
          type = "__expr__"
          uid  = "__expr__"
        }
      })
    }

    data {
      ref_id         = "limitExceeded"
      datasource_uid = "__expr__"

      relative_time_range {
        from = 0
        to   = 0
      }

      model = jsonencode({
        refId = "limitExceeded"
        conditions = [
          {
            type = "query"
            evaluator = {
              params = [90]
              type   = "gt"
            }
            operator = {
              type = "and"
            }
            query = {
              params = ["limitExceeded"]
            }
          }
        ]
        datasource = {
          type = "__expr__"
          uid  = "__expr__"
        }
        expression = "utilization"
        type       = "threshold"
      })
    }
  }

  # LG Global Lifetime Limit Alert (Discord + VictorOps)
  rule {
    name           = "LG Trading Limit Alert [Celo]"
    condition      = "limitExceeded"
    for            = "5m"
    exec_err_state = "Error"
    no_data_state  = "NoData"

    annotations = {
      summary = "LG (global lifetime) trading limit at {{ printf \"%.1f\" (index $values \"utilization\").Value }}% for {{ $labels.limitId }} on {{ $labels.chain | title }}"
    }

    labels = {
      service   = "trading-limits"
      severity  = "page"
      limitType = "LG"
    }

    data {
      ref_id         = "netflow"
      datasource_uid = "grafanacloud-prom"

      relative_time_range {
        from = 600
        to   = 0
      }

      model = jsonencode({
        refId   = "netflow"
        expr    = "Broker_tradingLimitsState_netflowGlobal{chain=\"celo\"}"
        instant = true
      })
    }

    data {
      ref_id         = "limit"
      datasource_uid = "grafanacloud-prom"

      relative_time_range {
        from = 600
        to   = 0
      }

      model = jsonencode({
        refId   = "limit"
        expr    = "clamp_min(abs(Broker_tradingLimitsConfig_limitGlobal{chain=\"celo\"}), 1)"
        instant = true
      })
    }

    data {
      ref_id         = "utilization"
      datasource_uid = "__expr__"

      relative_time_range {
        from = 0
        to   = 0
      }

      model = jsonencode({
        refId      = "utilization"
        type       = "math"
        expression = "(abs($netflow) / $limit) * 100"
        datasource = {
          type = "__expr__"
          uid  = "__expr__"
        }
      })
    }

    data {
      ref_id         = "limitExceeded"
      datasource_uid = "__expr__"

      relative_time_range {
        from = 0
        to   = 0
      }

      model = jsonencode({
        refId = "limitExceeded"
        conditions = [
          {
            type = "query"
            evaluator = {
              params = [90]
              type   = "gt"
            }
            operator = {
              type = "and"
            }
            query = {
              params = ["limitExceeded"]
            }
          }
        ]
        datasource = {
          type = "__expr__"
          uid  = "__expr__"
        }
        expression = "utilization"
        type       = "threshold"
      })
    }
  }
}

