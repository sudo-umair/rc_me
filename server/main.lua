local ESX = exports['es_extended']:getSharedObject()

local lastUsed = {}   -- [src] = game timer of last command

-----------------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------------

local function notify(src, msg, ntype)
    TriggerClientEvent('ox_lib:notify', src, {
        title       = 'RP',
        description = msg,
        type        = ntype or 'error',
        position    = 'top',
    })
end

-- Truncate a string to maxChars characters without splitting a UTF-8
-- codepoint (plain :sub() counts bytes and can cut a multibyte char in half).
local function truncate(s, maxChars)
    local len = utf8.len(s)
    if not len then
        return s:sub(1, maxChars)   -- invalid UTF-8; fall back to byte truncation
    end
    if len <= maxChars then
        return s
    end
    return s:sub(1, utf8.offset(s, maxChars + 1) - 1)
end

-- True if the player is allowed to use a command with the given job whitelist.
local function jobAllowed(src, jobs)
    if not jobs or #jobs == 0 then return true end
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false end
    local name = xPlayer.getJob().name
    for _, allowed in ipairs(jobs) do
        if name == allowed then return true end
    end
    return false
end

-- Send the message out. We broadcast to all players and let each client filter
-- by distance to the sender's ped (peds always stream client-side, so this is
-- reliable and needs no server-side entity access / OneSync entity lookups).
local function broadcastNearby(src, payload)
    if Config.Debug then
        print(('[rc_me] broadcasting %s from %s: %s'):format(payload.type, src, payload.text))
    end
    TriggerClientEvent('rc_me:show', -1, src, payload)
end

-----------------------------------------------------------------------------
-- Command registration
-----------------------------------------------------------------------------

local function handleCommand(def, src, args)
    -- cooldown (checked here, but only consumed once the command succeeds)
    if Config.Cooldown > 0 and lastUsed[src] then
        if (GetGameTimer() - lastUsed[src]) < Config.Cooldown then
            notify(src, 'Please wait a moment before using another RP command')
            return
        end
    end

    -- job restriction
    if not jobAllowed(src, def.jobs) then
        notify(src, 'You are not authorized to use /' .. def.command)
        return
    end

    -- text
    local text = table.concat(args, ' ')
    text = text:gsub('^%s*(.-)%s*$', '%1')        -- trim
    if text == '' then
        notify(src, 'Usage: /' .. def.command .. ' <text>')
        return
    end
    text = truncate(text, Config.MaxLength)

    -- /try outcome (server-authoritative)
    local success = nil
    if def.isTry then
        success = math.random(1, 100) <= Config.TrySuccessChance
    end

    -- command succeeded — consume the cooldown
    if Config.Cooldown > 0 then
        lastUsed[src] = GetGameTimer()
    end

    broadcastNearby(src, {
        type    = def.type,
        text    = text,
        success = success,
    })
end

CreateThread(function()
    for _, def in ipairs(Config.Commands) do
        RegisterCommand(def.command, function(source, args)
            if source == 0 then return end   -- ignore console
            handleCommand(def, source, args)
        end, false)
    end
end)

AddEventHandler('playerDropped', function()
    lastUsed[source] = nil
end)
