#!/usr/bin/env bash
# Demonstrates Privileged Identity Management via direct ARM REST calls
# (Microsoft.Authorization/roleEligibilityScheduleRequests + roleAssignmentScheduleRequests,
# api-version 2020-10-01) - there is no dedicated 'az pim' CLI, so PIM has to be driven
# through the underlying API, same as it is in production automation.
#
# Flow: make the signed-in user ELIGIBLE for Reader (not active) -> self-activate for 1 hour
# -> show the assignment is active -> (left to expire naturally, or deactivate manually).
set -euo pipefail
cd "$(dirname "$0")"
source lib/common.sh

RESOURCE_GROUP="${RESOURCE_GROUP:-rg-iam-security-baseline}"
READER_ROLE_ID="acdd72a7-3385-48ef-bd42-f606fba81ae7"   # built-in Reader, same GUID in every tenant

require_cli

SUBID=$(az account show --query id -o tsv)
MYOID=$(az ad signed-in-user show --query id -o tsv)
SCOPE="/subscriptions/${SUBID}/resourceGroups/${RESOURCE_GROUP}"

info "Scope: $SCOPE"
info "Principal: $MYOID"
confirm "Make Reader ELIGIBLE then self-activate it for 1 hour at this scope?" || { warn "Aborted."; exit 1; }

# --- 1. Make Reader eligible (not active) ---------------------------------
ELIGIBILITY_REQ_ID=$(uuidgen 2>/dev/null || python3 -c "import uuid; print(uuid.uuid4())")
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)

info "Creating eligibility schedule request $ELIGIBILITY_REQ_ID"
az rest --method put \
  --url "https://management.azure.com${SCOPE}/providers/Microsoft.Authorization/roleEligibilityScheduleRequests/${ELIGIBILITY_REQ_ID}?api-version=2020-10-01" \
  --body "{
    \"properties\": {
      \"principalId\": \"${MYOID}\",
      \"roleDefinitionId\": \"/subscriptions/${SUBID}/providers/Microsoft.Authorization/roleDefinitions/${READER_ROLE_ID}\",
      \"requestType\": \"AdminAssign\",
      \"scheduleInfo\": {
        \"startDateTime\": \"${NOW}\",
        \"expiration\": { \"type\": \"AfterDuration\", \"duration\": \"P30D\" }
      },
      \"justification\": \"IAM baseline - eligible Reader (not active)\"
    }
  }" >/dev/null

ok "Eligible (no standing access yet). Confirming no active assignment exists:"
az role assignment list --resource-group "$RESOURCE_GROUP" --include-inherited -o table

# --- 2. Self-activate for 1 hour ------------------------------------------
ACTIVATION_REQ_ID=$(uuidgen 2>/dev/null || python3 -c "import uuid; print(uuid.uuid4())")
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)

info "Self-activating for 1 hour (request $ACTIVATION_REQ_ID)"
az rest --method put \
  --url "https://management.azure.com${SCOPE}/providers/Microsoft.Authorization/roleAssignmentScheduleRequests/${ACTIVATION_REQ_ID}?api-version=2020-10-01" \
  --body "{
    \"properties\": {
      \"principalId\": \"${MYOID}\",
      \"roleDefinitionId\": \"/subscriptions/${SUBID}/providers/Microsoft.Authorization/roleDefinitions/${READER_ROLE_ID}\",
      \"requestType\": \"SelfActivate\",
      \"scheduleInfo\": {
        \"startDateTime\": \"${NOW}\",
        \"expiration\": { \"type\": \"AfterDuration\", \"duration\": \"PT1H\" }
      },
      \"justification\": \"Activating Reader for IAM baseline demo\"
    }
  }" >/dev/null

ok "Active for 1 hour. Confirming the assignment now shows up:"
az role assignment list --resource-group "$RESOURCE_GROUP" --include-inherited -o table

warn "This activation expires automatically in 1 hour - no cleanup action required."
info "Production variant: enable 'Require approval to activate' + a quarterly access review in PIM (Portal: Identity governance > Access reviews). See docs/THREAT-MODEL.md."
