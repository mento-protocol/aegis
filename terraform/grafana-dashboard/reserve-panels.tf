locals {
  reserve_panels = [
    {
      id      = 3 * length(local.chains) + 8
      type    = "row"
      title   = "Reserve"
      gridPos = { x = 0, y = 57, h = 1, w = 24 }
    },
    merge(local.common_panel_config, {
      id          = 3 * length(local.chains) + 9
      type        = "timeseries"
      title       = "Reserve Token Balances [celo]"
      description = "USDC, USDT, axlUSDC, and CELO balances of the Reserve (0x9380fA34Fd9e4Fd14c06305fd7B6199089eD4eb9)."
      gridPos = {
        x = 0,
        y = 58,
        h = 16,
        w = 24
      }
      fieldConfig = {
        defaults = {
          custom = {
            drawStyle         = "line"
            lineInterpolation = "smooth"
            fillOpacity       = 10
            gradientMode      = "none"
            spanNulls         = false
            showPoints        = "never"
            pointSize         = 5
            lineWidth         = 2
            stacking = {
              mode  = "none"
              group = "A"
            }
            axisPlacement = "auto"
            axisLabel     = "Token Balance"
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
          }
          color    = { mode = "palette-classic" }
          mappings = []
          unit     = "locale"
          min      = 0
        }
        overrides = [
          {
            matcher = { id = "byName", options = "CELO" }
            properties = [
              {
                id    = "custom.axisLabel"
                value = "CELO Balance"
              },
              {
                id    = "unit"
                value = "locale"
              },
              {
                id    = "color"
                value = { mode = "fixed", fixedColor = "yellow" }
              }
            ]
          },
          {
            matcher = { id = "byName", options = "USDC" }
            properties = [
              {
                id    = "custom.axisPlacement"
                value = "right"
              },
              {
                id    = "custom.axisLabel"
                value = "Stablecoin Balance"
              },
              {
                id    = "unit"
                value = "locale"
              },
              {
                id    = "color"
                value = { mode = "fixed", fixedColor = "blue" }
              }
            ]
          },
          {
            matcher = { id = "byName", options = "USDT" }
            properties = [
              {
                id    = "custom.axisPlacement"
                value = "right"
              },
              {
                id    = "custom.axisLabel"
                value = "Stablecoin Balance"
              },
              {
                id    = "unit"
                value = "locale"
              },
              {
                id    = "color"
                value = { mode = "fixed", fixedColor = "green" }
              }
            ]
          },
          {
            matcher = { id = "byName", options = "axlUSDC" }
            properties = [
              {
                id    = "custom.axisPlacement"
                value = "right"
              },
              {
                id    = "custom.axisLabel"
                value = "Stablecoin Balance"
              },
              {
                id    = "unit"
                value = "locale"
              },
              {
                id    = "color"
                value = { mode = "fixed", fixedColor = "orange" }
              }
            ]
          }
        ]
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
      targets = [
        {
          expr         = "CELOToken_balanceOf{chain=\"celo\", owner=\"Reserve\"}"
          legendFormat = "CELO"
          refId        = "CELO"
          yAxis        = 1
        },
        {
          expr         = "USDC_balanceOf{chain=\"celo\", owner=\"Reserve\"}"
          legendFormat = "USDC"
          refId        = "USDC"
          yAxis        = 2
        },
        {
          expr         = "USDT_balanceOf{chain=\"celo\", owner=\"Reserve\"}"
          legendFormat = "USDT"
          refId        = "USDT"
          yAxis        = 2
        },
        {
          expr         = "axlUSDC_balanceOf{chain=\"celo\", owner=\"Reserve\"}"
          legendFormat = "axlUSDC"
          refId        = "axlUSDC"
          yAxis        = 2
        }
      ]
    })
  ]
}
