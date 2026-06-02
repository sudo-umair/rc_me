local ESX = exports['es_extended']:getSharedObject()

local lastUsed = {}       -- [src] = game timer of last command
local discordCache = {}   -- [src] = { name = ..., avatar = ... } | false (lookup failed / no Discord)

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

-----------------------------------------------------------------------------
-- Discord profile
-----------------------------------------------------------------------------

-- Discord CDN default avatar for users without a custom one.
local function defaultAvatar(discordId)
    local id = tonumber(discordId)
    local idx = id and math.floor(id / 4194304) % 6 or 0   -- (snowflake >> 22) % 6
    return ('https://cdn.discordapp.com/embed/avatars/%d.png'):format(idx)
end

-- Resolve the player's Discord display name + avatar URL, caching successful
-- lookups for the rest of their session. cb(profile|nil) — may be called
-- asynchronously. Failures are NOT cached, so a transient API error only
-- affects the current message.
local function fetchDiscordProfile(src, cb)
    if discordCache[src] then
        return cb(discordCache[src])
    end

    if Config.DiscordBotToken == '' then
        print('[rc_me] WARNING: Config.DiscordBotToken is not set — /me will show character names instead of Discord profiles')
        return cb(nil)
    end

    local identifier = GetPlayerIdentifierByType(src, 'discord')
    if not identifier then
        print(('[rc_me] player %s has no Discord identifier (Discord not running when they connected?)'):format(src))
        return cb(nil)
    end
    local discordId = identifier:gsub('discord:', '')

    PerformHttpRequest(('https://discord.com/api/v10/users/%s'):format(discordId), function(status, body)
        if status ~= 200 or not body then
            print(('[rc_me] Discord lookup for player %s failed (HTTP %s) — check that the bot token is valid'):format(src, status))
            return cb(nil)
        end

        local data = json.decode(body)
        if not data then
            print(('[rc_me] Discord lookup for player %s returned invalid JSON'):format(src))
            return cb(nil)
        end

        local avatar
        if data.avatar then
            avatar = ('https://cdn.discordapp.com/avatars/%s/%s.png?size=64'):format(discordId, data.avatar)
        else
            avatar = defaultAvatar(discordId)
        end

        discordCache[src] = {
            name   = data.global_name or data.username,
            avatar = avatar,
        }
        cb(discordCache[src])
    end, 'GET', '', { ['Authorization'] = 'Bot ' .. Config.DiscordBotToken })
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

    -- command succeeded — consume the cooldown
    if Config.Cooldown > 0 then
        lastUsed[src] = GetGameTimer()
    end

    fetchDiscordProfile(src, function(profile)
        -- fall back to the character name when Discord info is unavailable
        local name
        if profile then
            name = profile.name
        else
            local xPlayer = ESX.GetPlayerFromId(src)
            name = xPlayer and xPlayer.getName() or GetPlayerName(src)
        end

        broadcastNearby(src, {
            type   = def.type,
            text   = text,
            name   = name,
            avatar = profile and profile.avatar or nil,
        })
    end)
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
    discordCache[source] = nil
end)
