variable "notify_automation_identifier" {
  description = "Identifier for the notify automation (fires automatically, no approval gate)"
  type        = string
  default     = "diagnostic_run_notify_critical"
}

variable "notify_title" {
  description = "Title for the notify automation"
  type        = string
  default     = "Notify Critical Diagnostic Run"
}

variable "automation_identifier" {
  description = "Identifier for the human-gated remediation self-service action"
  type        = string
  default     = "diagnostic_run_remediate_critical"
}

variable "automation_title" {
  description = "Title for the human-gated remediation self-service action"
  type        = string
  default     = "Remediate Critical Diagnostic Run"
}

variable "automation_description" {
  description = "Description for the remediation automation"
  type        = string
  default     = "Gates a remediation dispatch behind human approval when a diagnostic_run is reported Critical, and notifies the on-call channel."
}

variable "automation_icon" {
  description = "Icon for the remediation automation"
  type        = string
  default     = "AI"
}

variable "diagnostic_run_blueprint_identifier" {
  description = "Identifier of the diagnostic_run blueprint whose updates trigger this remediation"
  type        = string
  default     = "diagnostic_run"
}

variable "trigger_health_status" {
  description = "health_status value on diagnostic_run that should trigger remediation (e.g. Critical)"
  type        = string
  default     = "Critical"
}

variable "require_approval" {
  description = "Whether a human must approve the remediation before it executes (the human gate)"
  type        = bool
  default     = true
}

variable "publish" {
  description = "Whether to publish the remediation automation"
  type        = bool
  default     = true
}

variable "approval_notification_url" {
  description = "Webhook URL (e.g. Slack incoming webhook) notified when the remediation enters the human approval gate"
  type        = string
}

variable "remediation_agent_url" {
  description = "Webhook URL invoked to dispatch the remediation once approved (e.g. an AI remediation agent, GitHub Action dispatcher, or rollback endpoint)"
  type        = string
}
