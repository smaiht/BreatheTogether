#!/bin/bash
set -e

APP_NAME="Breathe Together"
REPO="smaiht/BreatheTogether"
DEST="/Applications/$APP_NAME.app"
TMP="/tmp/BreatheTogether-$$.dmg"
VOL=""

cleanup() { 
  [ -n "$VOL" ] && hdiutil detach "$VOL" -quiet 2>/dev/null
  rm -f "$TMP"
}
trap cleanup EXIT

echo "🫁 Installing $APP_NAME..."

# Get latest macOS release DMG URL (filter mac- tags only)
DMG_URL=$(curl -sL "https://api.github.com/repos/$REPO/releases" \
  | grep -o '"browser_download_url": *"[^"]*mac-v[^"]*\.dmg"' \
  | head -1 | sed 's/.*"browser_download_url": *"//;s/"//')

if [ -z "$DMG_URL" ]; then
  echo "❌ Could not find latest release"; exit 1
fi

echo "⬇️  Downloading..."
curl -fL --progress-bar "$DMG_URL" -o "$TMP"

echo "📦 Installing to /Applications..."
VOL=$(hdiutil attach "$TMP" -nobrowse 2>/dev/null | grep '/Volumes/' | sed 's/.*\(\/Volumes\/.*\)/\1/')

if [ ! -d "$VOL/$APP_NAME.app" ]; then
  echo "❌ App not found in DMG"; exit 1
fi

[ -d "$DEST" ] && rm -rf "$DEST"
cp -R "$VOL/$APP_NAME.app" "$DEST"

echo "✅ Installed! Launching..."
open "$DEST"
