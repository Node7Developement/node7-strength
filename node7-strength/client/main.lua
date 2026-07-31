local Stats = nil
local Prompt = nil
local PromptGroup = nil
local IsTraining = false
local LastFightXP = 0
local LastEffectApply = 0

local function debugLog(message)
    if Config.Debug then
        print(('[node7-strength] %s'):format(message))
    end
end

local function notify(message, kind)
    TriggerEvent('node7-strength:client:notify', message, kind or 'info')
end

local function requestStats(openUI)
    TriggerServerEvent('node7-strength:server:requestStats', openUI == true)
end

local function isPedReady(ped)
    if not ped or ped == 0 then return false end
    if IsEntityDead(ped) then return false end
    if IsPedInAnyVehicle(ped, false) then return false end
    return true
end

local function createVarString(text)
    return CreateVarString(10, 'LITERAL_STRING', text)
end

local function setupPrompt()
    if Prompt then return end

    PromptGroup = GetRandomIntInRange(0, 0xffffff)
    Prompt = PromptRegisterBegin()
    PromptSetControlAction(Prompt, Config.TrainingPromptKey)
    PromptSetText(Prompt, createVarString(Config.TrainingPromptText))
    PromptSetEnabled(Prompt, true)
    PromptSetVisible(Prompt, true)
    PromptSetHoldMode(Prompt, true)
    PromptSetGroup(Prompt, PromptGroup)
    PromptRegisterEnd(Prompt)
end

local function getClosestTrainingSpot(coords)
    local closestIndex = nil
    local closestSpot = nil
    local closestDistance = nil

    for index, spot in ipairs(Config.Training) do
        local distance = #(coords - spot.coords)
        if distance <= (spot.drawDistance or 18.0) then
            if not closestDistance or distance < closestDistance then
                closestIndex = index
                closestSpot = spot
                closestDistance = distance
            end
        end
    end

    return closestIndex, closestSpot, closestDistance
end

local function finishTraining(index, spot)
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    IsTraining = false
    TriggerServerEvent('node7-strength:server:train', index)
end

local function startTraining(index, spot)
    if IsTraining then return end

    local ped = PlayerPedId()
    if not isPedReady(ped) then return end

    IsTraining = true

    local duration = tonumber(spot.duration) or 8500
    local staminaMultiplier = Stats and Stats.stamina_multiplier or 1.0
    local speedBonus = math.max(0.0, (staminaMultiplier - 1.0) * 0.35)
    local adjustedDuration = math.floor(duration * (1.0 - math.min(Config.Multipliers.MaxTrainingSpeedBonus, speedBonus)))

    if spot.scenario and spot.scenario ~= '' then
        TaskStartScenarioInPlace(ped, GetHashKey(spot.scenario), adjustedDuration, true, false, false, false)
    end

    TriggerEvent('node7-strength:client:trainingStarted', spot.label or spot.name or 'Training', adjustedDuration)

    CreateThread(function()
        local finishAt = GetGameTimer() + adjustedDuration

        while IsTraining and GetGameTimer() < finishAt do
            if not isPedReady(PlayerPedId()) then
                IsTraining = false
                ClearPedTasks(PlayerPedId())
                return
            end

            Wait(250)
        end

        if IsTraining then
            finishTraining(index, spot)
        end
    end)
end

local function getTargetServerId(entity)
    if not entity or entity == 0 or not IsEntityAPed(entity) then return 0 end
    if not IsPedAPlayer(entity) then return 0 end

    local player = NetworkGetPlayerIndexFromPed(entity)
    if not player or player == -1 then return 0 end

    return GetPlayerServerId(player) or 0
end

local function tryFightXP()
    if not Config.Effects.EnableFightXP then return end

    local timer = GetGameTimer()
    if timer - LastFightXP < (Config.FightXPCooldown * 1000) then return end

    local ped = PlayerPedId()
    if not isPedReady(ped) then return end
    if not IsPedInMeleeCombat(ped) then return end

    local target = 0

    if type(GetMeleeTargetForPed) == 'function' then
        local ok, result = pcall(GetMeleeTargetForPed, ped)
        if ok and result then target = result end
    end

    if (not target or target == 0) and type(GetPlayerTargetEntity) == 'function' then
        local ok, hasTarget, result = pcall(GetPlayerTargetEntity, PlayerId())
        if ok and hasTarget and result then target = result end
    end

    local targetServerId = getTargetServerId(target)

    LastFightXP = timer
    TriggerServerEvent('node7-strength:server:fightXP', targetServerId)
end

local function applyMeleeModifier()
    if not Stats then return end
    if GetGameTimer() - LastEffectApply < 1000 then return end

    LastEffectApply = GetGameTimer()

    local ped = PlayerPedId()
    if not isPedReady(ped) then return end

    local inMelee = IsPedInMeleeCombat(ped)

    if Config.Effects.EnableMeleeModifier and inMelee and type(SetPlayerMeleeWeaponDamageModifier) == 'function' then
        pcall(SetPlayerMeleeWeaponDamageModifier, PlayerId(), Stats.brawl_multiplier or 1.0)
    elseif Config.Effects.EnableMeleeModifier and type(SetPlayerMeleeWeaponDamageModifier) == 'function' then
        pcall(SetPlayerMeleeWeaponDamageModifier, PlayerId(), 1.0)
    end

    if Config.Effects.EnableStaminaSupport and inMelee and type(RestorePlayerStamina) == 'function' then
        local bonus = math.max(0.0, (Stats.stamina_multiplier or 1.0) - 1.0)
        if bonus > 0 then
            pcall(RestorePlayerStamina, PlayerId(), bonus * 0.035)
        end
    end
end

RegisterNetEvent('node7-strength:client:setStats', function(stats)
    Stats = stats
    SendNUIMessage({ action = 'stats', data = stats })
end)

RegisterNetEvent('node7-strength:client:openStats', function(stats)
    Stats = stats or Stats
    TriggerEvent('node7-strength:client:openUI', Stats)
end)

RegisterCommand(Config.Command, function()
    requestStats(true)
end, false)

CreateThread(function()
    Wait(3000)
    TriggerServerEvent('node7-strength:server:playerReady')
    setupPrompt()
end)

CreateThread(function()
    while true do
        local sleep = 700

        if not IsTraining then
            local ped = PlayerPedId()

            if isPedReady(ped) and not IsPedInMeleeCombat(ped) then
                local coords = GetEntityCoords(ped)
                local index, spot, distance = getClosestTrainingSpot(coords)

                if spot and distance then
                    sleep = 0

                    if distance <= (spot.radius or 2.0) then
                        PromptSetActiveGroupThisFrame(PromptGroup, createVarString(spot.label or Config.TrainingPromptGroup))

                        if PromptHasHoldModeCompleted(Prompt) then
                            startTraining(index, spot)
                            Wait(1000)
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        tryFightXP()
        applyMeleeModifier()
        Wait(500)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    if Prompt then
        PromptDelete(Prompt)
        Prompt = nil
    end

    if type(SetPlayerMeleeWeaponDamageModifier) == 'function' then
        pcall(SetPlayerMeleeWeaponDamageModifier, PlayerId(), 1.0)
    end
end)
