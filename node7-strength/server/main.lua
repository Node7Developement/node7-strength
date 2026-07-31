local Core = nil
local Loaded = {}
local RecentFightTargets = {}

local function log(message)
    if Config.Debug then
        print(('[node7-strength] %s'):format(message))
    end
end

local function now()
    return os.time()
end

local function getCore()
    if Core then return Core end

    local ok, result = pcall(function()
        return exports['node7-core']:GetCoreObject()
    end)

    if ok and result then
        Core = result
    end

    return Core
end

local function notify(src, message, kind)
    TriggerClientEvent('node7-strength:client:notify', src, message, kind or 'info')
end

local function getIdentifier(src)
    local identifiers = GetPlayerIdentifiers(src)
    for _, identifier in ipairs(identifiers) do
        if identifier:find('license:', 1, true) then
            return identifier
        end
    end

    return identifiers[1] or ('source:' .. tostring(src))
end

local function getCitizenId(src)
    local core = getCore()

    if core then
        local candidates = {}

        if core.Functions and type(core.Functions.GetPlayer) == 'function' then
            local ok, player = pcall(core.Functions.GetPlayer, src)
            if ok and player then
                candidates[#candidates + 1] = player.citizenid
                candidates[#candidates + 1] = player.citizenId
                candidates[#candidates + 1] = player.citizen_id
                candidates[#candidates + 1] = player.charid
                candidates[#candidates + 1] = player.charId

                if player.PlayerData then
                    candidates[#candidates + 1] = player.PlayerData.citizenid
                    candidates[#candidates + 1] = player.PlayerData.citizenId
                    candidates[#candidates + 1] = player.PlayerData.citizen_id
                    candidates[#candidates + 1] = player.PlayerData.charid
                    candidates[#candidates + 1] = player.PlayerData.charId
                end

                if player.Character then
                    candidates[#candidates + 1] = player.Character.citizenid
                    candidates[#candidates + 1] = player.Character.charid
                end
            end
        end

        if type(core.GetPlayer) == 'function' then
            local ok, player = pcall(core.GetPlayer, src)
            if ok and player then
                candidates[#candidates + 1] = player.citizenid
                candidates[#candidates + 1] = player.charid

                if player.PlayerData then
                    candidates[#candidates + 1] = player.PlayerData.citizenid
                    candidates[#candidates + 1] = player.PlayerData.charid
                end
            end
        end

        for _, value in ipairs(candidates) do
            if value and tostring(value) ~= '' then
                return tostring(value)
            end
        end
    end

    return getIdentifier(src)
end

local function sendStats(src, stats)
    if not src or not stats then return end
    Loaded[src] = stats
    TriggerClientEvent('node7-strength:client:setStats', src, stats)
end

local function loadPlayer(src)
    src = tonumber(src)
    if not src or src <= 0 then return nil end

    local citizenid = getCitizenId(src)
    if not citizenid then return nil end

    local stats = Node7StrengthDB.Get(citizenid)
    if stats then
        sendStats(src, stats)
        log(('Loaded %s for source %s'):format(citizenid, src))
    end

    return stats
end

local function refreshPlayer(src)
    local citizenid = getCitizenId(src)
    if not citizenid then return nil end
    local stats = Node7StrengthDB.Get(citizenid)
    sendStats(src, stats)
    return stats
end

local function addXP(src, amount, reason, ignoreCap)
    src = tonumber(src)
    if not src then return false end

    local citizenid = getCitizenId(src)
    if not citizenid then return false end

    local stats, awarded, leveled, status = Node7StrengthDB.AddXP(citizenid, amount, ignoreCap == true)
    if not stats then return false end

    sendStats(src, stats)

    if awarded > 0 then
        TriggerClientEvent('node7-strength:client:xpPopup', src, {
            amount = awarded,
            reason = reason or 'Strength XP',
            stats = stats,
            leveled = leveled
        })
    elseif status == 'daily_cap' then
        notify(src, 'Daily strength XP cap reached.', 'error')
    elseif status == 'max_level' then
        notify(src, 'Strength is already maxed.', 'info')
    end

    return true, stats, awarded, leveled, status
end

CreateThread(function()
    Wait(500)
    Node7StrengthDB.EnsureSchema()
    print('^2[node7-strength]^7 Database ready.')
end)

RegisterNetEvent('node7-strength:server:playerReady', function()
    loadPlayer(source)
end)

RegisterNetEvent('node7-strength:server:requestStats', function(openUI)
    local src = source
    local stats = refreshPlayer(src)

    if openUI and stats then
        TriggerClientEvent('node7-strength:client:openStats', src, stats)
    end
end)

RegisterNetEvent('node7-strength:server:train', function(index)
    local src = source
    index = tonumber(index)
    local spot = index and Config.Training[index]

    if not spot then
        notify(src, 'Invalid training spot.', 'error')
        return
    end

    local citizenid = getCitizenId(src)
    if not citizenid then return end

    local stats = Node7StrengthDB.Get(citizenid)
    if not stats then return end

    local currentTime = now()
    local elapsed = currentTime - (tonumber(stats.last_train) or 0)

    if elapsed < Config.TrainingCooldown then
        local left = Config.TrainingCooldown - elapsed
        notify(src, ('Rest before training again. %ss left.'):format(left), 'error')
        return
    end

    local ped = GetPlayerPed(src)
    if ped and ped ~= 0 then
        local coords = GetEntityCoords(ped)
        local dist = #(coords - spot.coords)
        if dist > (spot.radius + 5.0) then
            notify(src, 'Too far from the training spot.', 'error')
            return
        end
    end

    Node7StrengthDB.SetLastTrain(citizenid, currentTime)
    addXP(src, spot.xp or Config.Effects.TrainingXP, spot.label or 'Training', false)
end)

RegisterNetEvent('node7-strength:server:fightXP', function(targetServerId)
    local src = source

    if not Config.Effects.EnableFightXP then return end

    targetServerId = tonumber(targetServerId) or 0

    local citizenid = getCitizenId(src)
    if not citizenid then return end

    local stats = Node7StrengthDB.Get(citizenid)
    if not stats then return end

    local currentTime = now()
    local fightElapsed = currentTime - (tonumber(stats.last_fight_xp) or 0)

    if fightElapsed < Config.FightXPCooldown then return end

    RecentFightTargets[src] = RecentFightTargets[src] or {}

    if targetServerId > 0 then
        local lastTargetTime = RecentFightTargets[src][targetServerId] or 0
        if currentTime - lastTargetTime < Config.SameTargetFightCooldown then return end
        RecentFightTargets[src][targetServerId] = currentTime
    end

    Node7StrengthDB.SetLastFight(citizenid, currentTime)
    addXP(src, Config.Effects.FightXP, 'Brawl', false)
end)

AddEventHandler('playerDropped', function()
    Loaded[source] = nil
    RecentFightTargets[source] = nil
end)

exports('GetStrength', function(src)
    src = tonumber(src)
    if not src then return nil end
    return Loaded[src] or loadPlayer(src)
end)

exports('GetStrengthLevel', function(src)
    local stats = Loaded[tonumber(src)] or loadPlayer(src)
    return stats and stats.level or 1
end)

exports('AddStrengthXP', function(src, amount, reason)
    local ok, stats, awarded, leveled, status = addXP(src, amount, reason or 'External XP', false)
    return ok == true, stats, awarded, leveled, status
end)

exports('SetStrengthLevel', function(src, level)
    local citizenid = getCitizenId(tonumber(src))
    if not citizenid then return false end
    local stats = Node7StrengthDB.SetLevel(citizenid, level)
    sendStats(tonumber(src), stats)
    return true, stats
end)


exports('ResetStrength', function(src)
    src = tonumber(src)
    if not src then return false end
    local citizenid = getCitizenId(src)
    if not citizenid then return false end
    local stats = Node7StrengthDB.Reset(citizenid)
    sendStats(src, stats)
    return true, stats
end)

exports('GetCarryMultiplier', function(src)
    local stats = Loaded[tonumber(src)] or loadPlayer(src)
    return Config.GetCarryMultiplier(stats and stats.level or 1)
end)

exports('GetBrawlMultiplier', function(src)
    local stats = Loaded[tonumber(src)] or loadPlayer(src)
    return Config.GetBrawlMultiplier(stats and stats.level or 1)
end)

exports('GetStaminaMultiplier', function(src)
    local stats = Loaded[tonumber(src)] or loadPlayer(src)
    return Config.GetStaminaMultiplier(stats and stats.level or 1)
end)
