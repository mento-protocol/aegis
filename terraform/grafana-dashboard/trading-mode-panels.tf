locals {
  trading_mode_panels = concat(
    [
      {
        id      = 1
        type    = "row"
        title   = "Trading Modes"
        gridPos = { x = 0, y = 0, h = 1, w = 24 }
      }
    ],
    flatten([
      for i, chain in local.chains : [
        merge(local.common_panel_config, local.state_timeline_config, {
          id          = i + 2
          title       = "Rate Feed Trading Mode [${chain}]"
          description = "Rate feed trading mode for each active rate feed. If != 0, it means the trading is halted for that pair."
          gridPos     = { x = i * 12, y = 1, h = 12, w = 24 / length(local.chains) }
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
