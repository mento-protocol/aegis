locals {
  # Panel ID ranges for better organization
  trading_mode_id_start              = 1
  oracle_relayer_id_start            = 100
  reserve_id_start                   = 200
  stable_token_supply_id_start       = 250
  trading_limits_id_start            = 300
  aegis_system_verification_id_start = 400

  # Y-position management
  trading_mode_y_start              = 0
  trading_mode_height               = 13 # 1 (row) + 12 (panel)
  oracle_relayer_y_start            = local.trading_mode_y_start + local.trading_mode_height
  oracle_relayer_height             = 29 # 1 (row) + 20 (freshness) + 8 (balances)
  reserve_y_start                   = local.oracle_relayer_y_start + local.oracle_relayer_height
  reserve_height                    = 17 # 1 (row) + 16 (panel)
  stable_token_supply_y_start       = local.reserve_y_start + local.reserve_height
  stable_token_supply_height        = 17 # 1 (row) + 16 (both panels side-by-side)
  trading_limits_y_start            = local.stable_token_supply_y_start + local.stable_token_supply_height
  trading_limits_height             = 25 # 1 (row) + 12 (L0) + 12 (Global)
  aegis_system_verification_y_start = local.trading_limits_y_start + local.trading_limits_height

  trading_mode_panels = concat(
    [
      {
        id      = local.trading_mode_id_start
        type    = "row"
        title   = "Trading Modes"
        gridPos = { x = 0, y = local.trading_mode_y_start, h = 1, w = 24 }
      }
    ],
    flatten([
      for i, chain in local.chains : [
        merge(local.common_panel_config, local.state_timeline_config, {
          id          = local.trading_mode_id_start + 1 + i
          title       = "Rate Feed Trading Mode [${chain}]"
          description = "Rate feed trading mode for each active rate feed. If != 0, it means the trading is halted for that pair."
          gridPos     = { x = i * 12, y = local.trading_mode_y_start + 1, h = 12, w = 24 / length(local.chains) }
          fieldConfig = {
            defaults = merge(local.state_timeline_config.fieldConfig.defaults, {
              decimals = 0
              max      = 3
              min      = 0
              thresholds = {
                mode = "absolute"
                steps = [
                  { color = "green", value = null },
                  { color = "red", value = 80 }
                ]
              }
            })
          }
          targets = [{
            expr         = "BreakerBox_getRateFeedTradingMode{chain=\"${chain}\"}"
            legendFormat = "{{rateFeed}}"
          }]
        })
      ]
    ])
  )
}
