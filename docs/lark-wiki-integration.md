# Lark Wiki Integration

This server ships with [`install-lark-cli.sh`](../install-lark-cli.sh) which installs the [lark-cli](https://github.com/larksuite/cli) tool alongside the Hostinger MCP server. Once installed, AI agents have access to Lark/Feishu Wiki knowledge-base operations through the `lark-cli wiki` family of commands.

## Quick Setup

```bash
# Install lark-cli and its AI agent skills
bash install-lark-cli.sh

# Configure Lark app credentials (interactive)
lark-cli config init

# Authenticate
lark-cli auth login --recommend
```

## Available Wiki Commands

### Shortcuts (Recommended)

Shortcuts are high-level wrappers that handle common multi-step workflows automatically.

| Command | Description |
|---------|-------------|
| `lark-cli wiki +node-create` | Create a wiki node with automatic space resolution |
| `lark-cli wiki +node-copy` | Copy a wiki node to a new location, with automatic space resolution |
| `lark-cli wiki +move` | Move a wiki node, or migrate a Drive document into Wiki |
| `lark-cli wiki +delete-space` | Delete a wiki space (async-safe with polling) |

### `wiki +node-create`

Creates a new node in a Lark Wiki space. Resolves the target space automatically from a parent node token or falls back to the caller's personal document library.

```bash
# Create a page in your personal wiki (user identity default)
lark-cli wiki +node-create --title "Project Plan"

# Create under a specific parent node
lark-cli wiki +node-create \
  --parent-node-token <PARENT_TOKEN> \
  --title "Sprint Notes"

# Create in an explicit space
lark-cli wiki +node-create \
  --space-id <SPACE_ID> \
  --title "Release Checklist"

# Create a shortcut node pointing to an existing node
lark-cli wiki +node-create \
  --parent-node-token <PARENT_TOKEN> \
  --node-type shortcut \
  --origin-node-token <ORIGIN_TOKEN> \
  --title "Shortcut to Design Doc"

# Preview without writing
lark-cli wiki +node-create --title "Draft" --dry-run
```

**Key flags:**

| Flag | Required | Description |
|------|----------|-------------|
| `--title` | No | Node title |
| `--space-id` | No | Target space ID; use `my_library` for personal wiki |
| `--parent-node-token` | No | Parent node token; space is inferred automatically |
| `--node-type` | No | `origin` (default) or `shortcut` |
| `--obj-type` | No | `docx` (default), `sheet`, `bitable`, `mindnote`, `slides` |
| `--origin-node-token` | No | Required when `--node-type=shortcut` |

### `wiki +node-copy`

Copies an existing wiki node to a new location within the same space. The space ID is resolved automatically from the node token when omitted.

```bash
# Copy a node (space resolved automatically)
lark-cli wiki +node-copy --node-token <NODE_TOKEN>

# Copy to a specific parent node
lark-cli wiki +node-copy \
  --node-token <NODE_TOKEN> \
  --target-parent-token <TARGET_PARENT_TOKEN>

# Copy with a new title
lark-cli wiki +node-copy \
  --node-token <NODE_TOKEN> \
  --title "Copy: Project Plan"

# Provide space ID explicitly (skips the look-up step)
lark-cli wiki +node-copy \
  --node-token <NODE_TOKEN> \
  --space-id <SPACE_ID> \
  --target-parent-token <TARGET_PARENT_TOKEN>

# Preview without writing
lark-cli wiki +node-copy --node-token <NODE_TOKEN> --dry-run
```

**Key flags:**

| Flag | Required | Description |
|------|----------|-------------|
| `--node-token` | Yes | Wiki node token to copy |
| `--space-id` | No | Source space ID; inferred from `--node-token` if omitted |
| `--target-parent-token` | No | Target parent node; defaults to same parent as source |
| `--title` | No | Title for the copy; defaults to original title |

**Required scopes:** `wiki:node:copy`, `wiki:node:read`

### `wiki +move`

Moves an existing wiki node to a different location, or migrates a Drive document into a wiki space. Handles both synchronous and asynchronous API responses.

```bash
# Move a wiki node to another parent
lark-cli wiki +move \
  --node-token <NODE_TOKEN> \
  --target-parent-token <TARGET_PARENT_TOKEN>

# Move a wiki node to a space root
lark-cli wiki +move \
  --node-token <NODE_TOKEN> \
  --target-space-id <TARGET_SPACE_ID>

# Migrate a Drive document into wiki
lark-cli wiki +move \
  --obj-type docx \
  --obj-token <DOC_TOKEN> \
  --target-space-id <TARGET_SPACE_ID>
```

### `wiki +delete-space`

Deletes a wiki space. Polls the async task automatically within a bounded window and returns a resume command if the task is still processing.

```bash
# Delete a wiki space (irreversible — --yes required)
lark-cli wiki +delete-space \
  --space-id <SPACE_ID> \
  --yes
```

> **Warning:** This operation is irreversible. The `--yes` flag is required as an explicit confirmation.

## Raw API Access

For operations not covered by shortcuts, use the underlying API commands directly:

```bash
# Inspect available parameters before calling
lark-cli schema wiki.spaces.list
lark-cli schema wiki.nodes.list
lark-cli schema wiki.members.create

# List wiki spaces
lark-cli wiki spaces list --format json

# Get a node by token
lark-cli wiki spaces get_node --params '{"token":"<wiki_token>"}'

# List child nodes of a space
lark-cli wiki nodes list --params '{"space_id":"<SPACE_ID>"}'

# Add a space member
lark-cli wiki members create \
  --params '{"space_id":"<SPACE_ID>"}' \
  --data '{"member_type":"openid","member_id":"<OPEN_ID>","role":"editor"}'
```

## Permissions Reference

| Operation | Required Scope |
|-----------|----------------|
| `nodes.copy` / `+node-copy` | `wiki:node:copy`, `wiki:node:read` |
| `nodes.create` / `+node-create` | `wiki:node:create`, `wiki:node:read`, `wiki:space:read` |
| `+move` (node mode) | `wiki:node:move`, `wiki:node:read`, `wiki:space:read` |
| `+delete-space` | `wiki:space:write_only`, `wiki:space:read` |
| `spaces.list` | `wiki:space:retrieve` |
| `spaces.get` / `spaces.get_node` | `wiki:space:read` / `wiki:node:read` |
| `members.create` | `wiki:member:create` |
| `members.delete` | `wiki:member:update` |
| `members.list` | `wiki:member:retrieve` |
| `nodes.list` | `wiki:node:retrieve` |

To grant the necessary scopes:

```bash
lark-cli auth login --scope "wiki:node:copy wiki:node:read wiki:node:create wiki:space:read"
```

## Identity Modes

All wiki commands support `--as user` (default) and `--as bot`:

```bash
# Run as the authenticated user
lark-cli wiki +node-copy --node-token <TOKEN> --as user

# Run as the configured bot (app identity)
lark-cli wiki +node-copy --node-token <TOKEN> --as bot
```

> **Note:** Bot identity cannot access the personal wiki library (`my_library`) and does not support adding department members to wiki spaces. Use `--as user` for those operations.

## Further Reading

- [lark-cli README](https://github.com/larksuite/cli)
- [Lark Open Platform — Wiki API](https://open.larksuite.com/document/server-docs/docs/wiki-v2/wiki-overview)
