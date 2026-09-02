#!/usr/bin/env bash
# Build the zellij-tab-title plugin and refresh the committed wasm artifact.
# This is the only supported way to produce zellij-plugins/zellij-tab-title.wasm;
# commit the rebuilt artifact together with the source change that caused it.
set -euo pipefail

crate_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$crate_dir"

# .cargo/config.toml pins the build target to wasm, which has no test runner,
# so the unit tests run against the host triple instead.
host_triple=$(rustc -vV | awk '/^host: /{print $2}')
cargo test --lib --target "$host_triple"

cargo build --release
cp target/wasm32-wasip1/release/zellij-tab-title.wasm ../zellij-tab-title.wasm
echo "Wrote $(cd .. && pwd)/zellij-tab-title.wasm"
