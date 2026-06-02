# rc_me

Roleplay floating-text command for **ESX** — `/me` — rendered as a clean glass NUI bubble
projected above the player in 3D world space, showing the sender's **Discord name and avatar**.

Built as an improved rewrite of the classic `3dme` script.

## Features

- **Discord identity** — each bubble shows the sender's Discord display name and profile
  picture (fetched server-side via the Discord API and cached per session).
- **Multiple concurrent bubbles** — many players can use commands at once without overwriting
  each other (the original `3dme` could only show one at a time).
- **Per-player stacking** — one player can have several lines stacked vertically
  (`Config.MaxLinesPerPlayer`).
- **Server-side OneSync proximity** — only players within `Config.MaxDistance` receive the
  message, instead of broadcasting to everyone.
- **Job-gated commands** — any command can be restricted to specific jobs (`jobs` field per command).
- **Efficient rendering** — a single client thread runs only while bubbles are active and pushes
  NUI updates only when the markup actually changes.
- Anti-spam cooldown and max-length clamping.

## Commands

| Command       | Example                       | Notes                                  |
|---------------|-------------------------------|----------------------------------------|
| `/me <text>`  | `/me opens the door slowly`   | Action you perform                     |

## Dependencies

- `es_extended`
- `ox_lib`
- OneSync (Infinity) enabled — required for server-side proximity.
- A **Discord bot token** for the name/avatar lookup (see below).

## Installation

1. Drop the `rc_me` folder into your `resources`.
2. Add `ensure rc_me` to your `server.cfg` (after `es_extended` and `ox_lib`).
3. Create a Discord application/bot at <https://discord.com/developers/applications>, copy its
   bot token and paste it into `Config.DiscordBotToken` in `config.lua`. The bot does **not**
   need to be invited to your guild — it is only used to look up public user profiles.
4. Adjust the rest of `config.lua` to taste.

> Players without a linked Discord identifier (or if no bot token is configured) fall back to
> their ESX character name and the command icon instead of an avatar.

## Configuration

All settings live in `config.lua`: distance, duration, cooldown, stacking limits, the Discord
bot token, and the command table (label, icon, accent colour, and per-command `jobs` whitelist).
Accent colours in `config.lua` must match the matching `.rp-<type>` rules in `html/style.css`.
