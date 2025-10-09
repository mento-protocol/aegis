resource "grafana_rule_group" "aegis_service_alerts" {
  name             = "Aegis service alerts"
  folder_uid       = var.aegis_folder.uid
  interval_seconds = 60

  rule {
    name      = "Number of failed rpc calls"
    condition = "B"

    data {
      ref_id = "errorCount"

      relative_time_range {
        from = 300
        to   = 0
      }

      datasource_uid = "grafanacloud-prom"
      model          = "{\"disableTextWrap\":false,\"editorMode\":\"code\",\"expr\":\"sum(delta(view_call_query_duration_count{chain=\\\"celo\\\", status=\\\"error\\\"}[5m]))\",\"fullMetaSearch\":false,\"includeNullMetadata\":true,\"instant\":true,\"intervalMs\":600000,\"legendFormat\":\"__auto\",\"maxDataPoints\":43200,\"range\":false,\"refId\":\"errorCount\",\"useBackend\":false}"
    }
    data {
      ref_id = "B"

      relative_time_range {
        from = 300
        to   = 0
      }

      datasource_uid = "__expr__"
      model          = "{\"conditions\":[{\"evaluator\":{\"params\":[10,0],\"type\":\"gt\"},\"operator\":{\"type\":\"and\"},\"query\":{\"params\":[]},\"reducer\":{\"params\":[],\"type\":\"avg\"},\"type\":\"query\"}],\"datasource\":{\"name\":\"Expression\",\"type\":\"__expr__\",\"uid\":\"__expr__\"},\"expression\":\"errorCount\",\"intervalMs\":1000,\"maxDataPoints\":43200,\"refId\":\"B\",\"type\":\"threshold\"}"
    }

    no_data_state  = "OK"
    exec_err_state = "Error"
    for            = "5m"
    annotations = {
      description = "Tracks the number of error responses from our monitoring service."
      summary     = "More than 10 errors were detected in a 5-minute timespan."
    }
    labels = {
      service  = "aegis"
      severity = "page"
    }
    is_paused = false
  }
  rule {
    name      = "Aegis does not report new data"
    condition = "C"

    data {
      ref_id = "A"

      relative_time_range {
        from = 600
        to   = 0
      }

      datasource_uid = "grafanacloud-prom"
      model          = "{\"editorMode\":\"code\",\"expr\":\"time() - lastUpdatedAt\",\"instant\":true,\"intervalMs\":1000,\"legendFormat\":\"__auto\",\"maxDataPoints\":43200,\"range\":false,\"refId\":\"A\"}"
    }
    data {
      ref_id = "C"

      relative_time_range {
        from = 600
        to   = 0
      }

      datasource_uid = "__expr__"
      model          = "{\"conditions\":[{\"evaluator\":{\"params\":[300],\"type\":\"gt\"},\"operator\":{\"type\":\"and\"},\"query\":{\"params\":[\"C\"]},\"reducer\":{\"params\":[],\"type\":\"last\"},\"type\":\"query\"}],\"datasource\":{\"type\":\"__expr__\",\"uid\":\"__expr__\"},\"expression\":\"A\",\"intervalMs\":1000,\"maxDataPoints\":43200,\"refId\":\"C\",\"type\":\"threshold\"}"
    }

    no_data_state  = "NoData"
    exec_err_state = "Error"
    for            = "5m"
    annotations = {
      description = "Triggers if the time between the last aegis update and now is bigger than 5 mins."
      summary     = "Tracks the time passed since the last update from aegis. \n\nThis alert triggering means aegis did not push any new data for > 5mins.\n\nIt is highly possible that the aegis is down."
    }
    labels = {
      service  = "aegis"
      severity = "page"
    }
    is_paused = false
  }
}
