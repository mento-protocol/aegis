variable "grafana_service_account_token" {
  description = "Grafana Service Account Token allowing Terraform to manage Grafana resources on the Mento Stack"
  type        = string
  sensitive   = true
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
