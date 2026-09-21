#!/usr/bin/env bash
# Build the mobile app against PRODUCTION Supabase (env.prod.json).
#
#   ./scripts/build_app.sh apk      # Android .apk to hand to testers directly
#   ./scripts/build_app.sh ios      # iOS archive for TestFlight (needs Apple Developer signing)
#   ./scripts/build_app.sh sim      # iOS Simulator build, then install + launch on the booted simulator
#
# Every target passes --dart-define-from-file=env.prod.json. A release build made
# without it refuses to start (SupabaseConfig.assertConfigured), so this script
# is the only supported way to build for real phones.
set -euo pipefail
cd "$(dirname "$0")/../apps/user_app"
ENV=../../env.prod.json
[ -f "$ENV" ] || { echo "missing $ENV"; exit 1; }

case "${1:-}" in
  apk)
    flutter build apk --release --dart-define-from-file=$ENV
    echo "→ build/app/outputs/flutter-apk/app-release.apk" ;;
  ios)
    flutter build ipa --release --dart-define-from-file=$ENV
    echo "→ build/ios/ipa/*.ipa  (upload with Transporter or Xcode → Organizer)" ;;
  sim)
    flutter build ios --simulator --dart-define-from-file=$ENV
    APP=build/ios/iphonesimulator/Runner.app
    xcrun simctl install booted "$APP"
    xcrun simctl launch booted com.diliontech.aiotschoollab ;;
  *) sed -n 2,7p "$0"; exit 1 ;;
esac
