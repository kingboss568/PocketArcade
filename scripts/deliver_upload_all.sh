#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

if [[ -f ".env.fastlane" ]]; then
  set -a; source .env.fastlane; set +a
fi

: "${ASC_ISSUER_ID:?ASC_ISSUER_ID is required}"
: "${ASC_KEY_ID:?ASC_KEY_ID is required}"
: "${ASC_KEY_FILE:?ASC_KEY_FILE is required}"
[[ -f "$ASC_KEY_FILE" ]] || { echo "ASC_KEY_FILE does not exist: $ASC_KEY_FILE"; exit 1; }
command -v fastlane >/dev/null 2>&1 || { echo "fastlane not found. Run: brew install fastlane"; exit 1; }

echo "[1/4] Upload metadata"
set +e
fastlane ios deliver_metadata
META_EXIT=$?
set -e
[[ $META_EXIT -eq 0 ]] || echo "[warn] metadata lane failed (known first-version fastlane issue). continue..."

echo "[2/4] Upload screenshots"
fastlane ios deliver_screenshots

if [[ -n "${IPA_PATH:-}" && -f "$IPA_PATH" ]]; then
  echo "[3/4] Upload IPA"
  fastlane ios deliver_ipa ipa:"$IPA_PATH"
elif [[ -n "${IPA_PATH:-}" ]]; then
  echo "[3/4] Skip IPA upload because IPA_PATH is set but the file does not exist yet: $IPA_PATH"
else
  echo "[3/4] Skip IPA upload because IPA_PATH is not set"
fi

echo "[4/4] Done. Verify latest build, IAP, Privacy URL, Support URL, and screenshots before submitting for review."
