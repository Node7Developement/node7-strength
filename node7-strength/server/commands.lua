local function hasAdmin(src)
    if src == 0 then return true end
    return IsPlayerAceAllowed(src, Config.AdminAce)
end

local function notify(src, message, kind)
    if src == 0 then
        print(('[node7-strength] %s'):format(message))
        return
    end

    TriggerClientEvent('node7-strength:client:notify', src, message, kind or 'info')
end

RegisterCommand('setstrength', function(src, args)
    if not hasAdmin(src) then
        notify(src, 'No permission.', 'error')
        return
    end

    local target = tonumber(args[1])
    local level = tonumber(args[2])

    if not target or not GetPlayerName(target) or not level then
        notify(src, 'Usage: /setstrength [id] [level]', 'error')
        return
    end

    local ok, stats = exports['node7-strength']:SetStrengthLevel(target, level)
    if not ok then
        notify(src, 'Failed to set strength.', 'error')
        return
    end

    notify(src, ('Set %s strength to level %s.'):format(GetPlayerName(target), stats.level), 'success')
    notify(target, ('Your strength was set to level %s.'):format(stats.level), 'success')
end, false)

RegisterCommand('addstrengthxp', function(src, args)
    if not hasAdmin(src) then
        notify(src, 'No permission.', 'error')
        return
    end

    local target = tonumber(args[1])
    local amount = tonumber(args[2])

    if not target or not GetPlayerName(target) or not amount then
        notify(src, 'Usage: /addstrengthxp [id] [amount]', 'error')
        return
    end

    local ok, stats, awarded = exports['node7-strength']:AddStrengthXP(target, amount, 'Admin XP')
    if not ok then
        notify(src, 'Failed to add strength XP.', 'error')
        return
    end

    notify(src, ('Added %s strength XP to %s.'):format(awarded or amount, GetPlayerName(target)), 'success')
    notify(target, ('Admin added %s strength XP.'):format(awarded or amount), 'success')
end, false)

RegisterCommand('resetstrength', function(src, args)
    if not hasAdmin(src) then
        notify(src, 'No permission.', 'error')
        return
    end

    local target = tonumber(args[1])

    if not target or not GetPlayerName(target) then
        notify(src, 'Usage: /resetstrength [id]', 'error')
        return
    end

    local ok = exports['node7-strength']:ResetStrength(target)
    if not ok then
        notify(src, 'Failed to reset strength.', 'error')
        return
    end

    notify(src, ('Reset %s strength.'):format(GetPlayerName(target)), 'success')
    notify(target, 'Your strength was reset.', 'info')
end, false)
