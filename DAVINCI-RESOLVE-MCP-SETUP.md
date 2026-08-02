# DaVinci Resolve MCP — Setup Guide

This repo is configured to use the [davinci-resolve-mcp](https://github.com/samuelgursky/davinci-resolve-mcp)
server, which lets AI assistants (Claude Code, Claude Desktop, Cursor, etc.)
control DaVinci Resolve through its official Scripting API.

The `.mcp.json` file in the repo root registers two servers for Claude Code:

| Server | What it does | Needs Resolve running? |
|---|---|---|
| `davinci-resolve` | Live control of DaVinci Resolve (timelines, media pool, grading, rendering, Fusion, Fairlight — 34 compound tools) | Yes |
| `davinci-resolve-advanced` | Offline editing of Resolve files (`.drp` / `.drt` / `.drx`), grading/QC catalog, project DB tools — 18 tools | No |

## Prerequisites (your local machine)

1. **DaVinci Resolve 18.5+** (macOS, Windows, or Linux)
   - **Studio edition**: supports external scripting directly.
   - **Free edition**: external scripting is gated by Blackmagic — use the
     in-app bridge (see "Free edition" below).
2. **Python 3.10+** (3.10–3.12 is the lowest-risk range)
3. **Node.js 18.17+** (for the `npx` launcher)

## One-time setup

1. Open DaVinci Resolve and set
   **Preferences > General > External scripting using** to **Local**
   (Studio edition only — this preference has no effect on the free edition).

2. With Resolve running, run the installer:

   ```bash
   npx davinci-resolve-mcp setup
