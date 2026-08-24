#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 WORK_ITEM_ID output/playwright/SCREENSHOT.png [COMMENT]" >&2
  exit 2
}

[[ $# -ge 2 && $# -le 3 ]] || usage

work_item_id="$1"
screenshot="$2"
comment="${3:-FastFood defect reproduction evidence}"
organization="https://dev.azure.com/4tecture-demo"
project="k8sDemo"
azure_devops_resource="499b84ac-1321-427f-aa17-267ca6975798"

[[ "$work_item_id" =~ ^[0-9]+$ ]] || { echo "Work item ID must be numeric." >&2; exit 2; }
command -v az >/dev/null 2>&1 || { echo "Azure CLI is required." >&2; exit 2; }
command -v curl >/dev/null 2>&1 || { echo "curl is required." >&2; exit 2; }
command -v jq >/dev/null 2>&1 || { echo "jq is required." >&2; exit 2; }
command -v file >/dev/null 2>&1 || { echo "file is required." >&2; exit 2; }

repository_root="$(git rev-parse --show-toplevel)"
evidence_root="$(cd "$repository_root/output/playwright" && pwd -P)"
[[ -f "$screenshot" ]] || { echo "Screenshot does not exist: $screenshot" >&2; exit 2; }
screenshot_path="$(cd "$(dirname "$screenshot")" && pwd -P)/$(basename "$screenshot")"

case "$screenshot_path" in
  "$evidence_root"/*.png) ;;
  *) echo "Screenshot must be a PNG under $evidence_root." >&2; exit 2 ;;
esac

[[ "$(file --brief --mime-type "$screenshot_path")" == "image/png" ]] || {
  echo "Screenshot content is not image/png." >&2
  exit 2
}

temporary_directory="$(mktemp -d)"
trap 'rm -rf "$temporary_directory"' EXIT
auth_config="$temporary_directory/curl-auth.conf"
upload_response="$temporary_directory/upload.json"
patch_body="$temporary_directory/patch.json"
patch_response="$temporary_directory/work-item.json"
work_item_before="$temporary_directory/work-item-before.json"

az boards work-item show \
  --organization "$organization" \
  --id "$work_item_id" \
  --expand fields \
  --output json > "$work_item_before"

existing_repro_steps="$(jq -r '.fields["Microsoft.VSTS.TCM.ReproSteps"] // ""' "$work_item_before")"

access_token="$(az account get-access-token \
  --resource "$azure_devops_resource" \
  --query accessToken \
  --output tsv)"
[[ -n "$access_token" ]] || { echo "Could not obtain an Azure DevOps access token." >&2; exit 1; }
chmod 700 "$temporary_directory"
printf 'header = "Authorization: Bearer %s"\n' "$access_token" > "$auth_config"
chmod 600 "$auth_config"
unset access_token

encoded_project="$(jq -rn --arg value "$project" '$value|@uri')"
encoded_filename="$(jq -rn --arg value "$(basename "$screenshot_path")" '$value|@uri')"
upload_endpoint="${organization}/${encoded_project}/_apis/wit/attachments?fileName=${encoded_filename}&api-version=7.1"

upload_status="$(curl --silent --show-error \
  --config "$auth_config" \
  --request POST \
  --header "Content-Type: application/octet-stream" \
  --data-binary "@$screenshot_path" \
  --output "$upload_response" \
  --write-out '%{http_code}' \
  "$upload_endpoint")"

[[ "$upload_status" =~ ^2 ]] || {
  echo "Attachment upload failed with HTTP $upload_status." >&2
  jq -r '.message? // empty' "$upload_response" >&2 || true
  exit 1
}

attachment_url="$(jq -er '.url' "$upload_response")"
embedded_repro_steps="${existing_repro_steps}<p><strong>Screenshot evidence</strong></p><p><img src=\"${attachment_url}\" alt=\"Reproduction screenshot\" /></p>"
jq -n \
  --arg url "$attachment_url" \
  --arg comment "$comment" \
  --arg reproSteps "$embedded_repro_steps" \
  '[
    {"op":"add","path":"/relations/-","value":{"rel":"AttachedFile","url":$url,"attributes":{"comment":$comment}}},
    {"op":"add","path":"/fields/Microsoft.VSTS.TCM.ReproSteps","value":$reproSteps}
  ]' \
  > "$patch_body"

patch_endpoint="${organization}/${encoded_project}/_apis/wit/workitems/${work_item_id}?api-version=7.1"
patch_status="$(curl --silent --show-error \
  --config "$auth_config" \
  --request PATCH \
  --header "Content-Type: application/json-patch+json" \
  --data-binary "@$patch_body" \
  --output "$patch_response" \
  --write-out '%{http_code}' \
  "$patch_endpoint")"

[[ "$patch_status" =~ ^2 ]] || {
  echo "Attachment was uploaded but linking and embedding it in work item $work_item_id failed with HTTP $patch_status." >&2
  jq -r '.message? // empty' "$patch_response" >&2 || true
  exit 1
}

jq -e --arg url "$attachment_url" '
  any(.relations[]?; .rel == "AttachedFile" and .url == $url) and
  (.fields["Microsoft.VSTS.TCM.ReproSteps"] | contains($url))
' "$patch_response" >/dev/null || {
  echo "Work item response did not confirm both the attachment and inline image." >&2
  exit 1
}

echo "Attached and embedded $(basename "$screenshot_path") in ${organization}/${project}/_workitems/edit/${work_item_id}"
