#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

SEARCH_CMD=""
if command -v rg >/dev/null 2>&1; then
  SEARCH_CMD="rg"
elif command -v grep >/dev/null 2>&1; then
  SEARCH_CMD="grep"
else
  echo "[FAIL] Ne rg ne grep bulundu."
  exit 1
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "[FAIL] flutter bulunamadi. PATH kontrol et."
  exit 1
fi

echo "== Actora Release Preflight =="

declare -a checks=(
  "ios/Runner.xcodeproj/project.pbxproj:com.example.actora"
  "android/app/build.gradle.kts:com.example.actora"
  "android/app/src/main/kotlin/com/hatirlatbana/invite/MainActivity.kt:package com.hatirlatbana.invite"
  "ios/Runner/Runner.entitlements:applinks:actora.app"
  "android/app/src/main/AndroidManifest.xml:android:host=\"actora.app\""
  "web/.well-known/apple-app-site-association:com.example.actora"
  "web/.well-known/assetlinks.json:com.example.actora"
  "lib/services/viral/invite_backend_service.dart:https://actora.app"
)

placeholder_failed=0
for row in "${checks[@]}"; do
  file="${row%%:*}"
  pattern="${row#*:}"

  if [[ "$SEARCH_CMD" == "rg" ]]; then
    $SEARCH_CMD -n "$pattern" "$file" >/dev/null 2>&1
  else
    $SEARCH_CMD -n "$pattern" "$file" >/dev/null 2>&1
  fi

  if [[ "$?" -eq 0 ]]; then
    echo "[FAIL] Placeholder bulundu: $file => $pattern"
    placeholder_failed=1
  else
    echo "[OK] $file"
  fi
done

if [[ "$placeholder_failed" -eq 1 ]]; then
  echo
  echo "[STOP] Placeholder degerler var. Canliya cikmadan once guncelle."
  exit 1
fi

echo
echo "[STEP] flutter pub get"
flutter pub get

echo
echo "[STEP] flutter analyze"
flutter analyze

echo
echo "[STEP] flutter test"
flutter test

echo
echo "[DONE] Release preflight basarili."
