#!/usr/bin/env bash
# Install lark-cli alongside this MCP server for AI agents that need
# both Hostinger API and Lark/Feishu capabilities.
# Source: https://github.com/larksuite/cli
set -euo pipefail

echo "==> Installing @larksuite/cli from npm..."
npm install -g @larksuite/cli

echo "==> Installing CLI skills for AI agents..."
npx skills add larksuite/cli -y -g

echo ""
lark-cli --version
echo "lark-cli installation complete."
echo ""
echo "Next steps:"
echo "  1. lark-cli config init    # configure Lark app credentials"
echo "  2. lark-cli auth login     # authenticate with Lark"
echo "  3. lark-cli auth status    # verify authentication"
