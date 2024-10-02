locals {
  legacy_client_panels = concat(
    [
      {
        id      = length(local.chains) + 3
        type    = "row"
        title   = "Oracles - Legacy Clients"
        gridPos = { x = 0, y = 18, h = 1, w = 24 }
      }
    ],
    flatten([
      for i, chain in local.chains : [
        merge(local.common_panel_config, local.state_timeline_config, {
          id    = length(local.chains) + i + 4
          title = "Number of Oracle Report Rates [${chain}]"
          gridPos = {
            x = i * 12,
            y = 19,
            h = 8,
            w = 12
          }
          targets = [{
            expr         = "topk by(rateFeed) (1, SortedOracles_numRates{chain=\"${chain}\"})"
            legendFormat = "{{rateFeed}}"
          }]
          options = merge(local.state_timeline_config.options, {
            showValue = "always"
          })
          fieldConfig = {
            defaults = merge(local.state_timeline_config.fieldConfig.defaults, {
              color = { mode = "continuous-RdYlGr" }
              max   = 10
              min   = 0
              thresholds = {
                mode = "absolute"
                steps = [
                  { color = "green", value = null },
                  { color = "red", value = 80 }
                ]
              }
            })
          }
        }),
        merge(local.common_panel_config, {
          id    = 2 * length(local.chains) + i + 4
          title = "Oracle Max Deviation [${chain}]"
          gridPos = {
            x = i * 12,
            y = 27,
            h = 8,
            w = 12
          }
          targets = [{
            expr         = "OracleHelper_deviation{chain=\"${chain}\"}"
            legendFormat = "{{rateFeed}}"
          }]
          type = "timeseries"
          options = {
            tooltip = { mode = "single" }
            legend = {
              showLegend  = true
              displayMode = "list"
              placement   = "bottom"
              calcs       = []
            }
          }
          fieldConfig = {
            defaults = {
              custom = {
                drawStyle         = "line"
                lineInterpolation = "linear"
                barAlignment      = 0
                lineWidth         = 1
                fillOpacity       = 0
                gradientMode      = "none"
                spanNulls         = false
                insertNulls       = false
                showPoints        = "auto"
                pointSize         = 5
                stacking = {
                  mode  = "none"
                  group = "A"
                }
                axisPlacement = "auto"
                axisLabel     = ""
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
                thresholdsStyle = {
                  mode = "off"
                }
              }
              color = { mode = "palette-classic" }
              min   = 0
              thresholds = {
                mode = "absolute"
                steps = [
                  { color = "green", value = null },
                  { color = "red", value = 80 }
                ]
              }
            }
          }
        })
      ]
    ])
  )



}
