# NOTE: Reserve balance alerts are CELO-only because we don't have an actively maintained
# Reserve on Alfajores and some tokens (i.e. USDT) don't even exist there.
resource "grafana_rule_group" "reserve_balances" {
  name             = "Reserve Balance Alerts"
  folder_uid       = var.reserve_folder.uid
  interval_seconds = 120

  dynamic "rule" {
    for_each = {
      # trunk-ignore(checkov/CKV_SECRET_6)
      CELO  = { token = "CELOToken", threshold = 5000000 }
      USDC  = { token = "USDC", threshold = 2000000 }
      USDT  = { token = "USDT", threshold = 2000000 }
      EUROC = { token = "axlEUROC", threshold = 1000000 }
    }
    content {
      name      = "Low ${rule.key} Reserve Balance Alert"
      condition = "lowerThan${rule.value.threshold / 1000000}m${rule.key}"

      # Threshold must be breached for at least 1 hour. Using the default 1m could get very noisy.
      # Because due to trades in both directions, it could temporarily dip below the threshold and
      # then back above it many times, causing a lot of alerts.
      for            = "60m"
      exec_err_state = "Error"
      no_data_state  = "NoData"

      annotations = {
        summary        = "Low ${rule.key} Reserve Balance: {{ humanize (index $values \"balance\").Value }} ${rule.key}"
        threshold      = "{{ humanize (${rule.value.threshold}) }}"
        currentBalance = "{{ humanize (index $values \"balance\").Value }} ${rule.key}"
      }
      labels = {
        service  = "reserve"
        severity = "warning"
        token    = rule.value.token
      }

      data {
        ref_id         = "a"
        datasource_uid = "grafanacloud-prom"
        relative_time_range {
          from = 600
          to   = 0
        }
        model = jsonencode({
          expr  = "${rule.value.token}_balanceOf{chain=\"celo\", owner=\"Reserve\"}"
          refId = "a"
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
          expression = "a"
          type       = "reduce"
          reducer    = "last"
          refId      = "balance"
        })
      }
      data {
        ref_id         = "lowerThan${rule.value.threshold / 1000000}m${rule.key}"
        datasource_uid = "__expr__"
        relative_time_range {
          from = 0
          to   = 0
        }
        model = jsonencode({
          type       = "threshold"
          expression = "balance"
          refId      = "lowerThan${rule.value.threshold / 1000000}m${rule.key}"
          conditions = [{
            evaluator = {
              params = [rule.value.threshold]
              type   = "lt"
            }
            operator = {
              type = "and"
            }
            reducer = {
              params = []
              type   = "last"
            }
            type = "query"
          }]
        })
      }
    }
  }
}
