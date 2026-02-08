#!/usr/bin/env bash

DIR=$(cd "$(dirname "$0")" && pwd)

OS=$(uname)
if [ "$OS" = "Darwin" ]; then
    exec "$DIR/setup-macos.sh" "$@"
elif [ "$OS" = "Linux" ]; then
    exec "$DIR/setup-linux.sh" "$@"
else
    echo "Unsupported OS"
    exit 1
fi