-- Build a quick type -> display-config lookup from the shared Config.
local CMD = {}
for _, def in ipairs(Config.Commands) do
    CMD[def.type] = def
end

local active = {}        -- [id] = { sender, type, text, name, avatar, expires }
local order = {}         -- ordered list of active ids (oldest first)
local idCounter = 0
local threadRunning = false
local lastHtml = ''
local debugFrames = 0    -- when > 0, buildHtml prints diagnostics this many frames

-----------------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------------

local function escapeHtml(s)
    return (s:gsub('[&<>]', { ['&'] = '&amp;', ['<'] = '&lt;', ['>'] = '&gt;' }))
end

-- Project a world position to normalised (0-1) screen coords.
local function world3dToScreen2d(x, y, z)
    return GetScreenCoordFromWorldCoord(x, y, z)
end

-- Push a bubble up (in screen space) until it no longer overlaps any bubble
-- placed earlier this frame. Older bubbles keep their spot; newer ones climb.
-- Needed when several senders share nearly the same world position, e.g.
-- multiple occupants of one vehicle.
local function resolveOverlap(placed, sx, sy)
    local moved = true
    while moved do
        moved = false
        for i = 1, #placed do
            local p = placed[i]
            if math.abs(sx - p.x) < Config.OverlapWidth and math.abs(sy - p.y) < Config.OverlapHeight then
                -- Only accept pushes that actually move us up. Due to floating-point
                -- rounding, (p.y - OverlapHeight) can still register as overlapping p,
                -- which would otherwise re-push to the same value forever (game freeze).
                local pushed = p.y - Config.OverlapHeight
                if pushed < sy then
                    sy = pushed
                    moved = true
                end
            end
        end
    end
    placed[#placed + 1] = { x = sx, y = sy }
    return sy
end

-- Drop the oldest bubble belonging to a sender (used to enforce stacking cap).
local function dropOldestFor(sender)
    for i = 1, #order do
        local id = order[i]
        if active[id] and active[id].sender == sender then
            active[id] = nil
            table.remove(order, i)
            return
        end
    end
end

-----------------------------------------------------------------------------
-- Render
-----------------------------------------------------------------------------

local function buildHtml()
    local now = GetGameTimer()
    local myCoords = GetEntityCoords(PlayerPedId())
    local stackIndex = {}    -- [sender] = how many of their lines drawn so far
    local placed = {}        -- screen positions used so far this frame (overlap resolution)
    local parts = {}
    local dbg = debugFrames > 0
    if dbg then debugFrames = debugFrames - 1 end

    for i = 1, #order do
        local id = order[i]
        local msg = active[id]
        if msg then
            if now >= msg.expires then
                active[id] = nil
                order[i] = false   -- mark for compaction below
            else
                local def = CMD[msg.type]
                local plyIdx = GetPlayerFromServerId(msg.sender)   -- player index (can be 0!), or -1 if not present
                local pedPtr = plyIdx ~= -1 and GetPlayerPed(plyIdx) or 0
                if dbg then
                    print(('[rc_me] render: sender=%s plyIdx=%s ped=%s'):format(msg.sender, plyIdx, pedPtr))
                end
                if def and pedPtr ~= 0 then
                    local sourceCoords = GetEntityCoords(pedPtr)
                    local dist = #(sourceCoords - myCoords)
                    if dist <= Config.MaxDistance then
                        local idx = stackIndex[msg.sender] or 0
                        stackIndex[msg.sender] = idx + 1

                        local onScreen, sx, sy = world3dToScreen2d(
                            sourceCoords.x + Config.OffsetX,
                            sourceCoords.y + Config.OffsetY,
                            sourceCoords.z + Config.OffsetZ + (idx * Config.LineGap)
                        )
                        if dbg then
                            print(('[rc_me] render: dist=%.1f onScreen=%s sx=%s sy=%s'):format(dist, tostring(onScreen), tostring(sx), tostring(sy)))
                        end

                        if onScreen then
                            sy = resolveOverlap(placed, sx, sy)

                            -- Discord avatar when available, otherwise the command icon
                            local head
                            if msg.avatar then
                                head = table.concat({ '<img class="rp-avatar" src="', msg.avatar, '">' })
                            else
                                head = table.concat({ '<span class="rp-icon"><i class="fas fa-', def.icon, '"></i></span>' })
                            end

                            parts[#parts + 1] = table.concat({
                                '<div class="rp-anchor" style="left:', sx * 100, '%;top:', sy * 100, '%;">',
                                '<div class="rp-row rp-', msg.type, '">',
                                head,
                                '<div class="rp-bubble">',
                                '<span class="rp-name">', escapeHtml(msg.name or def.label), '</span>',
                                '<span class="rp-text">', escapeHtml(msg.text), '</span>',
                                '</div>',
                                '</div></div>',
                            })
                        end
                    end
                end
            end
        end
    end

    -- compact the order list (drop expired/false entries)
    local compact = {}
    for i = 1, #order do
        if order[i] then compact[#compact + 1] = order[i] end
    end
    order = compact

    return table.concat(parts)
end

local function startThread()
    if threadRunning then return end
    threadRunning = true

    CreateThread(function()
        while #order > 0 do
            local html = buildHtml()
            if html ~= lastHtml then
                if Config.Debug then
                    print(('[rc_me] SendNUIMessage html length=%d'):format(#html))
                end
                SendNUIMessage({ action = 'render', html = html })
                lastHtml = html
            end
            Wait(0)
        end

        -- nothing left to show
        if lastHtml ~= '' then
            SendNUIMessage({ action = 'render', html = '' })
            lastHtml = ''
        end
        threadRunning = false
    end)
end

-----------------------------------------------------------------------------
-- Chat suggestions
-----------------------------------------------------------------------------

CreateThread(function()
    for _, def in ipairs(Config.Commands) do
        TriggerEvent('chat:addSuggestion', '/' .. def.command, def.help or def.label, {
            { name = 'text', help = 'what happens' },
        })
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for _, def in ipairs(Config.Commands) do
        TriggerEvent('chat:removeSuggestion', '/' .. def.command)
    end
end)

-----------------------------------------------------------------------------
-- Network
-----------------------------------------------------------------------------

RegisterNetEvent('rc_me:show', function(sender, payload)
    if Config.Debug then
        print(('[rc_me] received %s from %s: %s'):format(
            type(payload) == 'table' and payload.type or '?', sender,
            type(payload) == 'table' and payload.text or tostring(payload)))
    end
    if type(payload) ~= 'table' or not CMD[payload.type] then return end

    -- enforce per-player stacking cap
    local count = 0
    for _, msg in pairs(active) do
        if msg.sender == sender then count = count + 1 end
    end
    while count >= Config.MaxLinesPerPlayer do
        dropOldestFor(sender)
        count = count - 1
    end

    idCounter = idCounter + 1
    active[idCounter] = {
        sender  = sender,
        type    = payload.type,
        text    = payload.text or '',
        name    = payload.name,
        avatar  = payload.avatar,
        expires = GetGameTimer() + Config.Duration,
    }
    order[#order + 1] = idCounter

    if Config.Debug then debugFrames = 5 end
    startThread()
end)
