#!/bin/zsh
PROJECT_NAME=$1

rm -f ../bin/*.dylib
cp .build/arm64-apple-macosx/debug/lib${PROJECT_NAME}.dylib .build/arm64-apple-macosx/debug/libSwiftGodot.dylib .build/arm64-apple-macosx/debug/libSwiftGodotMacros.dylib ../bin
cat ./scripts/Config.gdextension.template |  awk -v proj=${PROJECT_NAME} '{gsub(/\{PROJECT_NAME\}/,proj)}1' > ../bin/${PROJECT_NAME}.gdextension

echo "✅ Copied ${PROJECT_NAME} to Godot Project"