resource "grafana_folder" "aegis" {
  title = "Aegis"
}

resource "grafana_folder" "oracle_relayers" {
  title = "Oracle Relayers"
}

data "grafana_folder" "reserve" {
  title = "Reserve"
}
