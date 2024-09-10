locals {
  chains                    = ["celo", "alfajores"]
  prometheus_datasource_uid = "grafanacloud-clabsmento-prom"

  common_panel_config = {
    datasource = {
      type = "prometheus"
      uid  = local.prometheus_datasource_uid
    }
    legend = {
      showLegend  = true
      displayMode = "list"
      placement   = "bottom"
    }
    tooltip = {
      mode = "single"
      sort = "none"
    }
  }

  state_timeline_config = {
    type = "state-timeline"
    options = {
      mergeValues = false
      showValue   = "never"
      alignValue  = "center"
      rowHeight   = 0.9
    }
    fieldConfig = {
      defaults = {
        custom = {
          lineWidth   = 0
          fillOpacity = 70
          spanNulls   = false
          insertNulls = false
        }
        color = {
          mode = "continuous-GrYlRd"
        }
      }
    }
  }

  report_rates_config = merge(local.state_timeline_config, {
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
  })

  max_deviation_config = {
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
  }
  legacy_client_panels = flatten([
    for i, chain in local.chains : [
      merge(local.common_panel_config, local.report_rates_config, {
        id    = length(local.chains) + i + 4
        title = "Number of Oracle Report Rates [${chain}]"
        gridPos = {
          x = i * 12,
          y = 19,
          h = 8,
          w = 12
        }
        targets = [{
          expr         = "topk by(rateFeed) (1, numRates{chain=\"${chain}\"})"
          legendFormat = "{{rateFeed}}"
        }]
      }),
      merge(local.common_panel_config, local.max_deviation_config, {
        id    = 2 * length(local.chains) + i + 4
        title = "Oracle Max Deviation [${chain}]"
        gridPos = {
          x = i * 12,
          y = 27,
          h = 8,
          w = 12
        }
        targets = [{
          expr         = "deviation{chain=\"${chain}\"}"
          legendFormat = "{{rateFeed}}"
        }]
      })
    ]
  ])
  celo_balance_threshold = 10
  celo_balance_panels = [
    for i, chain in local.chains : merge(local.common_panel_config, {
      id          = length(local.chains) * 2 + 7 + i
      type        = "timeseries"
      title       = "CELO Balances of Relayer Signers [${chain}]"
      description = "CELO balance of relayer signers on ${chain}. Red line indicates danger threshold."
      gridPos = {
        x = i * 12,
        y = 36,
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
              { color = "red", value = local.celo_balance_threshold }
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
        expr         = "balanceOf{chain=\"${chain}\"}"
        legendFormat = "{{owner}}" # This line is updated to use the 'owner' label
        refId        = chain
      }]
    })
  ]
}

resource "grafana_dashboard" "aegis_oracle_relayers" {
  folder = grafana_folder.oracle_relayers_folder.uid
  config_json = jsonencode({
    title = "Aegis - Oracle Relayers"
    time  = { from = "now-30m", to = "now" }
    panels = concat(
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
            gridPos     = { x = i * 12, y = 1, h = 8, w = 24 / length(local.chains) }
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
              expr         = "getRateFeedTradingMode{chain=\"${chain}\"}"
              legendFormat = "{{rateFeed}}"
            }]
          })
        ]
      ]),
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
            gridPos     = { x = i * 12, y = 10, h = 4, w = 24 / length(local.chains) }
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
              expr         = "isOldestReportExpired{chain=\"${chain}\"}"
              legendFormat = "{{rateFeed}}"
            }]
          })
        ]
      ]),
      [
        {
          id      = length(local.chains) + 3
          type    = "row"
          title   = "Oracles - Legacy Clients"
          gridPos = { x = 0, y = 18, h = 1, w = 24 }
        }
      ],
      local.legacy_client_panels,
      [
        {
          id      = length(local.chains) * 2 + 6
          type    = "row"
          title   = "CELO Balance"
          gridPos = { x = 0, y = 35, h = 1, w = 24 }
        }
      ],
      local.celo_balance_panels
    )
    timepicker    = {}
    timezone      = "browser"
    schemaVersion = 36
    version       = 0
    refresh       = "30s"
  })
}
