# terraform-port-diagnostic-remediation

**Repository:** https://github.com/sce81/terraform-port-diagnostic-remediation

Closes the loop on the self-health diagnostic pipeline: when a `diagnostic_run` entity is updated with `health_status == Critical`, this module notifies the on-call channel automatically, then lets a human trigger an approval-gated remediation action.

This covers the **Notify**, **Human gate**, and **Remediate** stages of Port's self-healing pattern (detect → enrich → diagnose → record → **notify → gate → remediate**), chained after the `diagnostic_run` entity produced by [`terraform-port-diagnostic-workflow`](https://github.com/sce81/terraform-port-diagnostic-workflow) or [`terraform-port-diagnostic-automation`](https://github.com/sce81/terraform-port-diagnostic-automation).

**Why two resources:** Port's API rejects `required_approval` on automation-triggered actions (`"Automation with approval is not supported"`). Approval gates only work on self-service actions. So this module splits the stage into what Port actually supports:

| Self-healing concept | Resource | Trigger | Approval gate |
|---|---|---|---|
| Condition + Notify | `port_action.notify_critical_diagnostic` | `automation_trigger` (entity updated, JQ condition on `health_status`) | not supported/used — fires automatically |
| Human gate + Remediate | `port_action.remediate_diagnostic_run` | `self_service_trigger` (`DAY-2`, scoped to `diagnostic_run`) | `required_approval = true` |

The notify automation's message tells a human to go run the remediation action; the remediation action itself pauses for approval before its webhook fires.

## Resources Created

- `port_action.notify_critical_diagnostic` — automation that posts to a webhook (e.g. Slack) when a `diagnostic_run` turns Critical
- `port_action.remediate_diagnostic_run` — approval-gated, human-triggered `DAY-2` action on `diagnostic_run` entities that dispatches remediation

## Prerequisites

- Terraform >= 1.0
- Port Provider >= 2.22.0 (`port-labs/port-labs`)
- Port API credentials (client ID and secret)
- `diagnostic_run` blueprint must exist with `health_status` and `remediation_status` properties (see [`terraform-port-diagnostic-run-blueprint`](https://github.com/sce81/terraform-port-diagnostic-run-blueprint))
- A webhook endpoint for notifications (e.g. a Slack incoming webhook)
- A webhook endpoint that performs or dispatches the actual remediation (e.g. a remediation AI agent invoke URL, or a GitHub Actions dispatcher)

## Installing

```hcl
module "diagnostic_remediation" {
  source = "github.com/sce81/terraform-port-diagnostic-remediation?ref=1.0.2"

  approval_notification_url = var.slack_webhook_url
  remediation_agent_url     = var.remediation_agent_url
}
```

## Usage

```hcl
module "diagnostic_remediation" {
  source = "github.com/sce81/terraform-port-diagnostic-remediation?ref=1.0.2"

  diagnostic_run_blueprint_identifier = "diagnostic_run"
  trigger_health_status                = "Critical"
  require_approval                     = true
  approval_notification_url            = "https://hooks.slack.com/services/T000/B000/XXXX"
  remediation_agent_url                = "https://api.port.io/v1/agent/remediation_agent/invoke"
}
```

## How It Works

1. **Trigger + condition:** the notify automation's `jq_condition` fires only when `health_status == "Critical"` and `remediation_status` isn't already `completed`/`in_progress`/`pending_approval` — preventing re-notification on every subsequent update.
2. **Notify:** its `webhook_method` posts a message to the configured webhook (e.g. Slack) naming the entity and pointing the on-call human at the remediation action.
3. **Human gate:** the remediation action is a `DAY-2` self-service action scoped to `diagnostic_run` (`self_service_trigger.blueprint_identifier`), so it appears in that entity's actions menu. With `required_approval = true`, a human must explicitly trigger it and have the run approved before anything executes.
4. **Remediate + verify/close:** once approved, `webhook_method` invokes the remediation endpoint with the target entity's context, asking it to propose and execute a fix, then write `remediation_status`, `remediation_plan`, and `remediated_at` back onto the `diagnostic_run` entity.

Provider credentials are configured once in the root module's `provider` block and inherited automatically — child modules do not declare or accept `port_client_id`/`port_client_secret`.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `notify_automation_identifier` | Identifier for the notify automation | `string` | `"diagnostic_run_notify_critical"` | no |
| `notify_title` | Title of the notify automation | `string` | `"Notify Critical Diagnostic Run"` | no |
| `automation_identifier` | Identifier for the human-gated remediation action | `string` | `"diagnostic_run_remediate_critical"` | no |
| `automation_title` | Title of the human-gated remediation action | `string` | `"Remediate Critical Diagnostic Run"` | no |
| `automation_description` | Description of the remediation action | `string` | | no |
| `automation_icon` | Icon for both resources | `string` | `"AI"` | no |
| `diagnostic_run_blueprint_identifier` | Identifier of diagnostic_run blueprint | `string` | `"diagnostic_run"` | no |
| `trigger_health_status` | `health_status` value that triggers notification | `string` | `"Critical"` | no |
| `require_approval` | Whether human approval is required before remediation runs | `bool` | `true` | no |
| `publish` | Whether to publish both resources | `bool` | `true` | no |
| `approval_notification_url` | Webhook posted to when a Critical diagnostic_run is detected | `string` | | yes |
| `remediation_agent_url` | Webhook invoked to perform remediation once approved | `string` | | yes |

## Outputs

| Name | Description |
|------|-------------|
| `notify_id` | ID of the notify automation |
| `notify_identifier` | Identifier of the notify automation |
| `remediation_id` | ID of the human-gated remediation action |
| `remediation_identifier` | Identifier of the human-gated remediation action |
| `remediation_title` | Title of the human-gated remediation action |
