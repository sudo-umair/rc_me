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

-- Send a message to every player within range of the sender (OneSync).
local function broadcastNearby(src, payload)
    local senderPed = GetPlayerPed(src)
    if senderPed == 0 then return end
    local origin = GetEntityCoords(senderPed)

    for _, pid in ipairs(GetPlayers()) do
        local target = tonumber(pid)
        local ped = GetPlayerPed(target)
        if ped ~= 0 then
            local dist = #(GetEntityCoords(ped) - origin)
            if dist <= Config.MaxDistance then
                TriggerClientEvent('rc_me:show', target, src, payload)
            end
        end
    end
end

-----------------------------------------------------------------------------
-- Command registration
-----------------------------------------------------------------------------

local function handleCommand(def, src, args)
    -- cooldown
    if Config.Cooldown > 0 then
        local now = GetGameTimer()
        if lastUsed[src] and (now - lastUsed[src]) < Config.Cooldown then
            return
        end
        lastUsed[src] = now
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
    text = text:sub(1, Config.MaxLength)

    -- /try outcome (server-authoritative)
    local success = nil
    if def.isTry then
        success = math.random(1, 100) <= Config.TrySuccessChance
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
