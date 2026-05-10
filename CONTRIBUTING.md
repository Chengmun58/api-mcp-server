# Contributing to hostinger-api-mcp

Thank you for your interest in contributing to the Hostinger API MCP server. This guide covers how to set up a development environment, add new tools, and submit changes.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Running the Server Locally](#running-the-server-locally)
- [Adding New Tools](#adding-new-tools)
- [Building](#building)
- [Submitting Changes](#submitting-changes)
- [Release Process](#release-process)

## Prerequisites

- [Node.js](https://nodejs.org/) v24 or higher
- npm (comes with Node.js)

We recommend using [NVM](https://github.com/nvm-sh/nvm) to manage Node.js versions:

```bash
nvm install v24
nvm use v24
```

## Development Setup

1. Fork and clone the repository:

```bash
git clone https://github.com/<your-username>/api-mcp-server.git
cd api-mcp-server
```

2. Install dependencies:

```bash
npm install
```

3. Copy the environment example file and fill in your Hostinger API token:

```bash
cp .env.example .env
```

Edit `.env` and set `API_TOKEN` to your [Hostinger API token](https://developers.hostinger.com).

## Project Structure

```
api-mcp-server/
├── server.ts          # TypeScript source — tool definitions and server logic
├── server.js          # Compiled/distributed JavaScript entry point
├── build.js           # Build script (TypeScript → dist/)
├── types.d.ts         # TypeScript type declarations
├── tsconfig.json      # TypeScript compiler configuration
├── package.json       # Project metadata and scripts
├── Dockerfile         # Container image definition
├── .env.example       # Environment variable template
└── .github/
    └── workflows/
        └── build-release.yaml  # CI/CD: auto-tag, publish to npm, MCP registry
```

The main source file is `server.ts`. It exports a `TOOLS` array where each entry defines one MCP tool, and a request handler that maps tool names to Hostinger API calls.

## Running the Server Locally

### stdio mode (default)

```bash
node server.js
```

Point your MCP client (Claude Desktop, Cursor, etc.) at this process.

### HTTP streaming mode

```bash
node server.js --http --port 8100
```

The server listens at `http://localhost:8100`. Use this when developing against the MCP HTTP client SDK.

### Environment variables

| Variable       | Default                               | Description                        |
|----------------|---------------------------------------|------------------------------------|
| `API_TOKEN`    | *(required)*                          | Hostinger API bearer token         |
| `API_BASE_URL` | `https://developers.hostinger.com`   | Override the Hostinger API base URL |
| `DEBUG`        | `false`                               | Enable verbose request logging     |

## Adding New Tools

All tools are defined in the `TOOLS` array near the top of `server.ts`. Each tool entry is an object conforming to the `OpenApiTool` interface:

```typescript
{
  name: string;          // Unique tool identifier (used by MCP clients)
  description: string;   // Human-readable description shown to AI models
  method: string;        // HTTP method: "GET", "POST", "PUT", "DELETE", etc.
  path: string;          // Hostinger API path, e.g. "/api/vps/v1/virtual-machines"
  security: any[];       // Security requirements (see existing tools for examples)
  inputSchema: {         // JSON Schema for the tool's input parameters
    type: "object";
    properties: Record<string, { type: string; description: string }>;
    required?: string[];
  };
}
```

**Steps to add a new tool:**

1. Find the corresponding endpoint in the [Hostinger API documentation](https://developers.hostinger.com).

2. Add a new entry to the `TOOLS` array in `server.ts`, following the naming convention:
   - Use the format `<category>_<actionName>V<version>` (e.g., `hosting_createWebsiteV1`)
   - Group related tools together in the array

3. Add the request handler in the `CallToolRequestSchema` handler switch/if block, making the appropriate `axios` call to the Hostinger API.

4. Update `README.md` by adding a new `### <tool_name>` section under the correct category in the [Available Tools](README.md#available-tools) section, and add the tool to the [Table of Contents](README.md#table-of-contents).

5. Rebuild the JavaScript output:

```bash
npm run build
```

## Building

The project is written in TypeScript but distributed as plain JavaScript. To compile `server.ts` to `dist/server.js`:

```bash
npm run build
```

The build script (`build.js`) runs `tsc`, then copies `README.md` and `.env.example` into the `dist/` directory and generates a `dist/package.json`.

To run the TypeScript source directly (without a separate build step):

```bash
npm run start:ts
```

## Submitting Changes

1. Create a feature branch from `main`:

```bash
git checkout -b feat/your-feature-name
```

2. Make your changes, then commit with a descriptive message following the [Conventional Commits](https://www.conventionalcommits.org/) format:

```
feat: add VPS_createSnapshotV2 tool
fix: correct path for billing_getSubscriptionListV1
docs: update README with new tools
```

3. Push and open a pull request against `main`.

4. Ensure the PR description explains *what* changed and *why*.

## Release Process

Releases are fully automated. When a pull request is merged into `main`:

1. GitHub Actions bumps the version tag automatically (via `mathieudutour/github-tag-action`).
2. A GitHub Release is created with auto-generated release notes.
3. The package is published to [npm](https://www.npmjs.com/package/hostinger-api-mcp) and the GitHub Package Registry.
4. The updated server definition is pushed to the MCP Registry.

You do not need to manually bump versions or publish.
