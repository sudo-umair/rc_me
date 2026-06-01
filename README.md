# rc_me

Roleplay floating-text commands for **ESX** — `/me`, `/try` — rendered as
clean glass NUI bubbles projected above the player in 3D world space.

Built as an improved rewrite of the classic `3dme` script.

## Features

- **Multiple concurrent bubbles** — many players can use commands at once without overwriting
  each other (the original `3dme` could only show one at a time).
- **Per-player stacking** — one player can have several lines stacked vertically
  (`Config.MaxLinesPerPlayer`).
- **Server-side OneSync proximity** — only players within `Config.MaxDistance` receive the
  message, instead of broadcasting to everyone.
- **Server-authoritative `/try`** — success/fail is rolled on the server (`Config.TrySuccessChance`).
- **Job-gated commands** — any command can be restricted to specific jobs (`jobs` field per command).
- **Efficient rendering** — a single client thread runs only while bubbles are active and pushes
  NUI updates only when the markup actually changes.
- Anti-spam cooldown and max-length clamping.

## Commands

| Command       | Example                       | Notes                                  |
|---------------|-------------------------------|----------------------------------------|
| `/me <text>`  | `/me opens the door slowly`   | Action you perform                     |
| `/try <text>` | `/try to pick the lock`       | Appends a server-rolled succeeds/fails |

## Dependencies

- `es_extended`
- `ox_lib`
- OneSync (Infinity) enabled — required for server-side proximity.

## Installation

1. Drop the `rc_me` folder into your `resources`.
2. Add `ensure rc_me` to your `server.cfg` (after `es_extended` and `ox_lib`).
3. Adjust `config.lua` to taste.

## Configuration

All settings live in `config.lua`: distance, duration, cooldown, stacking limits, the `/try`
success chance, and the command table (label, icon, accent colour, and per-command `jobs`
whitelist). Accent colours in `config.lua` must match the matching `.rp-<type>` rules in
`html/style.css`.
