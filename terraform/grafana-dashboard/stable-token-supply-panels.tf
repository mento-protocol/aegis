locals {
  stable_token_supply_panels = [
    {
      id      = local.stable_token_supply_id_start
      type    = "row"
      title   = "Stable Token Supply"
      gridPos = { x = 0, y = local.stable_token_supply_y_start, h = 1, w = 24 }
    },
    merge(local.common_panel_config, {
      id          = local.stable_token_supply_id_start + 1
      type        = "timeseries"
      title       = "Total Supply - All Stable Tokens [celo]"
      description = "Total outstanding supply of all Mento stable tokens. Shows the absolute number of tokens in circulation for each stablecoin."
      gridPos = {
        x = 0,
        y = local.stable_token_supply_y_start + 1,
        h = 16,
        w = 12
      }
      fieldConfig = {
        defaults = {
          custom = {
            drawStyle         = "line"
            lineInterpolation = "linear"
            fillOpacity       = 8
            gradientMode      = "opacity"
            spanNulls         = true
            showPoints        = "never"
            pointSize         = 5
            lineWidth         = 2
            stacking = {
              mode  = "none"
              group = "A"
            }
            axisPlacement = "auto"
            axisLabel     = "Token Supply (log scale)"
            axisColorMode = "text"
            axisSoftMin   = 1000
            axisGridShow  = false
            scaleDistribution = {
              type = "log"
              log  = 10
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
          decimals = 1
          min      = 0
        }
        overrides = [
          {
            matcher = { id = "byName", options = "cUSD" }
            properties = [
              {
                id    = "color"
                value = { mode = "fixed", fixedColor = "green" }
              },
              {
                id    = "decimals"
                value = 1
              }
            ]
          },
          {
            matcher = { id = "byName", options = "cEUR" }
            properties = [
              {
                id    = "color"
                value = { mode = "fixed", fixedColor = "blue" }
              },
              {
                id    = "decimals"
                value = 1
              }
            ]
          },
          {
            matcher = { id = "byName", options = "cREAL" }
            properties = [
              {
                id    = "color"
                value = { mode = "fixed", fixedColor = "yellow" }
              },
              {
                id    = "decimals"
                value = 1
              }
            ]
          },
          {
            matcher = { id = "byName", options = "cKES" }
            properties = [
              {
                id    = "color"
                value = { mode = "fixed", fixedColor = "orange" }
              },
              {
                id    = "decimals"
                value = 1
              }
            ]
          },
          {
            matcher = { id = "byName", options = "PUSO" }
            properties = [
              {
                id    = "color"
                value = { mode = "fixed", fixedColor = "purple" }
              },
              {
                id    = "decimals"
                value = 1
              }
            ]
          },
          {
            matcher = { id = "byName", options = "cCOP" }
            properties = [
              {
                id    = "color"
                value = { mode = "fixed", fixedColor = "red" }
              },
              {
                id    = "decimals"
                value = 1
              }
            ]
          }
        ]
      }
      options = {
        tooltip = { mode = "multi", sort = "desc" }
        legend = {
          showLegend  = true
          displayMode = "table"
          placement   = "bottom"
          calcs       = ["lastNotNull", "mean"]
          decimals    = 1
        }
      }
      pluginVersion = "10.0.0"
      transparent   = false
      targets = [
        {
          expr         = "cUSD_totalSupply{chain=\"celo\"}"
          legendFormat = "cUSD"
          refId        = "cUSD"
        },
        {
          expr         = "cEUR_totalSupply{chain=\"celo\"}"
          legendFormat = "cEUR"
          refId        = "cEUR"
        },
        {
          expr         = "cREAL_totalSupply{chain=\"celo\"}"
          legendFormat = "cREAL"
          refId        = "cREAL"
        },
        {
          expr         = "eXOF_totalSupply{chain=\"celo\"}"
          legendFormat = "eXOF"
          refId        = "eXOF"
        },
        {
          expr         = "cKES_totalSupply{chain=\"celo\"}"
          legendFormat = "cKES"
          refId        = "cKES"
        },
        {
          expr         = "PUSO_totalSupply{chain=\"celo\"}"
          legendFormat = "PUSO"
          refId        = "PUSO"
        },
        {
          expr         = "cCOP_totalSupply{chain=\"celo\"}"
          legendFormat = "cCOP"
          refId        = "cCOP"
        },
        {
          expr         = "cGHS_totalSupply{chain=\"celo\"}"
          legendFormat = "cGHS"
          refId        = "cGHS"
        },
        {
          expr         = "cGBP_totalSupply{chain=\"celo\"}"
          legendFormat = "cGBP"
          refId        = "cGBP"
        },
        {
          expr         = "cZAR_totalSupply{chain=\"celo\"}"
          legendFormat = "cZAR"
          refId        = "cZAR"
        },
        {
          expr         = "cCAD_totalSupply{chain=\"celo\"}"
          legendFormat = "cCAD"
          refId        = "cCAD"
        },
        {
          expr         = "cAUD_totalSupply{chain=\"celo\"}"
          legendFormat = "cAUD"
          refId        = "cAUD"
        },
        {
          expr         = "cCHF_totalSupply{chain=\"celo\"}"
          legendFormat = "cCHF"
          refId        = "cCHF"
        },
        {
          expr         = "cNGN_totalSupply{chain=\"celo\"}"
          legendFormat = "cNGN"
          refId        = "cNGN"
        },
        {
          expr         = "cJPY_totalSupply{chain=\"celo\"}"
          legendFormat = "cJPY"
          refId        = "cJPY"
        }
      ]
    }),
    # Second panel: Total Supply in USD (timeseries graph)
    merge(local.common_panel_config, {
      id          = local.stable_token_supply_id_start + 2
      type        = "timeseries"
      title       = "Total Supply - USD Value [celo]"
      description = "Individual USD value of each stable token over time. Each line shows the actual USD-equivalent supply for that token. Hover to see combined total."
      gridPos = {
        x = 12,
        y = local.stable_token_supply_y_start + 1,
        h = 16,
        w = 12
      }
      fieldConfig = {
        defaults = {
          custom = {
            drawStyle         = "line"
            lineInterpolation = "linear"
            fillOpacity       = 8
            gradientMode      = "opacity"
            spanNulls         = true
            showPoints        = "never"
            pointSize         = 5
            lineWidth         = 2
            stacking = {
              mode  = "none"
              group = "A"
            }
            axisPlacement    = "auto"
            axisLabel        = "USD Value (log scale)"
            axisColorMode    = "text"
            axisSoftMin      = 1000
            axisGridShow     = false
            axisCenteredZero = false
            scaleDistribution = {
              type = "log"
              log  = 10
            }
            hideFrom = {
              tooltip = false
              viz     = false
              legend  = false
            }
          }
          color    = { mode = "palette-classic" }
          mappings = []
          unit     = "currencyUSD"
          decimals = 2
          min      = 0
          max      = 50000000
        }
        overrides = [
          {
            matcher = { id = "byRegexp", options = ".*" }
            properties = [
              {
                id    = "decimals"
                value = 2
              }
            ]
          },
          {
            matcher = { id = "byName", options = "Total Supply (USD)" }
            properties = [
              {
                id    = "custom.lineWidth"
                value = 4
              },
              {
                id    = "color"
                value = { mode = "fixed", fixedColor = "white" }
              }
            ]
          }
        ]
      }
      options = {
        tooltip = { mode = "multi", sort = "desc" }
        legend = {
          showLegend  = true
          displayMode = "table"
          placement   = "bottom"
          calcs       = ["lastNotNull", "mean"]
          decimals    = 2
        }
      }
      pluginVersion = "10.0.0"
      transparent   = false
      transformations = [
        {
          id = "joinByField"
          options = {
            byField = "Time"
            mode    = "outer"
          }
        }
      ]
      targets = [
        {
          # cUSD is 1:1 with USD (no conversion needed)
          expr         = "cUSD_totalSupply{chain=\"celo\"}"
          legendFormat = "cUSD"
          refId        = "cUSD"
        },
        {
          # cEUR: Multiply cEUR supply by the dynamic EUR/USD exchange rate from SortedOracles
          expr         = "cEUR_totalSupply{chain=\"celo\"} * on() group_left SortedOracles_medianRate_rate{chain=\"celo\", token=\"EURUSD\"}"
          legendFormat = "cEUR"
          refId        = "cEUR"
        },
        {
          # cREAL: Multiply by dynamic BRL/USD rate
          expr         = "cREAL_totalSupply{chain=\"celo\"} * on() group_left SortedOracles_medianRate_rate{chain=\"celo\", token=\"BRLUSD\"}"
          legendFormat = "cREAL"
          refId        = "cREAL"
        },
        {
          # eXOF: Multiply by dynamic XOF/USD rate
          expr         = "eXOF_totalSupply{chain=\"celo\"} * on() group_left SortedOracles_medianRate_rate{chain=\"celo\", token=\"XOFUSD\"}"
          legendFormat = "eXOF"
          refId        = "eXOF"
        },
        {
          # cKES: Multiply by dynamic KES/USD rate
          expr         = "cKES_totalSupply{chain=\"celo\"} * on() group_left SortedOracles_medianRate_rate{chain=\"celo\", token=\"KESUSD\"}"
          legendFormat = "cKES"
          refId        = "cKES"
        },
        {
          # PUSO: Multiply by dynamic PHP/USD rate
          expr         = "PUSO_totalSupply{chain=\"celo\"} * on() group_left SortedOracles_medianRate_rate{chain=\"celo\", token=\"PHPUSD\"}"
          legendFormat = "PUSO"
          refId        = "PUSO"
        },
        {
          # cCOP: Multiply by dynamic COP/USD rate
          expr         = "cCOP_totalSupply{chain=\"celo\"} * on() group_left SortedOracles_medianRate_rate{chain=\"celo\", token=\"COPUSD\"}"
          legendFormat = "cCOP"
          refId        = "cCOP"
        },
        {
          # cGHS: Multiply by dynamic GHS/USD rate
          expr         = "cGHS_totalSupply{chain=\"celo\"} * on() group_left SortedOracles_medianRate_rate{chain=\"celo\", token=\"GHSUSD\"}"
          legendFormat = "cGHS"
          refId        = "cGHS"
        },
        {
          # cGBP: Multiply by dynamic GBP/USD rate
          expr         = "cGBP_totalSupply{chain=\"celo\"} * on() group_left SortedOracles_medianRate_rate{chain=\"celo\", token=\"GBPUSD\"}"
          legendFormat = "cGBP"
          refId        = "cGBP"
        },
        {
          # cZAR: Multiply by dynamic ZAR/USD rate
          expr         = "cZAR_totalSupply{chain=\"celo\"} * on() group_left SortedOracles_medianRate_rate{chain=\"celo\", token=\"ZARUSD\"}"
          legendFormat = "cZAR"
          refId        = "cZAR"
        },
        {
          # cCAD: Multiply by dynamic CAD/USD rate
          expr         = "cCAD_totalSupply{chain=\"celo\"} * on() group_left SortedOracles_medianRate_rate{chain=\"celo\", token=\"CADUSD\"}"
          legendFormat = "cCAD"
          refId        = "cCAD"
        },
        {
          # cAUD: Multiply by dynamic AUD/USD rate
          expr         = "cAUD_totalSupply{chain=\"celo\"} * on() group_left SortedOracles_medianRate_rate{chain=\"celo\", token=\"AUDUSD\"}"
          legendFormat = "cAUD"
          refId        = "cAUD"
        },
        {
          # cCHF: Multiply by dynamic CHF/USD rate
          expr         = "cCHF_totalSupply{chain=\"celo\"} * on() group_left SortedOracles_medianRate_rate{chain=\"celo\", token=\"CHFUSD\"}"
          legendFormat = "cCHF"
          refId        = "cCHF"
        },
        {
          # cNGN: Multiply by dynamic NGN/USD rate
          expr         = "cNGN_totalSupply{chain=\"celo\"} * on() group_left SortedOracles_medianRate_rate{chain=\"celo\", token=\"NGNUSD\"}"
          legendFormat = "cNGN"
          refId        = "cNGN"
        },
        {
          # cJPY: Multiply by dynamic JPY/USD rate
          expr         = "cJPY_totalSupply{chain=\"celo\"} * on() group_left SortedOracles_medianRate_rate{chain=\"celo\", token=\"JPYUSD\"}"
          legendFormat = "cJPY"
          refId        = "cJPY"
        },
        {
          # Combined total of all stable tokens in USD using dynamic exchange rates
          expr         = <<-EOT
            cUSD_totalSupply{chain="celo"} +
            (cEUR_totalSupply{chain="celo"} * on() group_left SortedOracles_medianRate_rate{chain="celo", token="EURUSD"}) +
            (cREAL_totalSupply{chain="celo"} * on() group_left SortedOracles_medianRate_rate{chain="celo", token="BRLUSD"}) +
            (eXOF_totalSupply{chain="celo"} * on() group_left SortedOracles_medianRate_rate{chain="celo", token="XOFUSD"}) +
            (cKES_totalSupply{chain="celo"} * on() group_left SortedOracles_medianRate_rate{chain="celo", token="KESUSD"}) +
            (PUSO_totalSupply{chain="celo"} * on() group_left SortedOracles_medianRate_rate{chain="celo", token="PHPUSD"}) +
            (cCOP_totalSupply{chain="celo"} * on() group_left SortedOracles_medianRate_rate{chain="celo", token="COPUSD"}) +
            (cGHS_totalSupply{chain="celo"} * on() group_left SortedOracles_medianRate_rate{chain="celo", token="GHSUSD"}) +
            (cGBP_totalSupply{chain="celo"} * on() group_left SortedOracles_medianRate_rate{chain="celo", token="GBPUSD"}) +
            (cZAR_totalSupply{chain="celo"} * on() group_left SortedOracles_medianRate_rate{chain="celo", token="ZARUSD"}) +
            (cCAD_totalSupply{chain="celo"} * on() group_left SortedOracles_medianRate_rate{chain="celo", token="CADUSD"}) +
            (cAUD_totalSupply{chain="celo"} * on() group_left SortedOracles_medianRate_rate{chain="celo", token="AUDUSD"}) +
            (cCHF_totalSupply{chain="celo"} * on() group_left SortedOracles_medianRate_rate{chain="celo", token="CHFUSD"}) +
            (cNGN_totalSupply{chain="celo"} * on() group_left SortedOracles_medianRate_rate{chain="celo", token="NGNUSD"}) +
            (cJPY_totalSupply{chain="celo"} * on() group_left SortedOracles_medianRate_rate{chain="celo", token="JPYUSD"})
          EOT
          legendFormat = "Total Supply (USD)"
          refId        = "Total"
        }
      ]
    })
  ]
}

