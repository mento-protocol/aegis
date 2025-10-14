locals {
  trading_limits_panels = [
    {
      id      = local.trading_limits_id_start
      type    = "row"
      title   = "Trading Limits"
      gridPos = { x = 0, y = local.trading_limits_y_start, h = 1, w = 24 }
    },
    merge(local.common_panel_config, {
      id          = local.trading_limits_id_start + 1
      type        = "timeseries"
      title       = "L0 Short-term Limit Utilization [celo]"
      description = "Percentage utilization of short-term (L0) trading limits. Shows how close each limit is to being hit. Red indicates 90%+ utilization (critical)."
      gridPos = {
        x = 0,
        y = local.trading_limits_y_start + 1,
        h = 12,
        w = 12
      }
      fieldConfig = {
        defaults = {
          custom = {
            drawStyle         = "line"
            lineInterpolation = "stepAfter"
            fillOpacity       = 20
            gradientMode      = "scheme"
            spanNulls         = false
            showPoints        = "never"
            pointSize         = 5
            lineWidth         = 2
            stacking = {
              mode  = "none"
              group = "A"
            }
            axisPlacement = "auto"
            axisLabel     = "Utilization %"
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
              mode = "line+area"
            }
          }
          color    = { mode = "thresholds" }
          mappings = []
          thresholds = {
            mode = "absolute"
            steps = [
              { color = "green", value = null },
              { color = "yellow", value = 50 },
              { color = "orange", value = 75 },
              { color = "red", value = 90 }
            ]
          }
          unit = "percent"
          max  = 100
          # min is not set to allow dynamic scaling - will show 0-100% normally,
          # but will auto-expand to show negative values if they occur
        }
      }
      options = {
        tooltip = { mode = "multi", sort = "desc" }
        legend = {
          showLegend  = true
          displayMode = "table"
          placement   = "bottom"
          calcs       = ["lastNotNull", "max", "min"]
          sortBy      = "max"
          sortDesc    = true
        }
      }
      targets = [{
        expr         = <<-EOT
          (
            abs(Broker_tradingLimitsState_netflow0{chain="celo"})
            /
            clamp_min(abs(Broker_tradingLimitsConfig_limit0{chain="celo"}), 1)
          ) * 100
        EOT
        legendFormat = "{{limitId}}"
        refId        = "L0_utilization"
      }]
    }),
    merge(local.common_panel_config, {
      id          = local.trading_limits_id_start + 2
      type        = "timeseries"
      title       = "L1 Medium-term Limit Utilization [celo]"
      description = "Percentage utilization of medium-term (L1) trading limits. Shows how close each limit is to being hit. Red indicates 90%+ utilization (critical)."
      gridPos = {
        x = 12,
        y = local.trading_limits_y_start + 1,
        h = 12,
        w = 12
      }
      fieldConfig = {
        defaults = {
          custom = {
            drawStyle         = "line"
            lineInterpolation = "stepAfter"
            fillOpacity       = 20
            gradientMode      = "scheme"
            spanNulls         = false
            showPoints        = "never"
            pointSize         = 5
            lineWidth         = 2
            stacking = {
              mode  = "none"
              group = "A"
            }
            axisPlacement = "auto"
            axisLabel     = "Utilization %"
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
              mode = "line+area"
            }
          }
          color    = { mode = "thresholds" }
          mappings = []
          thresholds = {
            mode = "absolute"
            steps = [
              { color = "green", value = null },
              { color = "yellow", value = 50 },
              { color = "orange", value = 75 },
              { color = "red", value = 90 }
            ]
          }
          unit = "percent"
          max  = 100
          # min is not set to allow dynamic scaling - will show 0-100% normally,
          # but will auto-expand to show negative values if they occur
        }
      }
      options = {
        tooltip = { mode = "multi", sort = "desc" }
        legend = {
          showLegend  = true
          displayMode = "table"
          placement   = "bottom"
          calcs       = ["lastNotNull", "max", "min"]
          sortBy      = "max"
          sortDesc    = true
        }
      }
      targets = [{
        expr         = <<-EOT
          (
            abs(Broker_tradingLimitsState_netflow1{chain="celo"})
            /
            clamp_min(abs(Broker_tradingLimitsConfig_limit1{chain="celo"}), 1)
          ) * 100
        EOT
        legendFormat = "{{limitId}}"
        refId        = "L1_utilization"
      }]
    }),
    merge(local.common_panel_config, {
      id          = local.trading_limits_id_start + 3
      type        = "timeseries"
      title       = "Global Lifetime Limit Utilization [celo]"
      description = "Percentage utilization of lifetime (Global) trading limits. Shows how close each limit is to being hit. Red indicates 90%+ utilization (critical)."
      gridPos = {
        x = 0,
        y = local.trading_limits_y_start + 13,
        h = 12,
        w = 24
      }
      fieldConfig = {
        defaults = {
          custom = {
            drawStyle         = "line"
            lineInterpolation = "stepAfter"
            fillOpacity       = 20
            gradientMode      = "scheme"
            spanNulls         = false
            showPoints        = "never"
            pointSize         = 5
            lineWidth         = 2
            stacking = {
              mode  = "none"
              group = "A"
            }
            axisPlacement = "auto"
            axisLabel     = "Utilization %"
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
              mode = "line+area"
            }
          }
          color    = { mode = "thresholds" }
          mappings = []
          thresholds = {
            mode = "absolute"
            steps = [
              { color = "green", value = null },
              { color = "yellow", value = 50 },
              { color = "orange", value = 75 },
              { color = "red", value = 90 }
            ]
          }
          unit = "percent"
          max  = 100
          # min is not set to allow dynamic scaling - will show 0-100% normally,
          # but will auto-expand to show negative values if they occur
        }
      }
      options = {
        tooltip = { mode = "multi", sort = "desc" }
        legend = {
          showLegend  = true
          displayMode = "table"
          placement   = "bottom"
          calcs       = ["lastNotNull", "max", "min"]
          sortBy      = "max"
          sortDesc    = true
        }
      }
      targets = [{
        expr         = <<-EOT
          (
            abs(Broker_tradingLimitsState_netflowGlobal{chain="celo"})
            /
            clamp_min(abs(Broker_tradingLimitsConfig_limitGlobal{chain="celo"}), 1)
          ) * 100
        EOT
        legendFormat = "{{limitId}}"
        refId        = "Global_utilization"
      }]
    })
  ]
}
