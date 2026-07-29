# NOTE: Port does not support `required_approval` on automation-triggered
# actions ("Automation with approval is not supported") - approval gates only
# work on self-service actions. So the "notify" and "human gate + remediate"
# stages are split into two separate port_action resources, matching Port's
# real automation/action model: automations react automatically (no gate),
# self-service actions can require approval before they execute.

# Stage: Notify. Fires automatically when a diagnostic_run is updated to
# Critical, posting to the on-call webhook (e.g. Slack) so a human knows to
# review and run the remediation action below.
resource "port_action" "notify_critical_diagnostic" {
  identifier  = var.notify_automation_identifier
  title       = var.notify_title
  icon        = var.automation_icon
  description = "Notifies the on-call channel when a diagnostic_run is reported Critical, so a human can review and trigger remediation."
  publish     = var.publish

  automation_trigger = {
    entity_updated_event = {
      blueprint_identifier = var.diagnostic_run_blueprint_identifier
    }
    jq_condition = {
      combinator = "and"
      expressions = [
        ".diff.after.properties.health_status == \"${var.trigger_health_status}\"",
        ".diff.after.properties.remediation_status != \"completed\" and .diff.after.properties.remediation_status != \"in_progress\" and .diff.after.properties.remediation_status != \"pending_approval\""
      ]
    }
  }

  webhook_method = {
    url    = var.approval_notification_url
    method = "POST"
    headers = {
      "Content-Type" = "application/json"
    }
    body = jsonencode({
      text = "Critical diagnostic run detected: {{ .diff.after.title }} (service: {{ .diff.after.relations.service }}). Review findings and run \"${var.automation_title}\" on the diagnostic_run entity to dispatch remediation."
    })
  }
}

# Stage: Human gate + Remediate. A human-triggered, approval-gated DAY-2
# action on an existing diagnostic_run entity. Once approved, it invokes the
# remediation webhook and expects the callee to write remediation_status,
# remediation_plan, and remediated_at back onto the entity (verify + close).
resource "port_action" "remediate_diagnostic_run" {
  identifier  = var.automation_identifier
  title       = var.automation_title
  icon        = var.automation_icon
  description = var.automation_description
  publish     = var.publish

  required_approval = var.require_approval

  self_service_trigger = {
    operation                  = "DAY-2"
    blueprint_identifier       = var.diagnostic_run_blueprint_identifier
    action_card_button_text    = "Remediate"
    execute_action_button_text = "Remediate"
  }

  webhook_method = {
    url    = var.remediation_agent_url
    method = "POST"
    headers = {
      "Content-Type" = "application/json"
    }
    body = jsonencode({
      prompt = "diagnostic_run {{ .entity.identifier }} for service {{ .entity.relations.service }} was reported health_status={{ .entity.properties.health_status }}. Findings: {{ .entity.properties.findings_summary }}. Propose a remediation (rollback, restart, scale, or open a PR), then execute it. Update the diagnostic_run entity's remediation_status (in_progress -> completed or failed), remediation_plan, and remediated_at once done."
      labels = {
        source       = "diagnostic_remediation"
        trigger_type = "self_service_approved"
      }
    })
  }
}
