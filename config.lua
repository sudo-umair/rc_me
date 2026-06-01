Config = {}

-----------------------------------------------------------------------------
-- General
-----------------------------------------------------------------------------

Config.Debug        = false  -- print diagnostics to server & client (F8) consoles
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
-- Overlap resolution — different players whose bubbles would draw on top of
-- each other (e.g. several people sitting in the same vehicle)
-----------------------------------------------------------------------------

Config.OverlapWidth  = 0.17   -- horizontal screen distance (0-1) under which two bubbles count as overlapping
Config.OverlapHeight = 0.045  -- vertical screen size (0-1) of a bubble; overlapping bubbles are pushed up by this

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
-- help       : description shown in the chat autocomplete suggestion
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
        help    = 'Describe an action your character performs',
        icon    = 'comment-dots',
        accent  = '#e0a93b',
    },
    {
        type    = 'do',
        command = 'do',
        label   = 'DO',
        help    = 'Describe the scene or your character\'s state',
        icon    = 'eye',
        accent  = '#4d66f1',
    },
    {
        type    = 'try',
        command = 'try',
        label   = 'TRY',
        help    = 'Attempt an action — the server rolls success or failure',
        icon    = 'dice',
        accent  = '#cb73e6',
        isTry   = true,
    },
    {
        type    = 'med',
        command = 'med',
        label   = 'MED',
        help    = 'Describe a medical action (EMS only)',
        icon    = 'hand-holding-medical',
        accent  = '#e3534f',
        jobs    = { 'ambulance' },   -- EMS only
    },
}
