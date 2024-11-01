resource "grafana_contact_point" "discord_channel_oracle_relayers_staging" {
  name = "Discord #🚨|stg-oracle-relayers"

  discord {
    url     = var.discord_alerts_webhook_url_staging
    title   = local.alert_config.title
    message = local.alert_config.message
  }
}

resource "grafana_contact_point" "discord_channel_oracle_relayers_prod" {
  name = "Discord #🚨|prod-oracle-relayers"

  discord {
    url     = var.discord_alerts_webhook_url_prod
    title   = local.alert_config.title
    message = local.alert_config.message
  }
}

resource "grafana_contact_point" "discord_channel_reserve" {
  name = "Discord #🚨|reserve"

  discord {
    url     = var.discord_alerts_webhook_url_reserve
    title   = local.alert_config.title
    message = local.alert_config.message
  }
}

resource "grafana_contact_point" "discord_channel_trading_modes_staging" {
  name = "Discord #🚨|stg-trading-modes"

  discord {
    url     = var.discord_alerts_webhook_url_trading_modes_staging
    title   = local.alert_config.title
    message = local.alert_config.message
  }
}

resource "grafana_contact_point" "discord_channel_trading_modes_prod" {
  name = "Discord #🚨|prod-trading-modes"

  discord {
    url     = var.discord_alerts_webhook_url_trading_modes_prod
    title   = local.alert_config.title
    message = local.alert_config.message
  }
}


# A catch all channel for all alerts and notification policies that don't have a specific contact point defined
resource "grafana_contact_point" "discord_channel_catch_all" {
  name = "Discord #alerts-catch-all"

  discord {
    url = var.discord_alerts_webhook_url_catch_all
  }
}

resource "grafana_contact_point" "splunk_on_call" {
  name = "Splunk On-Call"

  victorops {
    url         = var.splunk_on_call_alerts_webhook_url
    title       = local.alert_config.title
    description = local.alert_config.message
  }
}
