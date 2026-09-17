#!/usr/bin/env bash
# Build PassForge IPA on macOS (requires Xcode + CocoaPods + Apple signing).
# Target devices: iPhone X and later running iOS 15+.
#
# Usage:
#   ./scripts/build_ios.sh                 # ipa via flutter build ipa (App Store)
#   ./scripts/build_ios.sh ad-hoc          # ad-hoc ExportOptions
#   ./scripts/build_ios.sh development     # development ExportOptions
#
# Before first run:
#   1. Open ios/Runner.xcworkspace in Xcode
#   2. Select Runner → Signing & Capabilities → your Team
#   3. Replace YOUR_APPLE_TEAM_ID in ios/ExportOptions-*.plist (optional for flutter build ipa)

set -euo pipefail
cd "$(dirname "$0")/.."

METHOD="${1:-app-store}"
case "$METHOD" in
  app-store|ad-hoc|development) ;;
  *)
    echo "Unknown method: $METHOD (use app-store | ad-hoc | development)"
    exit 1
    ;;
esac

EXPORT_PLIST="ios/ExportOptions-${METHOD}.plist"
if [[ "$METHOD" == "app-store" ]]; then
  EXPORT_PLIST="ios/ExportOptions-app-store.plist"
fi

echo "==> flutter pub get"
flutter pub get

echo "==> pod install"
( cd ios && pod install )

echo "==> flutter build ipa ($METHOD)"
flutter build ipa --release --export-options-plist="$EXPORT_PLIST"

echo ""
echo "Done. IPA should be under:"
echo "  build/ios/ipa/"
ls -la build/ios/ipa/ 2>/dev/null || true
echo ""
echo "Install paths:"
echo "  • TestFlight / App Store Connect: upload the IPA or use Xcode Organizer"
echo "  • Ad Hoc / Development: install via Finder, Apple Configurator, or Xcode Devices"
echo "  • Minimum iOS: 15.0 · Devices: iPhone only (iPhone X and newer)"
