#!/bin/bash
set -e

cd "$(dirname "$0")/lambda"

echo "📦 Empacotando Lambda..."
zip -r ../lambda.zip .

echo "✅ Lambda empacotada em infra/lambda.zip"
