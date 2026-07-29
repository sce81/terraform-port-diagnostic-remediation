output "notify_id" {
  description = "ID of the notify automation"
  value       = port_action.notify_critical_diagnostic.id
}

output "notify_identifier" {
  description = "Identifier of the notify automation"
  value       = port_action.notify_critical_diagnostic.identifier
}

output "remediation_id" {
  description = "ID of the human-gated remediation action"
  value       = port_action.remediate_diagnostic_run.id
}

output "remediation_identifier" {
  description = "Identifier of the human-gated remediation action"
  value       = port_action.remediate_diagnostic_run.identifier
}

output "remediation_title" {
  description = "Title of the human-gated remediation action"
  value       = port_action.remediate_diagnostic_run.title
}
