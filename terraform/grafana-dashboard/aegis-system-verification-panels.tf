locals {
  aegis_system_verification_row = {
    id      = 3 * length(local.chains) + 4
    type    = "row"
    title   = "Aegis System Verification"
    gridPos = { x = 0, y = 35, h = 1, w = 24 }
  }

  rpc_query_heatmap_panel = {
    id             = 3 * length(local.chains) + 5
    type           = "heatmap"
    title          = "RPC Query Heatmap"
    gridPos        = { x = 0, y = 36, h = 8, w = 12 }
    datasource_uid = "grafanacloud-prom"
    maxDataPoints  = 100
    targets = [
      {
        datasource_uid = "grafanacloud-prom"
        expr           = "sum by(le) (increase(view_call_query_duration_bucket[$__interval]))"
        format         = "heatmap"
        refId          = "A"
      }
    ]
    options = {
      yAxis = {
        axisLabel = "Query execution time"
      }
    }
  }

  failed_rpc_calls_panel = {
    id      = 3 * length(local.chains) + 6
    type    = "timeseries"
    title   = "Number of failed RPC calls"
    gridPos = { x = 12, y = 36, h = 8, w = 12, }
    fieldConfig = {
      defaults = {
        custom = {
          drawStyle         = "line"
          lineInterpolation = "linear"
          barAlignment      = 0
          barWidthFactor    = 0.6
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
          axisPlacement  = "auto"
          axisLabel      = ""
          axisColorMode  = "text"
          axisBorderShow = false
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
        color = {
          mode = "palette-classic"
        }
        mappings = []
        thresholds = {
          mode = "absolute"
          steps = [
            {
              color = "green"
              value = null
            },
            {
              color = "red"
              value = 80
            }
          ]
        }
      }
    }
    targets = [
      {
        datasource_uid      = "grafanacloud-prom"
        expr                = "delta(view_call_query_duration_count{status=\"error\"}[5m])"
        fullMetaSearch      = false
        includeNullMetadata = true
        instant             = false
        legendFormat        = "{{functionName}} {{chain}} {{errorCount}}"
        range               = true
        refId               = "A"
        useBackend          = false
      }
    ]
    datasource_uid = "grafanacloud-prom"
    options = {
      tooltip = {
        mode = "single"
        sort = "none"
      }
      legend = {
        showLegend  = true
        displayMode = "list"
        placement   = "bottom"
      }
    }
  }

  time_since_last_update_panel = {
    id          = 3 * length(local.chains) + 7
    type        = "timeseries"
    title       = "Time since last update"
    description = "This is a health check for the Aegis exporter. If it starts to go up, it may mean that Aegis is down."
    gridPos     = { x = 0, y = 44, h = 8, w = 12 }
    fieldConfig = {
      defaults = {
        custom = {
          drawStyle         = "line"
          lineInterpolation = "linear"
          barAlignment      = 0
          barWidthFactor    = 0.6
          lineWidth         = 1
          fillOpacity       = 0
          gradientMode      = "none"
          spanNulls         = false
          insertNulls       = false
          showPoints        = "auto"
          pointSize         = 8
          stacking = {
            mode  = "none"
            group = "A"
          }
          axisPlacement  = "auto"
          axisLabel      = ""
          axisColorMode  = "text"
          axisBorderShow = false
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
            mode = "line"
          }
          axisSoftMax = 60
          lineStyle = {
            fill = "solid"
          }
        }
        color = {
          mode       = "fixed"
          fixedColor = "orange"
        }
        mappings = []
        thresholds = {
          mode = "absolute"
          steps = [
            {
              color = "green"
              value = null
            }
          ]
        }
        unit = "s"
      }
    }
    targets = [
      {
        datasource_uid      = "grafanacloud-prom"
        disableTextWrap     = false
        editorMode          = "builder"
        exemplar            = false
        expr                = "time() - lastUpdatedAt"
        format              = "time_series"
        fullMetaSearch      = false
        includeNullMetadata = true
        instant             = true
        legendFormat        = "__auto"
        range               = true
        refId               = "A"
        useBackend          = false
      }
    ]
    datasource_uid = "grafanacloud-prom"
    options = {
      tooltip = {
        mode = "single"
        sort = "none"
      }
      legend = {
        showLegend  = false
        displayMode = "list"
        placement   = "bottom"
        calcs       = []
      }
    }
  }

  # Append the new row and panels to the existing panels
  aegis_system_verification_panels = concat(
    local.legacy_client_panels,
    [
      local.aegis_system_verification_row,
      local.rpc_query_heatmap_panel,
      local.failed_rpc_calls_panel,
      local.time_since_last_update_panel
    ]
  )
}
