locals {
  chains                    = ["celo", "alfajores"]
  prometheus_datasource_uid = "grafanacloud-clabsmento-prom"
}

resource "grafana_dashboard" "aegis_oracle_relayers" {
  folder = grafana_folder.oracle_relayers_folder.uid
  config_json = jsonencode({
    title = "Aegis - Oracle Relayers"
    time = {
      from = "now-30m"
      to   = "now"
    }
    panels = concat([
      {
        id    = 1
        type  = "row"
        title = "Trading Modes"
        gridPos = {
          x = 0
          y = 0
          h = 1
          w = 24
        }
        collapsed = false
      }
      ],
      flatten([
        for i, chain in local.chains : [
          {
            id          = i + 2
            type        = "state-timeline"
            title       = "Rate Feed Trading Mode [${chain}]"
            description = "Rate feed trading mode for each active rate feed. If != 0, it means the trading is halted for that pair."
            gridPos = {
              x = i * 12
              y = 1
              h = 8
              w = 24 / length(local.chains)
            }
            fieldConfig = {
              defaults = {
                custom = {
                  lineWidth   = 0
                  fillOpacity = 70
                  spanNulls   = false
                  insertNulls = false
                  hideFrom = {
                    tooltip = false
                    viz     = false
                    legend  = false
                  }
                }
                color = {
                  mode = "continuous-GrYlRd"
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
                decimals = 0
                max      = 3
                min      = 0
              }
              overrides = []
            }
            options = {
              mergeValues = false
              showValue   = "never"
              alignValue  = "center"
              rowHeight   = 0.9
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
            targets = [
              {
                datasource = {
                  type = "prometheus"
                  uid  = local.prometheus_datasource_uid
                }
                expr         = "getRateFeedTradingMode{chain=\"${chain}\"}"
                format       = "time_series"
                legendFormat = "{{rateFeed}}"
                range        = true
                refId        = "A"
              }
            ]
          }
        ]
      ]),
      [
        {
          id    = length(local.chains) + 2
          type  = "row"
          title = "Oracles - Chainlink Relayers"
          gridPos = {
            x = 0
            y = 9
            h = 1
            w = 24
          }
          collapsed = false
        }
      ],
      flatten([
        for i, chain in local.chains : [
          {
            id          = i + length(local.chains) + 3
            type        = "state-timeline"
            title       = "Rate Feed Freshness [${chain}]"
            description = "Shows if the oldest report in SortedOracles is expired for each relayed rate feed. 1 means expired, 0 means not expired."
            gridPos = {
              x = i * 12
              y = 10
              h = 4
              w = 24 / length(local.chains)
            }
            fieldConfig = {
              defaults = {
                custom = {
                  lineWidth   = 0
                  fillOpacity = 70
                  spanNulls   = false
                  insertNulls = false
                  hideFrom = {
                    tooltip = false
                    viz     = false
                    legend  = false
                  }
                }
                color = {
                  mode = "continuous-GrYlRd"
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
                      value = 1
                    }
                  ]
                }
                decimals = 0
                max      = 1
                min      = 0
              }
              overrides = []
            }
            options = {
              mergeValues = false
              showValue   = "never"
              alignValue  = "center"
              rowHeight   = 0.9
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
            targets = [
              {
                datasource = {
                  type = "prometheus"
                  uid  = local.prometheus_datasource_uid
                }
                expr         = "isOldestReportExpired{chain=\"${chain}\"}"
                format       = "time_series"
                legendFormat = "{{rateFeed}}"
                range        = true
                refId        = "A"
              }
            ]
          }
        ]
      ]),
      [
        {
          id    = length(local.chains) + 3
          type  = "row"
          title = "Oracles - Legacy Clients"
          gridPos = {
            x = 0
            y = 18
            h = 1
            w = 24
          }
          collapsed = false
        }
      ],
      flatten([
        for i, chain in local.chains : [
          {
            id    = i * 2 + length(local.chains) + 4
            title = "Number of Oracle Report Rates [${chain}]"
            type  = "state-timeline"
            gridPos = {
              x = 0
              y = i * 8 + 19
              h = 8
              w = 24 / length(local.chains)
            }
            targets = [
              {
                datasource = {
                  type = "prometheus"
                  uid  = local.prometheus_datasource_uid
                }
                expr         = "topk by(rateFeed) (1, numRates{chain=\"${chain}\"})"
                format       = "time_series"
                instant      = false
                legendFormat = "{{rateFeed}}"
                range        = true
                refId        = "A"
              }
            ]
            options = {
              alignValue  = "center"
              mergeValues = false,
              showValue   = "always"
              rowHeight   = 0.9
              legend = {
                showLegend  = true,
                displayMode = "list"
                placement   = "bottom"
              },
              tooltip = {
                mode = "single"
                sort = "none"
              }
            }
            fieldConfig = {
              defaults = {
                color = {
                  mode = "continuous-RdYlGr"
                }
                custom = {
                  fillOpacity = 70
                  hideFrom = {
                    legend  = false
                    tooltip = false
                    viz     = false
                  }
                  insertNulls = false
                  lineWidth   = 0
                  spanNulls   = false
                }
                mappings = []
                max      = 10
                min      = 0
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
          },
          {
            id    = i * 2 + length(local.chains) + 5
            type  = "timeseries"
            title = "Oracle Max Deviation [${chain}]"
            gridPos = {
              x = 12
              y = i * 8 + 19
              h = 8
              w = 24 / length(local.chains)
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
              overrides = []
            }
            options = {
              tooltip = {
                mode = "single"
                sort = "none"
              }
              legend = {
                showLegend  = true
                displayMode = "list"
                placement   = "bottom"
                calcs       = []
              }
            }
            targets = [
              {
                datasource = {
                  type = "prometheus"
                  uid  = local.prometheus_datasource_uid
                }
                expr         = "deviation{chain=\"${chain}\"}"
                instant      = false
                legendFormat = "{{rateFeed}}"
                range        = true
                refId        = "A"
              }
            ]
          }
        ]
    ]))
    timepicker    = {}
    timezone      = "browser"
    schemaVersion = 36
    version       = 0
    refresh       = "30s"
  })
}
