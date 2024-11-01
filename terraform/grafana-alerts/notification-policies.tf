resource "grafana_notification_policy" "all" {
  group_by      = ["alertname", "chain"]
  contact_point = grafana_contact_point.discord_channel_catch_all.name # Default contact point

  # for_each = rule.value == "celo" ? [grafana_contact_point.splunk_on_call.name, grafana_contact_point.discord_channel_oracle_relayers_prod.name] : [grafana_contact_point.discord_channel_oracle_relayers_staging.name]

  policy {
    group_wait      = "30s"
    group_interval  = "5m"
    repeat_interval = "4h"

    # On-Call Alerts
    policy {
      contact_point = grafana_contact_point.splunk_on_call.name

      matcher {
        label = "severity"
        match = "="
        value = "page"
      }

      continue = true
    }

    # Oracle Relayer Alerts [Alfajores]
    policy {
      contact_point = grafana_contact_point.discord_channel_oracle_relayers_staging.name

      matcher {
        label = "service"
        match = "="
        value = "oracle-relayers"
      }

      matcher {
        label = "chain"
        match = "="
        value = "alfajores"
      }

      continue = true
    }

    # Oracle Relayer Alerts [Celo Mainnet]
    policy {
      contact_point = grafana_contact_point.discord_channel_oracle_relayers_prod.name

      matcher {
        label = "service"
        match = "="
        value = "oracle-relayers"
      }

      matcher {
        label = "chain"
        match = "="
        value = "celo"
      }

      continue = true
    }

    # Reserve Alerts
    policy {
      contact_point = grafana_contact_point.discord_channel_reserve.name

      matcher {
        label = "service"
        match = "="
        value = "reserve"
      }

      continue = true
    }

    # Legacy Oracle Client Alerts
    policy {
      contact_point = "discord-alerts-oracles"

      matcher {
        label = "service"
        match = "="
        value = "oracles"
      }

      continue = true
    }

    # Trading Mode Alerts [Alfajores]
    policy {
      contact_point = grafana_contact_point.discord_channel_trading_modes_staging.name

      matcher {
        label = "service"
        match = "="
        value = "exchanges"
      }

      matcher {
        label = "chain"
        match = "="
        value = "alfajores"
      }

      continue = true
    }


    # Trading Mode Alerts [Celo Mainnet]
    policy {
      contact_point = grafana_contact_point.discord_channel_trading_modes_prod.name

      matcher {
        label = "service"
        match = "="
        value = "exchanges"
      }

      matcher {
        label = "chain"
        match = "="
        value = "celo"
      }

      continue = true
    }


    # Market Making Alerts
    policy {
      contact_point = "Market Making Alerts"

      matcher {
        label = "service"
        match = "="
        value = "marketmaker"
      }

      continue = true
    }
  }
}
