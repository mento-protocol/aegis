locals {
  oracle_relayer_panels = concat(
    [
      {
        id      = length(local.chains) + 2
        type    = "row"
        title   = "Oracles - Chainlink Relayers"
        gridPos = { x = 0, y = 9, h = 1, w = 24 }
      }
    ],
    flatten([
      for i, chain in local.chains : [
        merge(local.common_panel_config, local.state_timeline_config, {
          id          = i + length(local.chains) + 3
          title       = "Rate Feed Freshness [${chain}]"
          description = "Shows if the oldest report in SortedOracles is expired for each relayed rate feed. 1 means expired, 0 means not expired."
          gridPos     = { x = i * 12, y = 10, h = 20, w = 24 / length(local.chains) }
          fieldConfig = {
            defaults = merge(local.state_timeline_config.fieldConfig.defaults, {
              decimals = 0
              max      = 1
              min      = 0
              thresholds = {
                mode = "absolute"
                steps = [
                  { color = "green", value = null },
                  { color = "red", value = 1 }
                ]
              }
            })
          }
          targets = [{
            expr         = "SortedOracles_isOldestReportExpired{chain=\"${chain}\"}"
            legendFormat = "{{rateFeed}}"
          }]
        })
      ]
    ]),
    [
      for i, chain in local.chains : merge(local.common_panel_config, {
        id          = length(local.chains) * 2 + 3 + i
        type        = "timeseries"
        title       = "CELO Balances of Relayer Signers [${chain}]"
        description = "CELO balance of relayer signers on ${chain}. Red line indicates danger threshold."
        gridPos = {
          x = i * 12,
          y = 14,
          h = 8,
          w = 12
        }
        fieldConfig = {
          defaults = {
            custom = {
              drawStyle         = "line"
              lineInterpolation = "linear"
              fillOpacity       = 10
              gradientMode      = "none"
              spanNulls         = false
              showPoints        = "auto"
              pointSize         = 5
              stacking = {
                mode  = "none"
                group = "A"
              }
              axisPlacement = "auto"
              axisLabel     = "CELO Balance"
              axisColorMode = "text"
              scaleDistribution = {
                type = "linear"
              }
              axisCenteredZero = false
              hideFrom = {
                tooltip = false
                viz     = false
                legend  = false
              }
              # This will draw the threshold as a line
              thresholdsStyle = {
                mode = "line"
              }
            }
            color    = { mode = "palette-classic" }
            mappings = []
            thresholds = {
              mode = "absolute"
              steps = [
                { color = "green", value = null },
                { color = "red", value = 10 }
              ]
            }
            unit = "locale"
            min  = 0 # Set the minimum value of the y-axis to 0 so the threshold line is always visible
          }
        }
        options = {
          tooltip = { mode = "multi" }
          legend = {
            showLegend  = true
            displayMode = "table"
            placement   = "bottom"
            calcs       = ["lastNotNull"]
          }
        }
        targets = [{
          expr         = "CELOToken_balanceOf{chain=\"${chain}\", owner!=\"Reserve\"}"
          legendFormat = "{{owner}}" # This line is updated to use the 'owner' label
          refId        = chain
        }]
      })
    ]
  )
}
