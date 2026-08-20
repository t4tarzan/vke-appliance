#!/bin/bash
# VKE — native macOS install (Apple silicon · MLX · no Docker).
#
#   curl -fsSL https://raw.githubusercontent.com/t4tarzan/vke-appliance/main/install-macos.sh | bash
#
# Installs into ~/.vke (app · venv · models · data · logs) + one LaunchAgent.
# Uninstall any time with:  vke uninstall
# Optional env: VKE_PORT (default 9040) · VKE_MLX_PORT (8081) · VKE_TRAINER_PORT (9003)
set -euo pipefail
[ "$(uname -sm)" = "Darwin arm64" ] || { echo "✗ VKE native needs an Apple-silicon Mac (this is $(uname -sm))"; exit 1; }
H="${VKE_HOME:-$HOME/.vke}"
PORT="${VKE_PORT:-9040}"; MLXP="${VKE_MLX_PORT:-8081}"; TRP="${VKE_TRAINER_PORT:-9003}"
BUNDLE="${VKE_NATIVE_BUNDLE:-https://github.com/t4tarzan/vke-appliance/releases/latest/download/vke-native.tar.gz}"
say(){ printf '\033[1m› %s\033[0m\n' "$*"; }

say "VKE native install → $H (app on :$PORT)"
mkdir -p "$H"/{app,data,models,logs,bin} "$HOME/.local/bin" "$HOME/Library/LaunchAgents"

if ! command -v uv >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/uv" ]; then
  say "installing uv (the Python toolchain — no sudo)"
  curl -LsSf https://astral.sh/uv/install.sh | sh >/dev/null
fi
UV="$(command -v uv || echo "$HOME/.local/bin/uv")"

say "fetching the latest VKE bundle"
curl -fsSL "$BUNDLE" -o "$H/bundle.tar.gz"
rm -rf "$H/app.new" && mkdir "$H/app.new"
tar xzf "$H/bundle.tar.gz" -C "$H/app.new"
[ -f "$H/app.new/VERSION" ] || { echo "✗ bundle invalid"; exit 1; }
rm -rf "$H/app" && mv "$H/app.new" "$H/app" && rm -f "$H/bundle.tar.gz"

say "python venv + dependencies (fastapi · uvicorn · mlx-lm)"
[ -d "$H/venv" ] || "$UV" venv "$H/venv" --python 3.12 >/dev/null
"$UV" pip install -q -p "$H/venv/bin/python" -r "$H/app/requirements.txt" mlx-lm huggingface_hub

say "installing the vke command + the launch agent"
install -m 0755 "$H/app/deploy/macos/vke" "$H/bin/vke"
ln -sf "$H/bin/vke" "$HOME/.local/bin/vke"
PLIST="$HOME/Library/LaunchAgents/com.vke.app.plist"
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.vke.app</string>
  <key>ProgramArguments</key><array>
    <string>$H/venv/bin/python</string>
    <string>$H/app/deploy/macos/supervisor.py</string>
  </array>
  <key>EnvironmentVariables</key><dict>
    <key>VKE_HOME</key><string>$H</string>
    <key>VKE_PORT</key><string>$PORT</string>
    <key>VKE_MLX_PORT</key><string>$MLXP</string>
    <key>VKE_TRAINER_PORT</key><string>$TRP</string>
  </dict>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>$H/logs/supervisor.log</string>
  <key>StandardErrorPath</key><string>$H/logs/supervisor.log</string>
</dict></plist>
EOF
launchctl bootout "gui/$(id -u)/com.vke.app" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"

say "waiting for first boot (downloads ~1.2GB of models the first time)…"
for i in $(seq 1 120); do
  curl -sf "http://127.0.0.1:$PORT/health" >/dev/null 2>&1 && break
  sleep 5
done
if curl -sf "http://127.0.0.1:$PORT/health" >/dev/null 2>&1; then
  V=$(cat "$H/app/VERSION")
  say "✓ VKE v$V is running — opening http://localhost:$PORT"
  say "  sign in: ML engineer U-ML / 3333 · demo U-DEMO / 0000 · manage with: vke status|logs|uninstall"
  open "http://localhost:$PORT" 2>/dev/null || true
else
  say "still starting (model download) — watch:  vke logs   then open http://localhost:$PORT"
fi
