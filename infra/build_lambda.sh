#!/bin/bash
set -e

cd "$(dirname "$0")/lambda"

echo "📦 Empacotando Lambda..."
zip -r ../discord_alert.zip .
echo "✅ Lambda empacotada em infra/discord_alert.zip"
