resource "grafana_dashboard" "aegis" {
  folder = var.aegis_folder.uid
  config_json = jsonencode({
    title = "Aegis - On-chain Metrics"
    time  = { from = "now-60m", to = "now" }
    panels = concat(
      local.trading_mode_panels,
      local.oracle_relayer_panels,
      local.legacy_client_panels,
    )
  })
}
