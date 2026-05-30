-- Build a quick type -> display-config lookup from the shared Config.
local CMD = {}
for _, def in ipairs(Config.Commands) do
    CMD[def.type] = def
end

local active = {}        -- [id] = { sender, type, text, success, expires }
local order = {}         -- ordered list of active ids (oldest first)
local idCounter = 0
local threadRunning = false
local lastHtml = ''

-----------------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------------

local function escapeHtml(s)
    return (s:gsub('[&<>]', { ['&'] = '&amp;', ['<'] = '&lt;', ['>'] = '&gt;' }))
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
    local parts = {}

    for i = 1, #order do
        local id = order[i]
        local msg = active[id]
        if msg then
            if now >= msg.expires then
                active[id] = nil
                order[i] = false   -- mark for compaction below
            else
                local def = CMD[msg.type]
                local ped = GetPlayerFromServerId(msg.sender)
                if def and ped ~= -1 and ped ~= 0 then
                    local pedPtr = GetPlayerPed(ped)
                    local sourceCoords = GetEntityCoords(pedPtr)
                    if #(sourceCoords - myCoords) <= Config.MaxDistance then
                        local idx = stackIndex[msg.sender] or 0
                        stackIndex[msg.sender] = idx + 1

                        local onScreen, sx, sy = GetHudScreenPositionFromWorldPosition(
                            sourceCoords.x + Config.OffsetX,
                            sourceCoords.y + Config.OffsetY,
                            sourceCoords.z + Config.OffsetZ + (idx * Config.LineGap)
                        )

                        if onScreen then
                            local text = escapeHtml(msg.text)
                            if msg.success ~= nil then
                                local outcome = msg.success and Config.TrySuccessText or Config.TryFailText
                                local cls = msg.success and 'rp-ok' or 'rp-bad'
                                text = ('tries to %s and <span class="%s">%s</span>'):format(text, cls, outcome)
                            end
                            parts[#parts + 1] = table.concat({
                                '<div class="rp-anchor" style="left:', sx * 100, '%;top:', sy * 100, '%;">',
                                '<div class="rp-bubble rp-', msg.type, '">',
                                '<span class="rp-icon"><i class="fas fa-', def.icon, '"></i></span>',
                                '<span class="rp-label">', def.label, '</span>',
                                '<span class="rp-text">', text, '</span>',
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
-- Network
-----------------------------------------------------------------------------

RegisterNetEvent('rc_me:show', function(sender, payload)
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
        success = payload.success,
        expires = GetGameTimer() + Config.Duration,
    }
    order[#order + 1] = idCounter

    startThread()
end)
