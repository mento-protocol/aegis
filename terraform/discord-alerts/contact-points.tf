resource "grafana_contact_point" "discord_channel_oracle_relayers_staging" {
  name = "Discord #🚨|stg-oracle-relayers"

  discord {
    url     = var.discord_alerts_webhook_url_staging
    title   = local.discord_alert_oracle_relayer_config.title
    message = local.discord_alert_oracle_relayer_config.message
  }
}

resource "grafana_contact_point" "discord_channel_oracle_relayers_prod" {
  name = "Discord #🚨|prod-oracle-relayers"

  discord {
    url     = var.discord_alerts_webhook_url_prod
    title   = local.discord_alert_oracle_relayer_config.title
    message = local.discord_alert_oracle_relayer_config.message
  }
}
