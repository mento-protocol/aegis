resource "grafana_dashboard" "aegis" {
  folder = var.aegis_folder.uid
  config_json = jsonencode({
    title = "Aegis - On-chain Metrics"
    time  = { from = "now-60m", to = "now" }
    panels = concat(
      local.trading_mode_panels,
      local.oracle_relayer_panels,
      local.reserve_panels,
      local.stable_token_supply_panels,
      local.trading_limits_panels,
      local.aegis_system_verification_panels
    )
  })
}
