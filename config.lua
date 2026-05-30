Config = {}

-----------------------------------------------------------------------------
-- General
-----------------------------------------------------------------------------

Config.Debug        = true   -- print diagnostics to server & client (F8) consoles
Config.MaxLength    = 112    -- max characters allowed in a single line
Config.Duration     = 8000   -- how long (ms) a bubble stays on screen
Config.MaxDistance  = 20.0   -- how far (metres) nearby players can see the text
Config.Cooldown     = 1000   -- anti-spam: min ms between commands per player (0 to disable)

-----------------------------------------------------------------------------
-- Stacking — one player using several commands quickly
-----------------------------------------------------------------------------

Config.MaxLinesPerPlayer = 3     -- max simultaneous bubbles above one player
Config.LineGap           = 0.28  -- vertical world-space gap between stacked lines

-----------------------------------------------------------------------------
-- World offset of the bubble relative to the player's position
-----------------------------------------------------------------------------

Config.OffsetX = 0.0
Config.OffsetY = 0.0
Config.OffsetZ = 1.10   -- height above the ped's root

-----------------------------------------------------------------------------
-- /try outcome — the roll is performed server-side (authoritative)
-----------------------------------------------------------------------------

Config.TrySuccessChance = 50          -- percent chance of success (0-100)
Config.TrySuccessText   = 'succeeds'
Config.TryFailText      = 'fails'

-----------------------------------------------------------------------------
-- Commands
-- type       : internal id, also used as the NUI css modifier (rp-<type>)
-- command    : the chat command players type (without the slash)
-- label      : short tag shown in the bubble
-- icon       : Font Awesome 5 icon name (without the "fa-" prefix)
-- accent     : accent colour (border + label + icon)
-- isTry      : if true, appends a server-rolled success/fail outcome
-- jobs       : if set, only these ESX jobs may use the command (nil = everyone)
-----------------------------------------------------------------------------

Config.Commands = {
    {
        type    = 'me',
        command = 'me',
        label   = 'ME',
        icon    = 'comment-dots',
        accent  = '#cb73e6',
    },
    {
        type    = 'do',
        command = 'do',
        label   = 'DO',
        icon    = 'eye',
        accent  = '#4d66f1',
    },
    {
        type    = 'try',
        command = 'try',
        label   = 'TRY',
        icon    = 'dice',
        accent  = '#e0a93b',
        isTry   = true,
    },
    {
        type    = 'med',
        command = 'med',
        label   = 'MED',
        icon    = 'hand-holding-medical',
        accent  = '#e3534f',
        jobs    = { 'ambulance' },   -- EMS only
    },
}
