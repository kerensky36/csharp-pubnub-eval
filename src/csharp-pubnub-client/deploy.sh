#!/bin/bash

# Set your bucket name
BUCKET_NAME="pubnub-client-static"

# Step 1: Clean previous builds
echo "🧹 Cleaning previous build artifacts..."
dotnet clean

# Step 2: Publish Blazor WASM app with full optimization
echo "🚀 Publishing Blazor WebAssembly app with Trim + AOT optimizations..."
dotnet publish -c Release -p:PublishTrimmed=true -p:RunAOTCompilation=true -p:InvariantGlobalization=true

# Step 3: Define paths
ROOT_DIR="bin/Release/net8.0/publish/wwwroot"
FRAMEWORK_DIR="$ROOT_DIR/_framework"

# Step 4: (Optional) Install Binaryen tools if you want hardcore wasm-opt compression
# echo "🔧 Installing wasm-opt via brew..."
# brew install binaryen

# Step 5: (Optional) Further optimize .wasm files (if you installed wasm-opt)
# echo "⚡ Further optimizing .wasm files..."
#find "$FRAMEWORK_DIR" -name "*.wasm" -exec wasm-opt -Oz -o {} {} \;

# Step 6: Brotli compress .wasm, .dll, .js, .json
echo "📦 Compressing assets with Brotli..."
find "$FRAMEWORK_DIR" -type f \( -iname "*.wasm" -o -iname "*.dll" -o -iname "*.js" -o -iname "*.json" \) -exec brotli -k -q 11 {} \;

# Step 7: Upload all files to GCP bucket
echo "☁️ Uploading files to GCS bucket $BUCKET_NAME..."
gsutil -m cp -r "$ROOT_DIR"/* gs://$BUCKET_NAME/

# Step 8: Set correct Content-Encoding and Content-Type metadata for Brotli files
echo "🔧 Setting Content-Encoding metadata for Brotli compressed files..."
gsutil -m setmeta -h "Content-Encoding:br" -h "Content-Type:application/wasm" gs://$BUCKET_NAME/_framework/*.wasm.br
gsutil -m setmeta -h "Content-Encoding:br" -h "Content-Type:application/javascript" gs://$BUCKET_NAME/_framework/*.js.br
gsutil -m setmeta -h "Content-Encoding:br" -h "Content-Type:application/octet-stream" gs://$BUCKET_NAME/_framework/*.dll.br
gsutil -m setmeta -h "Content-Encoding:br" -h "Content-Type:application/json" gs://$BUCKET_NAME/_framework/*.json.br

# Step 9: Done!
echo "✅ Blazor app fully published and deployed to https://storage.googleapis.com/$BUCKET_NAME/index.html"