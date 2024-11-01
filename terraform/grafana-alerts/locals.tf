# For shared local values that are used across multiple resources
# See https://www.terraform.io/docs/language/values/locals.html
locals {
  chains = ["celo", "alfajores"]
  alert_types = {
    oracle_stale_price = {
      names = [
        "Oldest Report Expired Alert [Alfajores]",
        "Oldest Report Expired Alert [Celo]"
      ],
      title_template   = "discord.oracle_stale_price_alert_title",
      message_template = "discord.oracle_stale_price_alert_message"
    },
    oracle_relayer_low_celo_balance = {
      names = [
        "Low CELO Balance Alert [Alfajores]",
        "Low CELO Balance Alert [Celo]"
      ],
      title_template   = "discord.oracle_relayer_low_celo_balance_alert_title",
      message_template = "discord.oracle_relayer_low_celo_balance_alert_message"
    },
    low_reserve_balance = {
      names = [
        "Low CELO Reserve Balance Alert",
        "Low USDC Reserve Balance Alert",
        "Low USDT Reserve Balance Alert",
        "Low EUROC Reserve Balance Alert"
      ],
      title_template   = "discord.reserve_balance_alert_title",
      message_template = "discord.reserve_balance_alert_message"
    },
    trading_halted = {
      names = [
        "Trading Mode Alert [Alfajores]",
        "Trading Mode Alert [Celo]"
      ],
      title_template   = "discord.trading_mode_alert_title",
      message_template = "discord.trading_mode_alert_message"
    }
  }
  alert_config = {
    title = <<EOT
    {{ $alertName := .CommonLabels.alertname }}
    %{for alert_type, config in local.alert_types~}
    %{for index, name in config.names~}
    %{if index == 0 && alert_type == keys(local.alert_types)[0]~}
    {{ if eq $alertName "${name}" }}
    %{else~}
    {{ else if eq $alertName "${name}" }}
    %{endif~}
    {{ template "${config.title_template}" . }}
    %{endfor~}
    %{endfor~}
    {{ else }}
    {{ $alertName }}
    {{ .CommonLabels }}
    {{ end }}
    EOT

    message = <<EOT
    {{ $alertName := .CommonLabels.alertname }}
    %{for alert_type, config in local.alert_types~}
    %{for index, name in config.names~}
    %{if index == 0 && alert_type == keys(local.alert_types)[0]~}
    {{ if (eq $alertName "${name}") }}
    %{else~}
    {{ else if (eq $alertName "${name}") }}
    %{endif~}
    {{ template "${config.message_template}" . }}
    %{endfor~}
    %{endfor~}
    {{ else if (eq $alertName "DatasourceError") }}
    The Grafana alert query might be broken. Please check the alert configuration.
    {{ else }}
    {{ $alertName}}
    {{ .CommonLabels }}
    {{ end }}
    EOT
  }
}
