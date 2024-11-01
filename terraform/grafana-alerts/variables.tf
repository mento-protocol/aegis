# For variables whose values are passed in from the either the root module or a terraform.tfvars file
variable "grafana_service_account_token" {
  description = "Grafana Service Account Token allowing Terraform to manage Grafana resources on the Mento Stack"
  type        = string
  sensitive   = true
}

variable "oracle_relayers_folder" {
  description = "The grafana folder in which to create the oracle relayer alerts"
  type = object({
    uid = string
  })
}

variable "reserve_folder" {
  description = "The Reserve folder in which to create the Reserve balance alerts"
  type = object({
    uid = string
  })
}

variable "trading_modes_folder" {
  description = "The Trading Modes folder in which to create the Trading Mode alerts"
  type = object({
    uid = string
  })
}

variable "discord_alerts_webhook_url_staging" {
  description = "Webhook URL for the Discord channel where alerts for staging oracle relayers are sent"
  type        = string
  sensitive   = true
}

variable "discord_alerts_webhook_url_prod" {
  description = "Webhook URL for the Discord channel where alerts for prod oracle relayers are sent"
  type        = string
  sensitive   = true
}

variable "discord_alerts_webhook_url_reserve" {
  description = "Webhook URL for the Discord channel where alerts for reserve balances are sent"
  type        = string
  sensitive   = true
}

variable "discord_alerts_webhook_url_trading_modes_staging" {
  description = "Webhook URL for the Discord channel where trading mode alerts on staging are sent"
  type        = string
  sensitive   = true
}

variable "discord_alerts_webhook_url_trading_modes_prod" {
  description = "Webhook URL for the Discord channel where trading mode alerts on production are sent"
  type        = string
  sensitive   = true
}

variable "discord_alerts_webhook_url_catch_all" {
  description = "Catch-all Webhook URL for the Discord channel where alerts without a configured contact point are sent"
  type        = string
  sensitive   = true
}

variable "splunk_on_call_alerts_webhook_url" {
  description = "Webhook URL for triggering on-call alerts"
  type        = string
  sensitive   = true
}
