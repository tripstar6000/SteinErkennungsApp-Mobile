#!/usr/bin/env bash
set -euo pipefail

echo "== Mobile Codex + Unlazy setup =="

if ! command -v node >/dev/null 2>&1; then
  echo "Node.js fehlt."
  exit 1
fi

NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]')"
if [ "$NODE_MAJOR" -lt 16 ]; then
  echo "Node.js 16+ erforderlich, gefunden: $(node --version)"
  exit 1
fi

if ! command -v codex >/dev/null 2>&1; then
  echo "Installiere Codex CLI ..."
  curl -fsSL https://chatgpt.com/codex/install.sh | sh
fi

# Der Standalone-Installer kann Codex unter ~/.local/bin ablegen.
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
if ! grep -Fq 'export PATH="$HOME/.local/bin:$HOME/bin:$PATH"' "$HOME/.bashrc" 2>/dev/null; then
  printf '\nexport PATH="$HOME/.local/bin:$HOME/bin:$PATH"\n' >> "$HOME/.bashrc"
fi

mkdir -p "$HOME/.codex/skills"

if [ -d "$HOME/.codex/skills/unlazy/.git" ]; then
  echo "Aktualisiere Unlazy ..."
  git -C "$HOME/.codex/skills/unlazy" pull --ff-only
else
  rm -rf "$HOME/.codex/skills/unlazy"
  echo "Installiere Unlazy ..."
  git clone --depth 1 https://github.com/Leonxlnx/unlazy.git "$HOME/.codex/skills/unlazy"
fi

test -f "$HOME/.codex/skills/unlazy/SKILL.md"
test -f "$HOME/.codex/skills/unlazy/scripts/gate-check.mjs"
node "$HOME/.codex/skills/unlazy/scripts/gate-check.mjs" --help >/dev/null

echo
echo "Fertig."
echo "Node:   $(node --version)"
if command -v codex >/dev/null 2>&1; then
  echo "Codex:  $(codex --version)"
else
  echo "Codex wurde installiert. Starte das Terminal neu und rufe dann 'codex' auf."
fi
echo "Unlazy: $HOME/.codex/skills/unlazy"
echo
echo "Naechster Schritt: 'codex' starten und mit ChatGPT anmelden."
