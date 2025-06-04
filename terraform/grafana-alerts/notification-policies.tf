resource "grafana_notification_policy" "all" {
  group_by      = ["alertname", "chain"]
  contact_point = grafana_contact_point.discord_channel_catch_all.name # Default contact point

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

      # Exclude the weekend-disabled feeds
      matcher {
        label = "rateFeed"
        match = "!~"
        value = local.weekend_disabled_feeds_pattern
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

      # Exclude the weekend-disabled feeds
      matcher {
        label = "rateFeed"
        match = "!~"
        value = local.weekend_disabled_feeds_pattern
      }

      continue = true
    }

    # Mute notifications on weekends for FX feeds that don't receive new data on weekends [Alfajores]
    policy {
      # Apply the mute timing to the policy
      mute_timings = [grafana_mute_timing.weekend_mute.name]

      # Use the same contact point as the Alfajores Oracle Relayer policy
      contact_point = grafana_contact_point.discord_channel_oracle_relayers_staging.name

      # Only apply this policy to the weekend-disabled feeds
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

      matcher {
        label = "rateFeed"
        match = "=~"
        value = local.weekend_disabled_feeds_pattern
      }

      # Set continue to false to prevent further processing of these specific alerts
      continue = false
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

      # Exclude the weekend-disabled feeds
      matcher {
        label = "rateFeed"
        match = "!~"
        value = local.weekend_disabled_feeds_pattern
      }

      continue = true
    }

    # Mute notifications on weekends for FX feeds that don't receive new data on weekends
    policy {
      # Apply the mute timing to the policy
      mute_timings = [grafana_mute_timing.weekend_mute.name]

      # Use the same contact point as the main Oracle Relayer policy
      contact_point = grafana_contact_point.discord_channel_oracle_relayers_prod.name

      # Only apply this policy to the weekend-disabled feeds
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

      matcher {
        label = "rateFeed"
        match = "=~"
        value = local.weekend_disabled_feeds_pattern
      }

      # Set continue to false to prevent further processing of these specific alerts
      continue = false
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
  }
}
